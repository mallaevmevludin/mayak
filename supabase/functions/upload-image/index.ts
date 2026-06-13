import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { S3Client, PutObjectCommand, DeleteObjectCommand } from "https://esm.sh/@aws-sdk/client-s3";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, DELETE, OPTIONS",
};

async function getUserId(req: Request): Promise<string> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    throw new Error("Missing Authorization header");
  }
  const token = authHeader.split(" ")[1];
  if (!token) {
    throw new Error("Missing token in Authorization header");
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY")!;

  const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: authHeader,
      },
    },
  });

  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) {
    throw new Error(error?.message || "Invalid session");
  }

  return user.id;
}

Deno.serve(async (req: Request) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST" && req.method !== "DELETE") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { "Content-Type": "application/json", ...corsHeaders },
    });
  }

  let userId: string;
  try {
    userId = await getUserId(req);
  } catch (err: any) {
    return new Response(
      JSON.stringify({ error: "Unauthorized", details: err.message }),
      {
        status: 401,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }

  try {
    const keyId = Deno.env.get("YANDEX_KEY_ID");
    const secretKey = Deno.env.get("YANDEX_SECRET_KEY");
    const bucket = Deno.env.get("YANDEX_BUCKET") || "images-mayak";

    if (!keyId || !secretKey) {
      return new Response(
        JSON.stringify({ error: "Server storage configuration error: missing credentials" }),
        {
          status: 500,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        }
      );
    }

    const s3Client = new S3Client({
      region: "ru-central1",
      endpoint: "https://storage.yandexcloud.net",
      credentials: {
        accessKeyId: keyId,
        secretAccessKey: secretKey,
      },
    });

    if (req.method === "DELETE") {
      const { imageUrl } = await req.json();
      if (!imageUrl) {
        return new Response(JSON.stringify({ error: "Missing imageUrl" }), {
          status: 400,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        });
      }

      // Parse S3 key and bucket from URL
      const parsedUrl = new URL(imageUrl);
      let key = "";
      let bucketForDelete = bucket; // Default fallback to env default

      if (parsedUrl.hostname.startsWith("storage.yandexcloud.net")) {
        const pathParts = parsedUrl.pathname.split("/").filter(Boolean);
        bucketForDelete = pathParts[0];
        key = pathParts.slice(1).join("/");
      } else if (parsedUrl.hostname.endsWith(".storage.yandexcloud.net")) {
        bucketForDelete = parsedUrl.hostname.split(".")[0];
        key = parsedUrl.pathname.substring(1);
      } else {
        const pathParts = parsedUrl.pathname.split("/").filter(Boolean);
        bucketForDelete = pathParts[0];
        key = pathParts.slice(1).join("/");
      }

      // Security check: only allow user to delete their own files
      if (!key.startsWith(`users/${userId}/`)) {
        return new Response(JSON.stringify({ error: "Access denied" }), {
          status: 403,
          headers: { "Content-Type": "application/json", ...corsHeaders },
        });
      }

      // Delete main image
      await s3Client.send(
        new DeleteObjectCommand({
          Bucket: bucketForDelete,
          Key: key,
        })
      );

      // Try deleting thumbnail if it exists
      const extIndex = key.lastIndexOf(".");
      if (extIndex !== -1) {
        const base = key.substring(0, extIndex);
        const ext = key.substring(extIndex);
        const thumbnailKey = `${base}_thumb${ext}`;
        try {
          await s3Client.send(
            new DeleteObjectCommand({
              Bucket: bucketForDelete,
              Key: thumbnailKey,
            })
          );
        } catch (e) {
          console.error("Failed to delete thumbnail:", e);
        }
      }

      return new Response(JSON.stringify({ success: true }), {
        status: 200,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    // POST Request (Upload logic)
    const formData = await req.formData();
    const imageFile = formData.get("image") as File | null;
    const thumbnailFile = formData.get("thumbnail") as File | null;
    const uploadType = formData.get("type") as string | null;

    if (!imageFile) {
      return new Response(JSON.stringify({ error: "Missing image file" }), {
        status: 400,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      });
    }

    const timestamp = Date.now();
    const rand = Math.random().toString(36).substring(2, 8);

    // Determine target bucket & path based on upload type
    const targetBucket = uploadType === "avatar" 
      ? "avatar-mayak" 
      : bucket;

    const imagePath = uploadType === "avatar"
      ? `users/${userId}/avatars/${timestamp}_${rand}.jpg`
      : `users/${userId}/posts/${timestamp}_${rand}.jpg`;

    const imageBytes = new Uint8Array(await imageFile.arrayBuffer());

    // Upload main image
    await s3Client.send(
      new PutObjectCommand({
        Bucket: targetBucket,
        Key: imagePath,
        Body: imageBytes,
        ContentType: imageFile.type || "image/jpeg",
        ACL: "public-read",
      })
    );

    const imageUrl = `https://storage.yandexcloud.net/${targetBucket}/${imagePath}`;
    let thumbnailUrl = imageUrl;

    // Upload thumbnail if provided (not usually sent for avatars, but supported)
    if (thumbnailFile) {
      const thumbnailPath = uploadType === "avatar"
        ? `users/${userId}/avatars/${timestamp}_${rand}_thumb.jpg`
        : `users/${userId}/posts/${timestamp}_${rand}_thumb.jpg`;
        
      const thumbnailBytes = new Uint8Array(await thumbnailFile.arrayBuffer());
      await s3Client.send(
        new PutObjectCommand({
          Bucket: targetBucket,
          Key: thumbnailPath,
          Body: thumbnailBytes,
          ContentType: thumbnailFile.type || "image/jpeg",
          ACL: "public-read",
        })
      );
      thumbnailUrl = `https://storage.yandexcloud.net/${targetBucket}/${thumbnailPath}`;
    }

    return new Response(
      JSON.stringify({
        imageUrl,
        thumbnailUrl,
      }),
      {
        status: 200,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  } catch (error: any) {
    return new Response(
      JSON.stringify({
        error: "Upload failed",
        details: error.message || error,
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json", ...corsHeaders },
      }
    );
  }
});

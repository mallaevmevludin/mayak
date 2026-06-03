import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import 'supabase_config.dart';

class ImageUploadService {
  /// Optimize raw image file in background isolate for upload
  static Future<Map<String, File>> optimizeImage(File rawFile) async {
    final result = await compute(_optimizeIsolate, rawFile.path);
    return {
      'optimized': File(result['optimized']!),
      'thumbnail': File(result['thumbnail']!),
    };
  }

  static Map<String, String> _optimizeIsolate(String path) {
    final bytes = File(path).readAsBytesSync();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) throw Exception("Failed to decode image");
    final orientedImage = img.bakeOrientation(originalImage);

    // Resize main
    final optimized = img.copyResize(
      orientedImage,
      width: orientedImage.width > orientedImage.height ? 1280 : null,
      height: orientedImage.height >= orientedImage.width ? 1280 : null,
      interpolation: img.Interpolation.cubic,
    );

    // Resize thumbnail
    final thumbnail = img.copyResize(
      orientedImage,
      width: orientedImage.width > orientedImage.height ? 320 : null,
      height: orientedImage.height >= orientedImage.width ? 320 : null,
      interpolation: img.Interpolation.linear,
    );

    final optBytes = img.encodeJpg(optimized, quality: 80);
    final thumbBytes = img.encodeJpg(thumbnail, quality: 65);

    final systemTemp = Directory.systemTemp;
    final rand = math.Random().nextInt(1000000);
    final optFile = File('${systemTemp.path}/opt_$rand.jpg')..writeAsBytesSync(optBytes);
    final thumbFile = File('${systemTemp.path}/thumb_$rand.jpg')..writeAsBytesSync(thumbBytes);

    return {
      'optimized': optFile.path,
      'thumbnail': thumbFile.path,
    };
  }

  /// Upload post image (optimized and thumbnail) to Yandex Cloud via Edge Function
  /// Returns a map with 'imageUrl' and 'thumbnailUrl'
  static Future<Map<String, String>> uploadPostImage({
    required File imageFile,
    required File thumbnailFile,
  }) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception("Пользователь не авторизован");
      }

      final session = client.auth.currentSession;
      final token = session?.accessToken;
      if (token == null) {
        throw Exception("Сессия истекла, пожалуйста, войдите снова");
      }

      final functionUrl = Uri.parse('${SupabaseConfig.supabaseUrl}/functions/v1/upload-image');
      
      final request = http.MultipartRequest('POST', functionUrl);

      // Auth and key headers required by Supabase API gateway
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['apikey'] = SupabaseConfig.supabaseAnonKey;

      // Add main optimized image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      // Add thumbnail image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'thumbnail',
          thumbnailFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      debugPrint('Uploading post images to: $functionUrl');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Upload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final imageUrl = data['imageUrl'] as String?;
        final thumbnailUrl = data['thumbnailUrl'] as String?;

        if (imageUrl == null || thumbnailUrl == null) {
          throw Exception("Получен некорректный ответ от сервера");
        }

        return {
          'imageUrl': imageUrl,
          'thumbnailUrl': thumbnailUrl,
        };
      } else {
        String errorMessage = 'Ошибка при загрузке изображения (${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'] as String;
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Exception in ImageUploadService.uploadPostImage: $e');
      rethrow;
    }
  }

  /// Delete post image (optimized and thumbnail) from Yandex Cloud via Edge Function
  static Future<void> deletePostImage(String imageUrl) async {
    try {
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      final token = session?.accessToken;
      if (token == null) {
        throw Exception("Сессия истекла, пожалуйста, войдите снова");
      }

      final functionUrl = Uri.parse('${SupabaseConfig.supabaseUrl}/functions/v1/upload-image');
      debugPrint('ImageUploadService.deletePostImage: calling DELETE on $functionUrl for $imageUrl');
      
      final response = await http.delete(
        functionUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'apikey': SupabaseConfig.supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'imageUrl': imageUrl,
        }),
      );

      debugPrint('ImageUploadService.deletePostImage status: ${response.statusCode}');
      if (response.statusCode != 200) {
        String errorMessage = 'Ошибка при удалении (${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'] as String;
          } else if (errorData['details'] != null) {
            errorMessage = errorData['details'] as String;
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Exception in ImageUploadService.deletePostImage: $e');
      rethrow;
    }
  }

  /// Upload avatar image to Yandex Cloud via Edge Function
  /// Returns the public URL of the uploaded avatar
  static Future<String> uploadAvatar({
    required File imageFile,
  }) async {
    try {
      if (!SupabaseConfig.isConfigured) {
        // Mock mode avatar URL simulation
        await Future.delayed(const Duration(milliseconds: 800));
        return 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150&h=150';
      }

      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception("Пользователь не авторизован");
      }

      final session = client.auth.currentSession;
      final token = session?.accessToken;
      if (token == null) {
        throw Exception("Сессия истекла, пожалуйста, войдите снова");
      }

      final functionUrl = Uri.parse('${SupabaseConfig.supabaseUrl}/functions/v1/upload-image');
      final request = http.MultipartRequest('POST', functionUrl);

      // Auth and key headers required by Supabase API gateway
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['apikey'] = SupabaseConfig.supabaseAnonKey;

      // Specify type as avatar to tell Edge Function to use avatar-mayak bucket
      request.fields['type'] = 'avatar';

      // Add main optimized image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      debugPrint('Uploading avatar to Yandex Cloud via Edge Function: $functionUrl');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Upload avatar response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final imageUrl = data['imageUrl'] as String?;
        if (imageUrl == null) {
          throw Exception("Получен некорректный ответ от сервера");
        }
        debugPrint('Avatar uploaded successfully. URL: $imageUrl');
        return imageUrl;
      } else {
        String errorMessage = 'Ошибка при загрузке аватара (${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            errorMessage = errorData['error'] as String;
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint('Exception in ImageUploadService.uploadAvatar: $e');
      rethrow;
    }
  }
}

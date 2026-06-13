import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/post_model.dart';
import '../../../models/comment_model.dart';
import '../../../models/user_model.dart';
import 'social_repository.dart';

class SupabaseSocialRepository implements SocialRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<List<PostModel>> fetchPosts(String? currentUserId, {int limit = 10, int offset = 0, String? tag}) async {
    var query = _client
        .from('posts')
        .select('''
          id, content, created_at, user_id,
          link_url, link_title,
          image_url, image_format, image_width, image_height, image_uploaded_at, image_urls,
          profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified),
          post_likes(user_id),
          comments(id),
          polls:polls(question, options),
          poll_votes:poll_votes(user_id, option_index),
          job_id,
          jobs:job_id(*, profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified))
        ''');

    if (tag != null && tag.isNotEmpty) {
      query = query.ilike('content', '%#$tag%');
    }

    final response = await query
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    final List<dynamic> data = response;
    return data
        .map((json) => PostModel.fromJson(json, currentUserId: currentUserId))
        .toList();
  }

  @override
  Future<PostModel?> fetchPost(int postId, String? currentUserId) async {
    final response = await _client
        .from('posts')
        .select('''
          id, content, created_at, user_id,
          link_url, link_title,
          image_url, image_format, image_width, image_height, image_uploaded_at, image_urls,
          profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified),
          post_likes(user_id),
          comments(id),
          polls:polls(question, options),
          poll_votes:poll_votes(user_id, option_index),
          job_id,
          jobs:job_id(*, profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified))
        ''')
        .eq('id', postId)
        .single();
    return PostModel.fromJson(response, currentUserId: currentUserId);
  }

  @override
  Future<PostModel> createPost({
    required String userId,
    required String content,
    String? linkUrl,
    String? linkTitle,
    String? pollQuestion,
    List<String>? pollOptions,
    String? imageUrl,
    String? imageFormat,
    int? imageWidth,
    int? imageHeight,
    List<String>? imageUrls,
    int? jobId,
  }) async {
    final Map<String, dynamic> insertData = {
      'user_id': userId,
      'content': content.trim(),
      'link_url': linkUrl,
      'link_title': linkTitle,
      'image_url': imageUrl ?? (imageUrls != null && imageUrls.isNotEmpty ? imageUrls.first : null),
      'image_format': imageFormat,
      'image_width': imageWidth,
      'image_height': imageHeight,
      'image_uploaded_at': (imageUrl != null || (imageUrls != null && imageUrls.isNotEmpty))
          ? DateTime.now().toUtc().toIso8601String()
          : null,
      'image_urls': imageUrls ?? (imageUrl != null ? [imageUrl] : const []),
      'job_id': jobId,
    };

    final response = await _client
        .from('posts')
        .insert(insertData)
        .select('id')
        .single();

    final newPostId = response['id'] as int;

    if (pollQuestion != null && pollOptions != null && pollOptions.isNotEmpty) {
      await _client.from('polls').insert({
        'post_id': newPostId,
        'question': pollQuestion,
        'options': pollOptions,
      });
    }

    final fullPost = await fetchPost(newPostId, userId);
    if (fullPost == null) {
      throw Exception('Не удалось загрузить созданный пост');
    }
    return fullPost;
  }

  @override
  Future<void> likePost({
    required String userId,
    required int postId,
    required bool currentlyLiked,
  }) async {
    if (currentlyLiked) {
      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } else {
      await _client.from('post_likes').insert({
        'post_id': postId,
        'user_id': userId,
      });
    }
  }

  @override
  Future<List<CommentModel>> fetchComments(int postId, String? currentUserId) async {
    final response = await _client
        .from('comments')
        .select('''
          id, post_id, user_id, content, created_at,
          profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified),
          comment_likes(user_id)
        ''')
        .eq('post_id', postId)
        .order('created_at', ascending: true);

    final List<dynamic> data = response;
    return data
        .map((json) => CommentModel.fromJson(json, currentUserId: currentUserId))
        .toList();
  }

  @override
  Future<CommentModel> addComment({
    required int postId,
    required String userId,
    required String content,
  }) async {
    final response = await _client
        .from('comments')
        .insert({
          'post_id': postId,
          'user_id': userId,
          'content': content.trim(),
        })
        .select('''
          id, post_id, user_id, content, created_at,
          profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified),
          comment_likes(user_id)
        ''')
        .single();

    return CommentModel.fromJson(response, currentUserId: userId);
  }

  @override
  Future<void> likeComment({
    required int commentId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    if (currentlyLiked) {
      await _client
          .from('comment_likes')
          .delete()
          .eq('comment_id', commentId)
          .eq('user_id', userId);
    } else {
      await _client.from('comment_likes').insert({
        'comment_id': commentId,
        'user_id': userId,
      });
    }
  }

  @override
  Future<void> deletePost({required int postId, required String userId}) async {
    await _client
        .from('posts')
        .delete()
        .eq('id', postId)
        .eq('user_id', userId);
  }

  @override
  Future<void> deleteComment({required int commentId, required String userId}) async {
    await _client
        .from('comments')
        .delete()
        .eq('id', commentId)
        .eq('user_id', userId);
  }

  @override
  Future<UserModel?> fetchUserProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return UserModel.fromJson(response, '');
  }

  @override
  Future<List<UserModel>> searchUsers(String query, bool searchByUsernameOnly) async {
    String cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.startsWith('@')) {
      cleanQuery = cleanQuery.substring(1).trim();
    }
    if (cleanQuery.isEmpty) return [];

    var req = _client.from('profiles').select();
    if (searchByUsernameOnly) {
      req = req.ilike('username', '%$cleanQuery%');
    } else {
      req = req.or(
        'username.ilike.%$cleanQuery%,first_name.ilike.%$cleanQuery%,last_name.ilike.%$cleanQuery%',
      );
    }

    final response = await req.limit(20);
    final List<dynamic> data = response;
    return data.map((json) => UserModel.fromJson(json, '')).toList();
  }

  @override
  Future<List<PostModel>> fetchUserPosts(String userId, String? currentUserId) async {
    final response = await _client
        .from('posts')
        .select('''
          id, content, created_at, user_id,
          link_url, link_title,
          image_url, image_format, image_width, image_height, image_uploaded_at, image_urls,
          profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url),
          post_likes(user_id),
          comments(id),
          polls:polls(question, options),
          poll_votes:poll_votes(user_id, option_index),
          job_id,
          jobs:job_id(*, profiles:user_id(first_name, last_name, username, emoji_avatar, avatar_url, is_verified))
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final List<dynamic> data = response;
    return data
        .map((json) => PostModel.fromJson(json, currentUserId: currentUserId))
        .toList();
  }

  @override
  Future<Map<String, int>> fetchUserStats(String userId) async {
    final postsResponse = await _client
        .from('posts')
        .select('id, post_likes(user_id)')
        .eq('user_id', userId);
    final List<dynamic> data = postsResponse;
    int totalLikes = 0;
    for (final post in data) {
      if (post['post_likes'] != null) {
        totalLikes += (post['post_likes'] as List).length;
      }
    }
    return {'posts': data.length, 'likes': totalLikes};
  }

  @override
  Future<void> voteInPoll({
    required int postId,
    required String userId,
    required int optionIndex,
  }) async {
    await _client.from('poll_votes').insert({
      'post_id': postId,
      'user_id': userId,
      'option_index': optionIndex,
    });
  }
}

import '../../../models/post_model.dart';
import '../../../models/comment_model.dart';
import '../../../models/user_model.dart';
import '../../../models/notification_model.dart';

abstract class SocialRepository {
  Future<List<PostModel>> fetchPosts(String? currentUserId, {int limit = 10, int offset = 0, String? tag});
  Future<PostModel?> fetchPost(int postId, String? currentUserId);
  
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
  });

  Future<void> likePost({
    required String userId,
    required int postId,
    required bool currentlyLiked,
  });

  Future<List<CommentModel>> fetchComments(int postId, String? currentUserId);

  Future<CommentModel> addComment({
    required int postId,
    required String userId,
    required String content,
  });

  Future<void> likeComment({
    required int commentId,
    required String userId,
    required bool currentlyLiked,
  });

  Future<void> deletePost({
    required int postId,
    required String userId,
  });

  Future<void> deleteComment({
    required int commentId,
    required String userId,
  });

  Future<UserModel?> fetchUserProfile(String userId);

  Future<List<UserModel>> searchUsers(String query, bool searchByUsernameOnly);

  Future<List<PostModel>> fetchUserPosts(String userId, String? currentUserId);

  Future<Map<String, int>> fetchUserStats(String userId);

  Future<void> voteInPoll({
    required int postId,
    required String userId,
    required int optionIndex,
  });

  // ── Подписки (follows) ──

  /// Подписаться: [followerId] начинает следить за [followeeId].
  Future<void> followUser({
    required String followerId,
    required String followeeId,
  });

  /// Отписаться.
  Future<void> unfollowUser({
    required String followerId,
    required String followeeId,
  });

  /// Подписан ли [followerId] на [followeeId].
  Future<bool> isFollowing({
    required String followerId,
    required String followeeId,
  });

  /// Кол-во подписчиков и подписок пользователя: `{'followers': x, 'following': y}`.
  Future<Map<String, int>> fetchFollowCounts(String userId);

  /// Лента из постов тех, на кого подписан [currentUserId] (вкладка «Подписки»).
  Future<List<PostModel>> fetchFollowingFeed(
    String currentUserId, {
    int limit = 10,
    int offset = 0,
  });

  // ── Уведомления ──

  Future<List<NotificationModel>> fetchNotifications(
    String userId, {
    int limit = 50,
  });

  Future<int> fetchUnreadNotificationsCount(String userId);

  Future<void> markNotificationsRead(String userId);
}

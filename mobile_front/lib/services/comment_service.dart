import 'package:dio/dio.dart';
import '../models/comment.dart';
import 'api_client.dart';

class CommentService {
  final ApiClient _apiClient = ApiClient();

  /// GET /api/courses/{courseId}/comments
  Future<List<Comment>> getComments(String courseId) async {
    try {
      final response = await _apiClient.dio.get('/courses/$courseId/comments');
      final list = response.data as List<dynamic>;
      return list.map((e) => Comment.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load comments');
    }
  }

  /// GET /api/courses/{courseId}/comments/{commentId}/replies
  Future<List<Comment>> getReplies(String courseId, String commentId) async {
    try {
      final response =
          await _apiClient.dio.get('/courses/$courseId/comments/$commentId/replies');
      final list = response.data as List<dynamic>;
      return list.map((e) => Comment.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to load replies');
    }
  }

  /// POST /api/courses/{courseId}/comments
  Future<Comment> addComment(String courseId, String content) async {
    try {
      final response = await _apiClient.dio.post(
        '/courses/$courseId/comments',
        data: {'content': content},
      );
      return Comment.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to add comment');
    }
  }

  /// POST /api/courses/{courseId}/comments/{commentId}/replies
  Future<Comment> replyToComment(
      String courseId, String commentId, String content) async {
    try {
      final response = await _apiClient.dio.post(
        '/courses/$courseId/comments/$commentId/replies',
        data: {'content': content},
      );
      return Comment.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to add reply');
    }
  }

  /// DELETE /api/courses/{courseId}/comments/{commentId}
  Future<void> deleteComment(String courseId, String commentId) async {
    try {
      await _apiClient.dio.delete('/courses/$courseId/comments/$commentId');
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to delete comment');
    }
  }

  /// POST /api/courses/{courseId}/comments/{commentId}/like
  Future<void> likeComment(String courseId, String commentId) async {
    try {
      await _apiClient.dio.post('/courses/$courseId/comments/$commentId/like');
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to like comment');
    }
  }

  /// DELETE /api/courses/{courseId}/comments/{commentId}/like
  Future<void> unlikeComment(String courseId, String commentId) async {
    try {
      await _apiClient.dio.delete('/courses/$courseId/comments/$commentId/like');
    } on DioException catch (e) {
      throw Exception(e.response?.data?.toString() ?? 'Failed to unlike comment');
    }
  }
}

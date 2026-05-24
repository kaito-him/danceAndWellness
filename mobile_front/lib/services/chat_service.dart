import 'package:dio/dio.dart';
import 'api_client.dart';
import '../models/message.dart';
import '../models/conversation.dart';

class ChatService {
  final ApiClient _api = ApiClient();

  Future<List<Conversation>> getConversations() async {
    try {
      final response = await _api.dio.get('/messages/conversations');
      if (response.data is List) {
        return (response.data as List).map((e) => Conversation.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load conversations: $e');
    }
  }

  Future<List<Message>> getThread(String otherUserId) async {
    try {
      final response = await _api.dio.get('/messages/thread/$otherUserId');
      if (response.data is List) {
        return (response.data as List).map((e) => Message.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to load thread: $e');
    }
  }

  Future<Message> sendMessage(String receiverId, String content) async {
    try {
      final response = await _api.dio.post('/messages/send', data: {
        'receiverId': receiverId,
        'content': content,
      });
      return Message.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  Future<void> markRead(String otherUserId) async {
    try {
      await _api.dio.post('/messages/read/$otherUserId');
    } catch (e) {
      // Silently fail for read status
    }
  }
}

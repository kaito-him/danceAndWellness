import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final _apiService = NotificationApiService();
  int _unreadCount = 0;
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> fetchUnreadCount() async {
    _isLoading = true;
    notifyListeners();
    try {
      _unreadCount = await _apiService.getUnreadCount();
    } catch (_) {
      _unreadCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void decrementCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  void resetCount() {
    _unreadCount = 0;
    notifyListeners();
  }
}

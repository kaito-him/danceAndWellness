import 'package:flutter/material.dart';
import '../../models/conversation.dart';
import '../../services/chat_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';
import 'chat_thread_screen.dart';
import 'dart:async';

class InstructorMessagesScreen extends StatefulWidget {
  const InstructorMessagesScreen({super.key});

  @override
  State<InstructorMessagesScreen> createState() => _InstructorMessagesScreenState();
}

class _InstructorMessagesScreenState extends State<InstructorMessagesScreen> {
  final ChatService _chatService = ChatService();
  List<Conversation> _allConversations = [];
  List<Conversation> _filteredConversations = [];
  bool _loading = true;
  String _searchQuery = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadConversations();
    // Auto refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadConversations(silent: true));
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final convs = await _chatService.getConversations();
      // Sort by newest first
      convs.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      
      if (mounted) {
        setState(() {
          _allConversations = convs;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading messages: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredConversations = _allConversations;
    } else {
      _filteredConversations = _allConversations
          .where((c) => c.otherUsername.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchHeader(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
              : _filteredConversations.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      color: AppTheme.primaryGold,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _filteredConversations.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
                        itemBuilder: (context, index) {
                          return _buildConversationTile(_filteredConversations[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
            _applyFilter();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by student name...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGold),
          filled: true,
          fillColor: AppTheme.lightGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conv) {
    return ListTile(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatThreadScreen(
              otherUserId: conv.otherUserId,
              otherUsername: conv.otherUsername,
              otherUserPhoto: conv.otherUserPhoto,
            ),
          ),
        );
        _loadConversations(silent: true);
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.paleGold,
            backgroundImage: conv.otherUserPhoto != null
                ? NetworkImage(ApiClient.formatMediaUrl('/api/files/${conv.otherUserPhoto}'))
                : null,
            child: conv.otherUserPhoto == null
                ? Text(conv.otherUsername[0].toUpperCase(),
                    style: const TextStyle(color: AppTheme.darkGold, fontWeight: FontWeight.bold))
                : null,
          ),
          if (conv.unreadCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  '${conv.unreadCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            conv.otherUsername,
            style: TextStyle(
              fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
              fontSize: 16,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            _formatTime(conv.lastMessageAt),
            style: TextStyle(
              fontSize: 12,
              color: conv.unreadCount > 0 ? AppTheme.primaryGold : AppTheme.textSecondary,
              fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          conv.lastMessageWasMine ? 'You: ${conv.lastMessage}' : conv.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: conv.unreadCount > 0 ? AppTheme.textPrimary : AppTheme.textSecondary,
            fontWeight: conv.unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: AppTheme.mediumGray.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No conversations yet' : 'No results found',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}

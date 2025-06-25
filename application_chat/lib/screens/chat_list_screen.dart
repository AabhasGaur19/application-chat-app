//application_chat/lib/screens/chat_list_screen.dart

import 'package:application_chat/models/chat_model.dart';
import 'package:application_chat/models/message_model.dart';
import 'package:application_chat/models/user_model.dart';
import 'package:application_chat/screens/chat_screen.dart';
import 'package:application_chat/screens/profile_screen.dart';
import 'package:application_chat/screens/search_screen.dart';
import 'package:application_chat/services/api_service.dart';
import 'package:application_chat/services/auth_service.dart';
import 'package:application_chat/services/socket_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final SocketService _socketService = SocketService();
  List<ChatModel> _chats = [];
  bool _isLoading = true;
  Map<String, bool> _onlineStatus = {};
  Map<String, DateTime> _lastSeen = {};

  @override
  void initState() {
    super.initState();
    _loadChats();
    _initializeSocketAndListeners();
  }

// Replace the _initializeSocketAndListeners method:

  Future<void> _initializeSocketAndListeners() async {
    await _socketService.ensureInitialized();

    // Wait for stable connection
    await Future.delayed(Duration(milliseconds: 1000));

    if (mounted) {
      _setupSocketListeners();

      // Join user's personal room for receiving notifications
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        _socketService.emit('join:user', {'userId': currentUser.uid});
      }
    }
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      final chats = await _apiService.getChats();
      if (mounted) {
        setState(() {
          _chats = chats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chats: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

// Updated socket listeners in _setupSocketListeners() method
  // Replace the entire _setupSocketListeners method in ChatListScreen:

  void _setupSocketListeners() {
    _socketService.on('user:status', (data) {
      if (mounted) {
        setState(() {
          _onlineStatus[data['uid']] = data['online'];
        });
      }
    });

    _socketService.on('user:lastSeen', (data) {
      if (mounted) {
        setState(() {
          _lastSeen[data['uid']] = DateTime.parse(data['lastSeen']);
        });
      }
    });

    _socketService.on('unread:count', (data) {
      if (mounted) {
        setState(() {
          final index = _chats.indexWhere((chat) => chat.id == data['chatId']);
          if (index != -1) {
            _chats[index] = ChatModel(
              id: _chats[index].id,
              participants: _chats[index].participants,
              lastMessage: _chats[index].lastMessage,
              updatedAt: _chats[index].updatedAt,
              unreadCount: data['count'],
            );
          }
        });
      }
    });

    // NEW: Listen for new chat creation
    _socketService.on('chat:new', (data) {
      if (mounted) {
        print('Received new chat: $data');
        try {
          final newChat = ChatModel.fromJson(data);
          setState(() {
            // Check if chat already exists to avoid duplicates
            bool chatExists = _chats.any((chat) => chat.id == newChat.id);
            if (!chatExists) {
              _chats.insert(0, newChat);
            }
          });
        } catch (e) {
          print('Error processing new chat: $e');
        }
      }
    });

    // NEW: Listen for chat updates (when last message changes)
    _socketService.on('chat:updated', (data) {
      if (mounted) {
        print('Received chat update: $data');
        try {
          final chatId = data['chatId'];
          final lastMessage = MessageModel.fromJson(data['lastMessage']);
          final updatedAt = DateTime.parse(data['updatedAt']);

          setState(() {
            final index = _chats.indexWhere((chat) => chat.id == chatId);
            if (index != -1) {
              // Update existing chat
              _chats[index] = ChatModel(
                id: _chats[index].id,
                participants: _chats[index].participants,
                lastMessage: lastMessage,
                updatedAt: updatedAt,
                unreadCount: _chats[index].unreadCount,
              );

              // Move updated chat to top
              final updatedChat = _chats.removeAt(index);
              _chats.insert(0, updatedChat);
            }
          });
        } catch (e) {
          print('Error processing chat update: $e');
        }
      }
    });

    _socketService.on('message:new', (data) async {
      final message = MessageModel.fromJson(data);
      if (mounted) {
        setState(() {
          final index = _chats.indexWhere((chat) => chat.id == message.chatId);
          if (index != -1) {
            // Update existing chat
            final currentUserId = _authService.currentUser?.uid;
            final shouldIncrementUnread = message.sender.uid != currentUserId;

            _chats[index] = ChatModel(
              id: _chats[index].id,
              participants: _chats[index].participants,
              lastMessage: message,
              updatedAt: DateTime.now(),
              unreadCount: shouldIncrementUnread
                  ? _chats[index].unreadCount + 1
                  : _chats[index].unreadCount,
            );

            // Move to top
            final updatedChat = _chats.removeAt(index);
            _chats.insert(0, updatedChat);
          }
          // Note: If chat doesn't exist, it should be handled by 'chat:new' event
        });
      }
    });
  }

  void _onChatTap(ChatModel chat, UserModel recipient) {
    // Reset unread count immediately for better UX
    if (chat.unreadCount > 0) {
      setState(() {
        final index = _chats.indexWhere((c) => c.id == chat.id);
        if (index != -1) {
          _chats[index] = ChatModel(
            id: _chats[index].id,
            participants: _chats[index].participants,
            lastMessage: _chats[index].lastMessage,
            updatedAt: _chats[index].updatedAt,
            unreadCount: 0, // Reset to 0
          );
        }
      });
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatId: chat.id,
          recipient: recipient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
              ? const Center(
                  child: Text(
                    'No chats found. Tap the + button or search icon to start a conversation!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _chats.length,
                  itemBuilder: (context, index) {
                    final chat = _chats[index];

                    // FIXED: Handle empty participants or no valid recipient
                    if (chat.participants.isEmpty) {
                      return const SizedBox.shrink(); // Skip this chat
                    }

                    final currentUserUid = _authService.currentUser?.uid;
                    if (currentUserUid == null) {
                      return const SizedBox.shrink(); // Skip if no current user
                    }

                    // Find recipient with proper null safety
                    final recipientList = chat.participants
                        .where((p) => p.uid != currentUserUid)
                        .toList();

                    if (recipientList.isEmpty) {
                      // If no recipient found (e.g., chat with self), skip or handle differently
                      return const ListTile(
                        leading: CircleAvatar(child: Icon(Icons.error)),
                        title: Text('Invalid chat'),
                        subtitle: Text('No valid recipient found'),
                      );
                    }

                    final recipient = recipientList.first;
                    final isOnline = _onlineStatus[recipient.uid] ?? false;
                    final lastSeen = _lastSeen[recipient.uid];

                    return ChatTile(
                      chat: chat,
                      recipient: recipient,
                      isOnline: isOnline,
                      lastSeen: lastSeen,
                      onTap: () =>
                          _onChatTap(chat, recipient), // Use the new method
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SearchScreen()),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Start a new chat',
      ),
    );
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final UserModel recipient;
  final bool isOnline;
  final DateTime? lastSeen;
  final VoidCallback onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.recipient,
    required this.isOnline,
    required this.lastSeen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final istLocation = tz.getLocation('Asia/Kolkata');
    final formattedLastSeen = lastSeen != null
        ? DateFormat('MMM dd, HH:mm')
            .format(tz.TZDateTime.from(lastSeen!, istLocation))
        : null;

    return ListTile(
      leading: Stack(
        alignment: Alignment.bottomRight,
        children: [
          recipient.photoUrl != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(recipient.photoUrl!),
                )
              : const CircleAvatar(child: Icon(Icons.person)),
          if (isOnline)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
        ],
      ),
      title: Text(recipient.displayName),
      subtitle: // In ChatTile widget's build method, update the subtitle section:
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chat.lastMessage?.content ?? 'No messages yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // Show online status or last seen
          if (isOnline)
            const Text(
              'Online',
              style: TextStyle(
                  fontSize: 10,
                  color: Colors.green,
                  fontWeight: FontWeight.w500),
            )
          else if (formattedLastSeen != null)
            Text(
              'Last seen: $formattedLastSeen',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat('MMM dd, HH:mm')
                .format(tz.TZDateTime.from(chat.updatedAt, istLocation)),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (chat.unreadCount > 0)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${chat.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}

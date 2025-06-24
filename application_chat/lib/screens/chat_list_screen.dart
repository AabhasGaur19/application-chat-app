// import 'package:application_chat/models/chat_model.dart';
// import 'package:application_chat/models/user_model.dart';
// import 'package:application_chat/services/api_service.dart';
// import 'package:application_chat/services/auth_service.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'profile_screen.dart';
// import 'search_screen.dart';
// import 'chat_screen.dart';

// class ChatListScreen extends StatefulWidget {
//   const ChatListScreen({super.key});

//   @override
//   _ChatListScreenState createState() => _ChatListScreenState();
// }

// class _ChatListScreenState extends State<ChatListScreen> {
//   final ApiService _apiService = ApiService();
//   final AuthService _authService = AuthService();
//   List<ChatModel> _chats = [];
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadChats();
//   }

//   Future<void> _loadChats() async {
//     setState(() => _isLoading = true);
//     try {
//       final chats = await _apiService.getChats();
//       if (mounted) {
//         setState(() {
//           _chats = chats;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load chats: $e')),
//         );
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chats'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.person),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => ProfileScreen()),
//               );
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => SearchScreen()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _chats.isEmpty
//               ? const Center(
//                   child: Text(
//                     'No chats found. Tap the + button or search icon to start a conversation!',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                 )
//               : ListView.builder(
//                   itemCount: _chats.length,
//                   itemBuilder: (context, index) {
//                     final chat = _chats[index];
                    
//                     // Check if current user exists
//                     if (_authService.currentUser == null) {
//                       return const SizedBox.shrink(); // Skip this chat
//                     }
                    
//                     // Find recipient with proper error handling
//                     final recipient = chat.participants.firstWhere(
//                       (p) => p.uid != _authService.currentUser!.uid,
//                       orElse: () => chat.participants.isNotEmpty 
//                           ? chat.participants.first 
//                           : UserModel(
//                               uid: 'unknown',
//                               displayName: 'Unknown User',
//                               email: '',
//                             ),
//                     );
                    
//                     return ChatTile(
//                       chat: chat,
//                       recipient: recipient,
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => ChatScreen(
//                               chatId: chat.id,
//                               recipient: recipient,
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => SearchScreen()),
//           );
//         },
//         child: const Icon(Icons.add),
//         tooltip: 'Start a new chat',
//       ),
//     );
//   }
// }

// class ChatTile extends StatelessWidget {
//   final ChatModel chat;
//   final UserModel recipient;
//   final VoidCallback onTap;

//   const ChatTile({
//     super.key,
//     required this.chat,
//     required this.recipient,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       leading: recipient.photoUrl != null
//           ? CircleAvatar(
//               backgroundImage: NetworkImage(recipient.photoUrl!),
//             )
//           : const CircleAvatar(child: Icon(Icons.person)),
//       title: Text(recipient.displayName),
//       subtitle: Text(
//         chat.lastMessage?.content ?? 'No messages yet',
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//       ),
//       trailing: Text(
//         DateFormat('MMM dd, HH:mm').format(chat.updatedAt),
//         style: const TextStyle(fontSize: 12, color: Colors.grey),
//       ),
//       onTap: onTap,
//     );
//   }
// }













// import 'package:application_chat/models/chat_model.dart';
// import 'package:application_chat/models/message_model.dart';
// import 'package:application_chat/models/user_model.dart';
// import 'package:application_chat/screens/chat_screen.dart';
// import 'package:application_chat/screens/profile_screen.dart';
// import 'package:application_chat/screens/search_screen.dart';
// import 'package:application_chat/services/api_service.dart';
// import 'package:application_chat/services/auth_service.dart';
// import 'package:application_chat/services/socket_services.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:timezone/timezone.dart' as tz;

// class ChatListScreen extends StatefulWidget {
//   const ChatListScreen({super.key});

//   @override
//   _ChatListScreenState createState() => _ChatListScreenState();
// }

// class _ChatListScreenState extends State<ChatListScreen> {
//   final ApiService _apiService = ApiService();
//   final AuthService _authService = AuthService();
//   final SocketService _socketService = SocketService();
//   List<ChatModel> _chats = [];
//   bool _isLoading = true;
//   Map<String, bool> _onlineStatus = {};
//   Map<String, DateTime> _lastSeen = {};

//   @override
//   void initState() {
//     super.initState();
//     _loadChats();
//     _initializeSocketAndListeners();
//   }

//   Future<void> _initializeSocketAndListeners() async {
//     await _socketService.ensureInitialized();
//     if (mounted) {
//       _setupSocketListeners();
//     }
//   }

//   Future<void> _loadChats() async {
//     setState(() => _isLoading = true);
//     try {
//       final chats = await _apiService.getChats();
//       if (mounted) {
//         setState(() {
//           _chats = chats;
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load chats: $e')),
//         );
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   void _setupSocketListeners() {
//     _socketService.on('user:status', (data) {
//       if (mounted) {
//         setState(() {
//           _onlineStatus[data['uid']] = data['online'];
//         });
//       }
//     });

//     _socketService.on('user:lastSeen', (data) {
//       if (mounted) {
//         setState(() {
//           _lastSeen[data['uid']] = DateTime.parse(data['lastSeen']);
//         });
//       }
//     });

//     _socketService.on('unread:count', (data) {
//       if (mounted) {
//         setState(() {
//           final index = _chats.indexWhere((chat) => chat.id == data['chatId']);
//           if (index != -1) {
//             _chats[index] = ChatModel(
//               id: _chats[index].id,
//               participants: _chats[index].participants,
//               lastMessage: _chats[index].lastMessage,
//               updatedAt: _chats[index].updatedAt,
//               unreadCount: data['count'],
//             );
//           }
//         });
//       }
//     });

//     _socketService.on('message:new', (data) async {
//       final message = MessageModel.fromJson(data);
//       if (mounted) {
//         setState(() {
//           final index = _chats.indexWhere((chat) => chat.id == message.chatId);
//           if (index != -1) {
//             _chats[index] = ChatModel(
//               id: _chats[index].id,
//               participants: _chats[index].participants,
//               lastMessage: message,
//               updatedAt: DateTime.now(),
//               unreadCount: _chats[index].unreadCount + 1,
//             );
//             _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
//           }
//         });
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chats'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.person),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => ProfileScreen()),
//               );
//             },
//           ),
//           IconButton(
//             icon: const Icon(Icons.search),
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => SearchScreen()),
//               );
//             },
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : _chats.isEmpty
//               ? const Center(
//                   child: Text(
//                     'No chats found. Tap the + button or search icon to start a conversation!',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                 )
//               : ListView.builder(
//                   itemCount: _chats.length,
//                   itemBuilder: (context, index) {
//                     final chat = _chats[index];
//                     final recipient = chat.participants
//                         .firstWhere((p) => p.uid != _authService.currentUser!.uid);
//                     final isOnline = _onlineStatus[recipient.uid] ?? false;
//                     final lastSeen = _lastSeen[recipient.uid];
//                     return ChatTile(
//                       chat: chat,
//                       recipient: recipient,
//                       isOnline: isOnline,
//                       lastSeen: lastSeen,
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => ChatScreen(
//                               chatId: chat.id,
//                               recipient: recipient,
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => SearchScreen()),
//           );
//         },
//         child: const Icon(Icons.add),
//         tooltip: 'Start a new chat',
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _socketService.disconnect();
//     super.dispose();
//   }
// }

// class ChatTile extends StatelessWidget {
//   final ChatModel chat;
//   final UserModel recipient;
//   final bool isOnline;
//   final DateTime? lastSeen;
//   final VoidCallback onTap;

//   const ChatTile({
//     super.key,
//     required this.chat,
//     required this.recipient,
//     required this.isOnline,
//     required this.lastSeen,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final istLocation = tz.getLocation('Asia/Kolkata');
//     final formattedLastSeen = lastSeen != null
//         ? DateFormat('MMM dd, HH:mm').format(tz.TZDateTime.from(lastSeen!, istLocation))
//         : null;

//     return ListTile(
//       leading: Stack(
//         alignment: Alignment.bottomRight,
//         children: [
//           recipient.photoUrl != null
//               ? CircleAvatar(
//                   backgroundImage: NetworkImage(recipient.photoUrl!),
//                 )
//               : const CircleAvatar(child: Icon(Icons.person)),
//           if (isOnline)
//             Container(
//               width: 12,
//               height: 12,
//               decoration: BoxDecoration(
//                 color: Colors.green,
//                 shape: BoxShape.circle,
//                 border: Border.all(color: Colors.white, width: 2),
//               ),
//             ),
//         ],
//       ),
//       title: Text(recipient.displayName),
//       subtitle: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             chat.lastMessage?.content ?? 'No messages yet',
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//           ),
//           if (formattedLastSeen != null)
//             Text(
//               'Last seen: $formattedLastSeen',
//               style: const TextStyle(fontSize: 10, color: Colors.grey),
//             ),
//         ],
//       ),
//       trailing: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(
//             DateFormat('MMM dd, HH:mm').format(tz.TZDateTime.from(chat.updatedAt, istLocation)),
//             style: const TextStyle(fontSize: 12, color: Colors.grey),
//           ),
//           if (chat.unreadCount > 0)
//             Container(
//               padding: const EdgeInsets.all(6),
//               decoration: const BoxDecoration(
//                 color: Colors.blue,
//                 shape: BoxShape.circle,
//               ),
//               child: Text(
//                 '${chat.unreadCount}',
//                 style: const TextStyle(color: Colors.white, fontSize: 12),
//               ),
//             ),
//         ],
//       ),
//       onTap: onTap,
//     );
//   }
// }






















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

  Future<void> _initializeSocketAndListeners() async {
    await _socketService.ensureInitialized();
    if (mounted) {
      _setupSocketListeners();
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

    _socketService.on('message:new', (data) async {
      final message = MessageModel.fromJson(data);
      if (mounted) {
        setState(() {
          final index = _chats.indexWhere((chat) => chat.id == message.chatId);
          if (index != -1) {
            _chats[index] = ChatModel(
              id: _chats[index].id,
              participants: _chats[index].participants,
              lastMessage: message,
              updatedAt: DateTime.now(),
              unreadCount: _chats[index].unreadCount + 1,
            );
            _chats.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          }
        });
      }
    });
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatId: chat.id,
                              recipient: recipient,
                            ),
                          ),
                        );
                      },
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
        ? DateFormat('MMM dd, HH:mm').format(tz.TZDateTime.from(lastSeen!, istLocation))
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chat.lastMessage?.content ?? 'No messages yet',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (formattedLastSeen != null)
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
            DateFormat('MMM dd, HH:mm').format(tz.TZDateTime.from(chat.updatedAt, istLocation)),
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
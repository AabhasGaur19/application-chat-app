// import 'package:application_chat/models/message_model.dart';
// import 'package:application_chat/models/user_model.dart';
// import 'package:application_chat/services/api_service.dart';
// import 'package:application_chat/services/auth_service.dart';
// import 'package:application_chat/services/socket_services.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:timezone/timezone.dart' as tz;

// class ChatScreen extends StatefulWidget {
//   final String chatId;
//   final UserModel recipient;

//   const ChatScreen({
//     super.key,
//     required this.chatId,
//     required this.recipient,
//   });

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final ApiService _apiService = ApiService();
//   final AuthService _authService = AuthService();
//   final SocketService _socketService = SocketService();
//   final TextEditingController _controller = TextEditingController();
//   List<MessageModel> _messages = [];
//   bool _isLoading = true;
//   bool _hasError = false;
//   bool _isTyping = false;
//   bool _recipientTyping = false;
//   bool _isConnected = false;
//   bool _isRecipientOnline = false;
//   DateTime? _recipientLastSeen;

//   @override
//   void initState() {
//     super.initState();
//     _loadMessages();
//     _initializeSocketAndListeners();
//     _controller.addListener(_handleTyping);
//   }

//   Future<void> _initializeSocketAndListeners() async {
//     await _socketService.ensureInitialized();
//     if (mounted) {
//       _setupSocketListeners();
//       _socketService.emit('join:chat', {'chatId': widget.chatId});
//       _socketService.emit('last:seen', {});
//     }
//   }

//   Future<void> _loadMessages() async {
//     setState(() {
//       _isLoading = true;
//       _hasError = false;
//     });
//     try {
//       final messages = await _apiService.getMessages(widget.chatId);
//       if (mounted) {
//         setState(() {
//           _messages = messages.reversed.toList();
//           _isLoading = false;
//         });
//         // Mark messages as delivered/read
//         for (var message in messages) {
//           if (message.sender.uid != _authService.currentUser!.uid &&
//               message.status != 'read') {
//             _socketService.emit('message:delivered', {
//               'messageId': message.id,
//               'chatId': widget.chatId,
//             });
//             _socketService.emit('message:read', {
//               'messageId': message.id,
//               'chatId': widget.chatId,
//             });
//           }
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _hasError = true;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load messages: $e')),
//         );
//       }
//     }
//   }

//   void _setupSocketListeners() {
//     _socketService.on('connect', (_) {
//       if (mounted) {
//         setState(() => _isConnected = true);
//         _socketService.emit('join:chat', {'chatId': widget.chatId});
//       }
//     });

//     _socketService.on('disconnect', (_) {
//       if (mounted) {
//         setState(() => _isConnected = false);
//       }
//     });

//     _socketService.on('message:new', (data) {
//       final message = MessageModel.fromJson(data);
//       if (mounted && message.chatId == widget.chatId) {
//         setState(() {
//           _messages.insert(0, message);
//         });
//         if (message.sender.uid != _authService.currentUser!.uid) {
//           _socketService.emit('message:delivered', {
//             'messageId': message.id,
//             'chatId': widget.chatId,
//           });
//           _socketService.emit('message:read', {
//             'messageId': message.id,
//             'chatId': widget.chatId,
//           });
//         }
//       }
//     });

//     _socketService.on('message:status', (data) {
//       if (mounted) {
//         setState(() {
//           final index = _messages.indexWhere((m) => m.id == data['messageId']);
//           if (index != -1) {
//             _messages[index] = MessageModel(
//               id: _messages[index].id,
//               chatId: _messages[index].chatId,
//               sender: _messages[index].sender,
//               content: _messages[index].content,
//               status: data['status'],
//               createdAt: _messages[index].createdAt,
//             );
//           }
//         });
//       }
//     });

//     _socketService.on('typing', (data) {
//       if (mounted && data['userId'] == widget.recipient.uid) {
//         setState(() => _recipientTyping = data['isTyping']);
//       }
//     });

//     _socketService.on('user:status', (data) {
//       if (mounted && data['uid'] == widget.recipient.uid) {
//         setState(() => _isRecipientOnline = data['online']);
//       }
//     });

//     _socketService.on('user:lastSeen', (data) {
//       if (mounted && data['uid'] == widget.recipient.uid) {
//         setState(() => _recipientLastSeen = DateTime.parse(data['lastSeen']));
//       }
//     });
//   }

//   void _handleTyping() {
//     final isTyping = _controller.text.isNotEmpty;
//     if (isTyping != _isTyping) {
//       setState(() => _isTyping = isTyping);
//       _socketService.emit('typing', {
//         'chatId': widget.chatId,
//         'isTyping': isTyping,
//       });
//     }
//   }

//   Future<void> _sendMessage() async {
//     if (_controller.text.trim().isEmpty) return;
//     try {
//       final message =
//           await _apiService.sendMessage(widget.chatId, _controller.text.trim());
//       if (message != null && mounted) {
//         setState(() {
//           _controller.clear();
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to send message: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final istLocation = tz.getLocation('Asia/Kolkata');
//     final formattedLastSeen = _recipientLastSeen != null
//         ? DateFormat('MMM dd, HH:mm')
//             .format(tz.TZDateTime.from(_recipientLastSeen!, istLocation))
//         : null;

//     return Scaffold(
//       appBar: AppBar(
// // In ChatScreen's build method, update the AppBar title section:

//         title: Row(
//           children: [
//             Stack(
//               alignment: Alignment.bottomRight,
//               children: [
//                 widget.recipient.photoUrl != null
//                     ? CircleAvatar(
//                         radius: 16,
//                         backgroundImage:
//                             NetworkImage(widget.recipient.photoUrl!),
//                       )
//                     : const CircleAvatar(
//                         radius: 16,
//                         child: Icon(Icons.person, size: 16),
//                       ),
//                 if (_isRecipientOnline)
//                   Container(
//                     width: 8,
//                     height: 8,
//                     decoration: BoxDecoration(
//                       color: Colors.green,
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Colors.white, width: 1),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               // Add Expanded to prevent overflow
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     widget.recipient.displayName,
//                     style: const TextStyle(fontSize: 16),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   // Show online status or last seen
//                   if (_isRecipientOnline)
//                     const Text(
//                       'Online',
//                       style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.green,
//                           fontWeight: FontWeight.w500),
//                     )
//                   else if (formattedLastSeen != null)
//                     Text(
//                       'Last seen: $formattedLastSeen',
//                       style: const TextStyle(fontSize: 10, color: Colors.grey),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         // actions: [
//         //   Icon(
//         //     _isConnected ? Icons.wifi : Icons.wifi_off,
//         //     color: _isConnected ? Colors.green : Colors.red,
//         //   ),
//         // ],
//       ),
//       body: Column(
//         children: [
//           if (_recipientTyping)
//             const Padding(
//               padding: EdgeInsets.all(8.0),
//               child: Text('Typing...', style: TextStyle(color: Colors.grey)),
//             ),
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _hasError
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Text(
//                               'Failed to load messages. Please try again.',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(color: Colors.red),
//                             ),
//                             const SizedBox(height: 16),
//                             ElevatedButton(
//                               onPressed: _loadMessages,
//                               child: const Text('Retry'),
//                             ),
//                           ],
//                         ),
//                       )
//                     : _messages.isEmpty
//                         ? const Center(
//                             child: Text(
//                                 'No messages yet. Start the conversation!'))
//                         : ListView.builder(
//                             reverse: true,
//                             itemCount: _messages.length,
//                             itemBuilder: (context, index) {
//                               final message = _messages[index];
//                               final isMe = message.sender.uid ==
//                                   _authService.currentUser!.uid;
//                               return MessageBubble(
//                                 message: message,
//                                 isMe: isMe,
//                               );
//                             },
//                           ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: const InputDecoration(
//                       hintText: 'Type a message...',
//                       border: OutlineInputBorder(),
//                     ),
//                     onSubmitted: (_) => _sendMessage(),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.removeListener(_handleTyping);
//     _controller.dispose();
//     _socketService.disconnect();
//     super.dispose();
//   }
// }

// class MessageBubble extends StatelessWidget {
//   final MessageModel message;
//   final bool isMe;

//   const MessageBubble({
//     super.key,
//     required this.message,
//     required this.isMe,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final istLocation = tz.getLocation('Asia/Kolkata');
//     final istTime = tz.TZDateTime.from(message.createdAt, istLocation);
//     final formattedTime = DateFormat('h:mm a').format(istTime);

//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.blue : Colors.grey[300],
//           borderRadius: BorderRadius.only(
//             topLeft: const Radius.circular(16),
//             topRight: const Radius.circular(16),
//             bottomLeft: Radius.circular(isMe ? 16 : 0),
//             bottomRight: Radius.circular(isMe ? 0 : 16),
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               message.content,
//               style: TextStyle(color: isMe ? Colors.white : Colors.black),
//             ),
//             const SizedBox(height: 4),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   formattedTime,
//                   style: const TextStyle(fontSize: 10, color: Colors.grey),
//                 ),
//                 if (isMe)
//                   Padding(
//                     padding: const EdgeInsets.only(left: 4),
//                     child: Icon(
//                       message.status == 'read'
//                           ? Icons.done_all
//                           : message.status == 'delivered'
//                               ? Icons.done
//                               : Icons.access_time,
//                       size: 16,
//                       color:
//                           message.status == 'read' ? Colors.blue : Colors.grey,
//                     ),
//                   ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:application_chat/models/message_model.dart';
// import 'package:application_chat/models/user_model.dart';
// import 'package:application_chat/services/api_service.dart';
// import 'package:application_chat/services/auth_service.dart';
// import 'package:application_chat/services/socket_services.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:timezone/timezone.dart' as tz;

// class ChatScreen extends StatefulWidget {
//   final String chatId;
//   final UserModel recipient;

//   const ChatScreen({
//     super.key,
//     required this.chatId,
//     required this.recipient,
//   });

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final ApiService _apiService = ApiService();
//   final AuthService _authService = AuthService();
//   final SocketService _socketService = SocketService();
//   final TextEditingController _controller = TextEditingController();
//   List<MessageModel> _messages = [];
//   bool _isLoading = true;
//   bool _hasError = false;
//   bool _isTyping = false;
//   bool _recipientTyping = false;
//   bool _isConnected = false;
//   bool _isRecipientOnline = false;
//   DateTime? _recipientLastSeen;

//   @override
//   void initState() {
//     super.initState();
//     _loadMessages();
//     _initializeSocketAndListeners();
//     _controller.addListener(_handleTyping);
//   }

//   Future<void> _initializeSocketAndListeners() async {
//     await _socketService.ensureInitialized();
//     if (mounted) {
//       _setupSocketListeners();
//       _socketService.emit('join:chat', {'chatId': widget.chatId});
//       _socketService.emit('last:seen', {});

//       // Mark all messages as read when entering chat
//       _markAllMessagesAsRead();
//     }
//   }

//   void _markAllMessagesAsRead() {
//     for (var message in _messages) {
//       if (message.sender.uid != _authService.currentUser!.uid &&
//           message.status != 'read') {
//         _socketService.emit('message:read', {
//           'messageId': message.id,
//           'chatId': widget.chatId,
//         });
//       }
//     }
//   }

//   Future<void> _loadMessages() async {
//     setState(() {
//       _isLoading = true;
//       _hasError = false;
//     });
//     try {
//       final messages = await _apiService.getMessages(widget.chatId);
//       if (mounted) {
//         setState(() {
//           _messages = messages.reversed.toList();
//           _isLoading = false;
//         });

//         // Mark all messages as read after loading
//         _markAllMessagesAsRead();
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//           _hasError = true;
//         });
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load messages: $e')),
//         );
//       }
//     }
//   }

//   void _setupSocketListeners() {
//     _socketService.on('connect', (_) {
//       if (mounted) {
//         setState(() => _isConnected = true);
//         _socketService.emit('join:chat', {'chatId': widget.chatId});
//       }
//     });

//     _socketService.on('disconnect', (_) {
//       if (mounted) {
//         setState(() => _isConnected = false);
//       }
//     });

//     _socketService.on('message:new', (data) {
//       final message = MessageModel.fromJson(data);
//       if (mounted && message.chatId == widget.chatId) {
//         setState(() {
//           _messages.insert(0, message);
//         });

//         // Immediately mark as read if it's from someone else
//         if (message.sender.uid != _authService.currentUser!.uid) {
//           _socketService.emit('message:delivered', {
//             'messageId': message.id,
//             'chatId': widget.chatId,
//           });
//           _socketService.emit('message:read', {
//             'messageId': message.id,
//             'chatId': widget.chatId,
//           });
//         }
//       }
//     });

//     _socketService.on('message:status', (data) {
//       if (mounted) {
//         setState(() {
//           final index = _messages.indexWhere((m) => m.id == data['messageId']);
//           if (index != -1) {
//             _messages[index] = MessageModel(
//               id: _messages[index].id,
//               chatId: _messages[index].chatId,
//               sender: _messages[index].sender,
//               content: _messages[index].content,
//               status: data['status'],
//               createdAt: _messages[index].createdAt,
//             );
//           }
//         });
//       }
//     });

//     _socketService.on('typing', (data) {
//       if (mounted && data['userId'] == widget.recipient.uid) {
//         setState(() => _recipientTyping = data['isTyping']);
//       }
//     });

//     _socketService.on('user:status', (data) {
//       if (mounted && data['uid'] == widget.recipient.uid) {
//         setState(() => _isRecipientOnline = data['online']);
//       }
//     });

//     _socketService.on('user:lastSeen', (data) {
//       if (mounted && data['uid'] == widget.recipient.uid) {
//         setState(() => _recipientLastSeen = DateTime.parse(data['lastSeen']));
//       }
//     });
//   }

//   void _handleTyping() {
//     final isTyping = _controller.text.isNotEmpty;
//     if (isTyping != _isTyping) {
//       setState(() => _isTyping = isTyping);
//       _socketService.emit('typing', {
//         'chatId': widget.chatId,
//         'isTyping': isTyping,
//       });
//     }
//   }

//   Future<void> _sendMessage() async {
//     if (_controller.text.trim().isEmpty) return;
//     try {
//       final message =
//           await _apiService.sendMessage(widget.chatId, _controller.text.trim());
//       if (message != null && mounted) {
//         setState(() {
//           _controller.clear();
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to send message: $e')),
//         );
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final istLocation = tz.getLocation('Asia/Kolkata');
//     final formattedLastSeen = _recipientLastSeen != null
//         ? DateFormat('MMM dd, HH:mm')
//             .format(tz.TZDateTime.from(_recipientLastSeen!, istLocation))
//         : null;

//     return Scaffold(
//       appBar: AppBar(
// // In ChatScreen's build method, update the AppBar title section:

//         title: Row(
//           children: [
//             Stack(
//               alignment: Alignment.bottomRight,
//               children: [
//                 widget.recipient.photoUrl != null
//                     ? CircleAvatar(
//                         radius: 16,
//                         backgroundImage:
//                             NetworkImage(widget.recipient.photoUrl!),
//                       )
//                     : const CircleAvatar(
//                         radius: 16,
//                         child: Icon(Icons.person, size: 16),
//                       ),
//                 if (_isRecipientOnline)
//                   Container(
//                     width: 8,
//                     height: 8,
//                     decoration: BoxDecoration(
//                       color: Colors.green,
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Colors.white, width: 1),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               // Add Expanded to prevent overflow
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     widget.recipient.displayName,
//                     style: const TextStyle(fontSize: 16),
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   // Show online status or last seen
//                   if (_isRecipientOnline)
//                     const Text(
//                       'Online',
//                       style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.green,
//                           fontWeight: FontWeight.w500),
//                     )
//                   else if (formattedLastSeen != null)
//                     Text(
//                       'Last seen: $formattedLastSeen',
//                       style: const TextStyle(fontSize: 10, color: Colors.grey),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         // actions: [
//         //   Icon(
//         //     _isConnected ? Icons.wifi : Icons.wifi_off,
//         //     color: _isConnected ? Colors.green : Colors.red,
//         //   ),
//         // ],
//       ),
//       body: Column(
//         children: [
//           if (_recipientTyping)
//             const Padding(
//               padding: EdgeInsets.all(8.0),
//               child: Text('Typing...', style: TextStyle(color: Colors.grey)),
//             ),
//           Expanded(
//             child: _isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : _hasError
//                     ? Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             const Text(
//                               'Failed to load messages. Please try again.',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(color: Colors.red),
//                             ),
//                             const SizedBox(height: 16),
//                             ElevatedButton(
//                               onPressed: _loadMessages,
//                               child: const Text('Retry'),
//                             ),
//                           ],
//                         ),
//                       )
//                     : _messages.isEmpty
//                         ? const Center(
//                             child: Text(
//                                 'No messages yet. Start the conversation!'))
//                         : ListView.builder(
//                             reverse: true,
//                             itemCount: _messages.length,
//                             itemBuilder: (context, index) {
//                               final message = _messages[index];
//                               final isMe = message.sender.uid ==
//                                   _authService.currentUser!.uid;
//                               return MessageBubble(
//                                 message: message,
//                                 isMe: isMe,
//                               );
//                             },
//                           ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: const InputDecoration(
//                       hintText: 'Type a message...',
//                       border: OutlineInputBorder(),
//                     ),
//                     onSubmitted: (_) => _sendMessage(),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _controller.removeListener(_handleTyping);
//     _controller.dispose();
//     _socketService.disconnect();
//     super.dispose();
//   }
// }

// class MessageBubble extends StatelessWidget {
//   final MessageModel message;
//   final bool isMe;

//   const MessageBubble({
//     super.key,
//     required this.message,
//     required this.isMe,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final istLocation = tz.getLocation('Asia/Kolkata');
//     final istTime = tz.TZDateTime.from(message.createdAt, istLocation);
//     final formattedTime = DateFormat('h:mm a').format(istTime);

//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.blue : Colors.grey[300],
//           borderRadius: BorderRadius.only(
//             topLeft: const Radius.circular(16),
//             topRight: const Radius.circular(16),
//             bottomLeft: Radius.circular(isMe ? 16 : 0),
//             bottomRight: Radius.circular(isMe ? 0 : 16),
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               message.content,
//               style: TextStyle(color: isMe ? Colors.white : Colors.black),
//             ),
//             const SizedBox(height: 4),
//             Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   formattedTime,
//                   style: const TextStyle(fontSize: 10, color: Colors.grey),
//                 ),
//                 if (isMe)
//                   Padding(
//                     padding: const EdgeInsets.only(left: 4),
//                     child: Icon(
//                       message.status == 'read'
//                           ? Icons.done_all
//                           : message.status == 'delivered'
//                               ? Icons.done
//                               : Icons.access_time,
//                       size: 16,
//                       color:
//                           message.status == 'read' ? Colors.blue : Colors.grey,
//                     ),
//                   ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:application_chat/models/message_model.dart';
import 'package:application_chat/models/user_model.dart';
import 'package:application_chat/services/api_service.dart';
import 'package:application_chat/services/auth_service.dart';
import 'package:application_chat/services/socket_services.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class ChatScreen extends StatefulWidget {
  final String chatId;
  final UserModel recipient;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.recipient,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  final SocketService _socketService = SocketService();
  final TextEditingController _controller = TextEditingController();
  List<MessageModel> _messages = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isTyping = false;
  bool _recipientTyping = false;
  bool _isConnected = false;
  bool _isRecipientOnline = false;
  DateTime? _recipientLastSeen;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _initializeSocketAndListeners();
    _controller.addListener(_handleTyping);
  }

  Future<void> _initializeSocketAndListeners() async {
    await _socketService.ensureInitialized();

    // Wait a bit more to ensure connection is stable
    await Future.delayed(Duration(milliseconds: 1000));

    if (mounted) {
      _setupSocketListeners();

      // Join chat room after listeners are set up
      _socketService.emit('join:chat', {'chatId': widget.chatId});
      _socketService.emit('last:seen', {});

      // Mark all messages as read when entering chat
      _markAllMessagesAsRead();
    }
  }

  void _markAllMessagesAsRead() {
    for (var message in _messages) {
      if (message.sender.uid != _authService.currentUser!.uid &&
          message.status != 'read') {
        _socketService.emit('message:read', {
          'messageId': message.id,
          'chatId': widget.chatId,
        });
      }
    }
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final messages = await _apiService.getMessages(widget.chatId);
      if (mounted) {
        setState(() {
          _messages = messages.reversed.toList();
          _isLoading = false;
        });

        // Mark all messages as read after loading
        _markAllMessagesAsRead();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load messages: $e')),
        );
      }
    }
  }

  void _setupSocketListeners() {
    _socketService.on('connect', (_) {
      print('Chat screen: Socket connected');
      if (mounted) {
        setState(() => _isConnected = true);
        // Re-join chat room on reconnection
        _socketService.emit('join:chat', {'chatId': widget.chatId});
      }
    });

    _socketService.on('disconnect', (_) {
      print('Chat screen: Socket disconnected');
      if (mounted) {
        setState(() => _isConnected = false);
      }
    });

    _socketService.on('message:new', (data) {
      print('Received new message: $data');
      try {
        final message = MessageModel.fromJson(data);
        if (mounted && message.chatId == widget.chatId) {
          setState(() {
            // Check if message already exists to avoid duplicates
            bool messageExists = _messages.any((m) => m.id == message.id);
            if (!messageExists) {
              _messages.insert(0, message);
            }
          });

          // Immediately mark as read if it's from someone else
          if (message.sender.uid != _authService.currentUser!.uid) {
            _socketService.emit('message:delivered', {
              'messageId': message.id,
              'chatId': widget.chatId,
            });
            _socketService.emit('message:read', {
              'messageId': message.id,
              'chatId': widget.chatId,
            });
          }
        }
      } catch (e) {
        print('Error processing new message: $e');
      }
    });

    _socketService.on('message:status', (data) {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == data['messageId']);
          if (index != -1) {
            _messages[index] = MessageModel(
              id: _messages[index].id,
              chatId: _messages[index].chatId,
              sender: _messages[index].sender,
              content: _messages[index].content,
              status: data['status'],
              createdAt: _messages[index].createdAt,
            );
          }
        });
      }
    });

    _socketService.on('typing', (data) {
      if (mounted && data['userId'] == widget.recipient.uid) {
        setState(() => _recipientTyping = data['isTyping']);
      }
    });

    _socketService.on('user:status', (data) {
      if (mounted && data['uid'] == widget.recipient.uid) {
        setState(() => _isRecipientOnline = data['online']);
      }
    });

    _socketService.on('user:lastSeen', (data) {
      if (mounted && data['uid'] == widget.recipient.uid) {
        setState(() => _recipientLastSeen = DateTime.parse(data['lastSeen']));
      }
    });
  }

  void _handleTyping() {
    final isTyping = _controller.text.isNotEmpty;
    if (isTyping != _isTyping) {
      setState(() => _isTyping = isTyping);
      _socketService.emit('typing', {
        'chatId': widget.chatId,
        'isTyping': isTyping,
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    try {
      final message =
          await _apiService.sendMessage(widget.chatId, _controller.text.trim());
      if (message != null && mounted) {
        setState(() {
          _controller.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final istLocation = tz.getLocation('Asia/Kolkata');
    final formattedLastSeen = _recipientLastSeen != null
        ? DateFormat('MMM dd, HH:mm')
            .format(tz.TZDateTime.from(_recipientLastSeen!, istLocation))
        : null;

    return Scaffold(
      appBar: AppBar(
// In ChatScreen's build method, update the AppBar title section:

        title: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                widget.recipient.photoUrl != null
                    ? CircleAvatar(
                        radius: 16,
                        backgroundImage:
                            NetworkImage(widget.recipient.photoUrl!),
                      )
                    : const CircleAvatar(
                        radius: 16,
                        child: Icon(Icons.person, size: 16),
                      ),
                if (_isRecipientOnline)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              // Add Expanded to prevent overflow
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.recipient.displayName,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Show online status or last seen
                  if (_isRecipientOnline)
                    const Text(
                      'Online',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500),
                    )
                  else if (formattedLastSeen != null)
                    Text(
                      'Last seen: $formattedLastSeen',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        // actions: [
        //   Icon(
        //     _isConnected ? Icons.wifi : Icons.wifi_off,
        //     color: _isConnected ? Colors.green : Colors.red,
        //   ),
        // ],
      ),
      body: Column(
        children: [
          if (_recipientTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Typing...', style: TextStyle(color: Colors.grey)),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Failed to load messages. Please try again.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMessages,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? const Center(
                            child: Text(
                                'No messages yet. Start the conversation!'))
                        : ListView.builder(
                            reverse: true,
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              final message = _messages[index];
                              final isMe = message.sender.uid ==
                                  _authService.currentUser!.uid;
                              return MessageBubble(
                                message: message,
                                isMe: isMe,
                              );
                            },
                          ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTyping);
    _controller.dispose();
    _socketService.disconnect();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final istLocation = tz.getLocation('Asia/Kolkata');
    final istTime = tz.TZDateTime.from(message.createdAt, istLocation);
    final formattedTime = DateFormat('h:mm a').format(istTime);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(color: isMe ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formattedTime,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                if (isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      message.status == 'read'
                          ? Icons.done_all
                          : message.status == 'delivered'
                              ? Icons.done
                              : Icons.access_time,
                      size: 16,
                      color:
                          message.status == 'read' ? Colors.blue : Colors.grey,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

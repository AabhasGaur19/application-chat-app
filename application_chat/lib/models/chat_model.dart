//application_chat/lib/models/chat_model.dart
import 'package:application_chat/models/user_model.dart';
import 'package:application_chat/models/message_model.dart';

class ChatModel {
  final String id;
  final List<UserModel> participants;
  final MessageModel? lastMessage;
  final DateTime updatedAt;
  final int unreadCount;

  ChatModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.updatedAt,
    required this.unreadCount,
  });

  factory ChatModel.fromJson(Map<String, dynamic> data) {
    return ChatModel(
      id: data['_id'] ?? '',
      participants: (data['participants'] as List? ?? [])
          .map((p) => UserModel.fromJson(p))
          .toList(),
      lastMessage: data['lastMessage'] != null
          ? MessageModel.fromJson(data['lastMessage'])
          : null,
      updatedAt: DateTime.parse(data['updatedAt'] ?? DateTime.now().toIso8601String()),
      unreadCount: data['unreadCount'] ?? 0,
    );
  }
}
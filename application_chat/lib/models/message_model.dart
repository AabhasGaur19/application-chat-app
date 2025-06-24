import 'package:application_chat/models/user_model.dart';

class MessageModel {
  final String id;
  final String chatId;
  final UserModel sender;
  final String content;
  final String status;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> data) {
    return MessageModel(
      id: data['_id'] ?? '',
      chatId: data['chatId'] ?? '',
      sender: UserModel.fromJson(data['senderId'] ?? {}),
      content: data['content'] ?? '',
      status: data['status'] ?? 'sent',
      createdAt: DateTime.parse(data['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
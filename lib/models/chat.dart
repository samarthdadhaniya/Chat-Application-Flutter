import 'dart:convert';
import 'package:flutter_chat_app/models/message.dart';
import 'package:flutter_chat_app/models/user.dart';

class Chat {
  final String id;
  final User user1;
  final User user2;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chat({
    required this.id,
    required this.user1,
    required this.user2,
    required this.messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : 
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  Message? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.last;
  }

  String getLastMessagePreview() {
    if (messages.isEmpty) {
      return 'No messages yet';
    }
    return messages.last.content.length > 30
        ? '${messages.last.content.substring(0, 30)}...'
        : messages.last.content;
  }

  User getOtherUser(String currentUserId) {
    return user1.id == currentUserId ? user2 : user1;
  }

  int getUnreadCount(String userId) {
    return messages.where((msg) => 
      msg.receiverId == userId && !msg.isRead
    ).length;
  }

  // Create a copy with updated fields
  Chat copyWith({
    List<Message>? messages,
    DateTime? updatedAt,
  }) {
    return Chat(
      id: id,
      user1: user1,
      user2: user2,
      messages: messages ?? this.messages,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Convert Chat to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1': user1.toJson(),
      'user2': user2.toJson(),
      'messages': messages.map((message) => message.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create Chat from JSON
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'],
      user1: User.fromJson(json['user1']),
      user2: User.fromJson(json['user2']),
      messages: (json['messages'] as List)
          .map((messageJson) => Message.fromJson(messageJson))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // For storing a list of chats
  static String encodeChats(List<Chat> chats) {
    return json.encode(
      chats.map((chat) => chat.toJson()).toList(),
    );
  }

  // For retrieving a list of chats
  static List<Chat> decodeChats(String chatsString) {
    final List<dynamic> decodedList = json.decode(chatsString);
    return decodedList
        .map((chatJson) => Chat.fromJson(chatJson))
        .toList();
  }
}

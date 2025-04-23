import 'dart:convert';

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
  });

  // Create a copy with updated fields
  Message copyWith({
    bool? isRead,
  }) {
    return Message(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      content: content,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
    );
  }

  // Convert Message to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  // Create Message from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
    );
  }

  // For storing a list of messages
  static String encodeMessages(List<Message> messages) {
    return json.encode(
      messages.map((message) => message.toJson()).toList(),
    );
  }

  // For retrieving a list of messages
  static List<Message> decodeMessages(String messagesString) {
    final List<dynamic> decodedList = json.decode(messagesString);
    return decodedList
        .map((messageJson) => Message.fromJson(messageJson))
        .toList();
  }
}

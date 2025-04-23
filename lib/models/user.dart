import 'dart:convert';

class User {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Create a copy of the user with updated fields
  User copyWith({
    String? name,
    String? email,
    String? avatar,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt,
    );
  }

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatar: json['avatar'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  // For storing a list of users
  static String encodeUsers(List<User> users) {
    return json.encode(
      users.map((user) => user.toJson()).toList(),
    );
  }

  // For retrieving a list of users
  static List<User> decodeUsers(String usersString) {
    final List<dynamic> decodedList = json.decode(usersString);
    return decodedList
        .map((userJson) => User.fromJson(userJson))
        .toList();
  }
}

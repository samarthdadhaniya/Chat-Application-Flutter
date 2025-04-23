import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_chat_app/models/user.dart';
import 'package:flutter_chat_app/models/chat.dart';

class StorageService {
  static const String _usersKey = 'users';
  static const String _chatsKey = 'chats';
  static const String _currentUserKey = 'current_user';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Save users to local storage
  Future<void> saveUsers(List<User> users) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedUsers = User.encodeUsers(users);
    await prefs.setString(_usersKey, encodedUsers);
  }

  // Get users from local storage
  Future<List<User>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersString = prefs.getString(_usersKey);
    
    if (usersString == null) {
      return [];
    }
    
    return User.decodeUsers(usersString);
  }

  // Save chats to local storage
  Future<void> saveChats(List<Chat> chats) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedChats = Chat.encodeChats(chats);
    await prefs.setString(_chatsKey, encodedChats);
  }

  // Get chats from local storage
  Future<List<Chat>> getChats() async {
    final prefs = await SharedPreferences.getInstance();
    final String? chatsString = prefs.getString(_chatsKey);
    
    if (chatsString == null) {
      return [];
    }
    
    return Chat.decodeChats(chatsString);
  }

  // Save current user ID
  Future<void> saveCurrentUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, userId);
  }

  // Get current user ID
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  // Clear current user (logout)
  Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Save user credentials securely
  Future<void> saveUserCredentials(String email, String password) async {
    await _secureStorage.write(key: email, value: password);
  }

  // Verify user credentials
  Future<bool> verifyUserCredentials(String email, String password) async {
    final storedPassword = await _secureStorage.read(key: email);
    return storedPassword == password;
  }

  // Clear all data (for testing)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secureStorage.deleteAll();
  }
}

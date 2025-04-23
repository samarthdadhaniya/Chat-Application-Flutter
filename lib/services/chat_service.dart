import 'package:flutter/material.dart';
import 'package:flutter_chat_app/models/chat.dart';
import 'package:flutter_chat_app/models/message.dart';
import 'package:flutter_chat_app/models/user.dart';
import 'package:flutter_chat_app/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class ChatService extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final Uuid _uuid = const Uuid();
  
  // State
  List<User> _users = [];
  List<Chat> _chats = [];
  User? _currentUser;
  bool _isLoading = true;

  // Getters
  User? get currentUser => _currentUser;
  List<Chat> get chats => _chats.where((chat) => 
    chat.user1.id == _currentUser?.id || chat.user2.id == _currentUser?.id
  ).toList();
  List<User> get availableUsers => _users.where((user) => user.id != _currentUser?.id).toList();
  List<User> get allUsers => _users;
  bool get isLoading => _isLoading;

  // Constructor
  ChatService() {
    _initializeData();
  }

  // Initialize data from local storage
  Future<void> _initializeData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load users and chats from storage
      _users = await _storageService.getUsers();
      _chats = await _storageService.getChats();

      // If no users exist, create sample data
      if (_users.isEmpty) {
        _createSampleData();
      }

      // Try to restore the current user session
      final currentUserId = await _storageService.getCurrentUserId();
      if (currentUserId != null) {
        final user = _users.firstWhere(
          (user) => user.id == currentUserId,
          orElse: () => _users.first,
        );
        _currentUser = user;
      }
    } catch (e) {
      debugPrint('Error initializing data: $e');
      // Create sample data if there's an error
      _createSampleData();
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create sample data for first-time users
  void _createSampleData() {
    // Create sample users
    _users = [
      User(
        id: _uuid.v4(),
        name: 'John Doe',
        email: 'john@example.com',
        avatar: 'https://i.pravatar.cc/150?img=1',
      ),
      User(
        id: _uuid.v4(),
        name: 'Jane Smith',
        email: 'jane@example.com',
        avatar: 'https://i.pravatar.cc/150?img=5',
      ),
    ];

    // Create a sample chat
    final chat = Chat(
      id: _uuid.v4(),
      user1: _users[0],
      user2: _users[1],
      messages: [
        Message(
          id: _uuid.v4(),
          senderId: _users[0].id,
          receiverId: _users[1].id,
          content: 'Hey Jane, welcome to the chat app!',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        Message(
          id: _uuid.v4(),
          senderId: _users[1].id,
          receiverId: _users[0].id,
          content: 'Thanks John! This looks great.',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ],
    );

    _chats = [chat];

    // Save to storage
    _saveData();
  }

  // Save all data to storage
  Future<void> _saveData() async {
    await _storageService.saveUsers(_users);
    await _storageService.saveChats(_chats);
    if (_currentUser != null) {
      await _storageService.saveCurrentUserId(_currentUser!.id);
    }
  }

  // Register a new user
  Future<bool> register(String name, String email, String password) async {
    // Check if email already exists
    final existingUser = _users.firstWhere(
      (user) => user.email.toLowerCase() == email.toLowerCase(),
      orElse: () => User(
        id: '',
        name: '',
        email: '',
        avatar: '',
      ),
    );

    if (existingUser.id.isNotEmpty) {
      return false; // Email already exists
    }

    // Create new user
    final newUser = User(
      id: _uuid.v4(),
      name: name,
      email: email,
      avatar: 'https://i.pravatar.cc/150?img=${_users.length + 1}',
    );

    _users.add(newUser);
    await _saveData();
    
    // Save credentials
    await _storageService.saveUserCredentials(email, password);
    
    // Log in the new user
    _currentUser = newUser;
    notifyListeners();
    
    return true;
  }

  // Login user
  Future<bool> login(String email, String password) async {
    // Verify credentials
    final isValid = await _storageService.verifyUserCredentials(email, password);
    if (!isValid) {
      return false;
    }

    // Find user by email
    final user = _users.firstWhere(
      (user) => user.email.toLowerCase() == email.toLowerCase(),
      orElse: () => User(
        id: '',
        name: '',
        email: '',
        avatar: '',
      ),
    );

    if (user.id.isEmpty) {
      return false;
    }

    _currentUser = user;
    await _storageService.saveCurrentUserId(user.id);
    notifyListeners();
    
    return true;
  }

  // Logout user
  Future<void> logout() async {
    _currentUser = null;
    await _storageService.clearCurrentUser();
    notifyListeners();
  }

  // Update user profile
  Future<void> updateProfile(String name, String avatar) async {
    if (_currentUser == null) return;

    final updatedUser = _currentUser!.copyWith(
      name: name,
      avatar: avatar,
    );

    // Update in users list
    final index = _users.indexWhere((user) => user.id == _currentUser!.id);
    if (index != -1) {
      _users[index] = updatedUser;
    }

    // Update current user
    _currentUser = updatedUser;

    // Update user in all chats
    for (var i = 0; i < _chats.length; i++) {
      if (_chats[i].user1.id == updatedUser.id) {
        _chats[i] = Chat(
          id: _chats[i].id,
          user1: updatedUser,
          user2: _chats[i].user2,
          messages: _chats[i].messages,
          createdAt: _chats[i].createdAt,
          updatedAt: _chats[i].updatedAt,
        );
      } else if (_chats[i].user2.id == updatedUser.id) {
        _chats[i] = Chat(
          id: _chats[i].id,
          user1: _chats[i].user1,
          user2: updatedUser,
          messages: _chats[i].messages,
          createdAt: _chats[i].createdAt,
          updatedAt: _chats[i].updatedAt,
        );
      }
    }

    await _saveData();
    notifyListeners();
  }

  // Get chat by id
  Chat getChatById(String chatId) {
    return _chats.firstWhere((chat) => chat.id == chatId);
  }

  // Send message
  Future<void> sendMessage(String chatId, String content) async {
    if (_currentUser == null) return;

    final chat = _chats.firstWhere((chat) => chat.id == chatId);
    final receiverId = chat.user1.id == _currentUser!.id ? chat.user2.id : chat.user1.id;

    final newMessage = Message(
      id: _uuid.v4(),
      senderId: _currentUser!.id,
      receiverId: receiverId,
      content: content,
      timestamp: DateTime.now(),
    );

    final chatIndex = _chats.indexWhere((c) => c.id == chatId);
    final updatedMessages = [..._chats[chatIndex].messages, newMessage];
    
    _chats[chatIndex] = _chats[chatIndex].copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
    
    await _saveData();
    notifyListeners();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    if (_currentUser == null) return;

    final chatIndex = _chats.indexWhere((c) => c.id == chatId);
    if (chatIndex == -1) return;

    final chat = _chats[chatIndex];
    bool hasChanges = false;

    final updatedMessages = chat.messages.map((message) {
      if (message.receiverId == _currentUser!.id && !message.isRead) {
        hasChanges = true;
        return message.copyWith(isRead: true);
      }
      return message;
    }).toList();

    if (hasChanges) {
      _chats[chatIndex] = chat.copyWith(
        messages: updatedMessages,
      );
      
      await _saveData();
      notifyListeners();
    }
  }

  // Create new chat
  Future<String> createNewChat(String otherUserId) async {
    if (_currentUser == null) return '';

    // Check if chat already exists
    final existingChat = _chats.firstWhere(
      (chat) => 
        (chat.user1.id == _currentUser!.id && chat.user2.id == otherUserId) ||
        (chat.user1.id == otherUserId && chat.user2.id == _currentUser!.id),
      orElse: () => Chat(
        id: '',
        user1: _users[0],
        user2: _users[0],
        messages: [],
      ),
    );

    if (existingChat.id.isNotEmpty) {
      return existingChat.id;
    }

    // Create new chat
    final otherUser = _users.firstWhere((user) => user.id == otherUserId);
    final newChat = Chat(
      id: _uuid.v4(),
      user1: _currentUser!,
      user2: otherUser,
      messages: [],
    );

    _chats.add(newChat);
    await _saveData();
    notifyListeners();
    
    return newChat.id;
  }

  // Delete chat
  Future<void> deleteChat(String chatId) async {
    _chats.removeWhere((chat) => chat.id == chatId);
    await _saveData();
    notifyListeners();
  }

  // Get total unread message count
  int getTotalUnreadCount() {
    if (_currentUser == null) return 0;
    
    return _chats.fold(0, (total, chat) {
      return total + chat.getUnreadCount(_currentUser!.id);
    });
  }
}

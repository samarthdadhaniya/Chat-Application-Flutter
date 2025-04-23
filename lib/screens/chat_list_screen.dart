import 'package:flutter/material.dart';
import 'package:flutter_chat_app/models/chat.dart';
import 'package:flutter_chat_app/screens/chat_screen.dart';
import 'package:flutter_chat_app/screens/login_screen.dart';
import 'package:flutter_chat_app/screens/profile_screen.dart';
import 'package:flutter_chat_app/services/chat_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final currentUser = chatService.currentUser;
    
    if (currentUser == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Chat'),
        actions: [
          // Profile button
          IconButton(
            icon: Hero(
              tag: 'profile-avatar',
              child: CircleAvatar(
                radius: 16,
                backgroundImage: CachedNetworkImageProvider(currentUser.avatar),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chats'),
            Tab(text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Chats tab
          _ChatsTab(),
          
          // Users tab
          _UsersTab(),
        ],
      ),
    );
  }
}

class _ChatsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final currentUser = chatService.currentUser;
    final chats = chatService.chats;
    
    if (currentUser == null) {
      return const Center(child: Text('Please log in'));
    }

    // Sort chats by last message timestamp
    chats.sort((a, b) {
      if (a.lastMessage == null && b.lastMessage == null) return 0;
      if (a.lastMessage == null) return 1;
      if (b.lastMessage == null) return -1;
      return b.lastMessage!.timestamp.compareTo(a.lastMessage!.timestamp);
    });

    if (chats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 50,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No chats yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a conversation by tapping on a user',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final tabController = DefaultTabController.of(context);
                if (tabController != null) {
                  tabController.animateTo(1); // Switch to Users tab
                }
              },
              icon: const Icon(Icons.person_add),
              label: const Text('Find Users'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (context, index) {
        final chat = chats[index];
        final otherUser = chat.getOtherUser(currentUser.id);
        final lastMessage = chat.lastMessage;
        final unreadCount = chat.getUnreadCount(currentUser.id);
        
        return Animate(
          effects: [
            FadeEffect(
              duration: 300.ms,
              delay: (50 * index).ms,
            ),
            SlideEffect(
              begin: const Offset(0, 0.1),
              end: const Offset(0, 0),
              duration: 300.ms,
              delay: (50 * index).ms,
            ),
          ],
          child: Dismissible(
            key: Key(chat.id),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Chat'),
                  content: const Text('Are you sure you want to delete this chat?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) {
              chatService.deleteChat(chat.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Chat with ${otherUser.name} deleted'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      // This is just for show - we can't actually undo in this demo
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('This feature is not implemented in the demo')),
                      );
                    },
                  ),
                ),
              );
            },
            child: ListTile(
              leading: Hero(
                tag: 'avatar-${otherUser.id}',
                child: CircleAvatar(
                  radius: 25,
                  backgroundImage: CachedNetworkImageProvider(otherUser.avatar),
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      otherUser.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (lastMessage != null)
                    Text(
                      _formatTimestamp(lastMessage.timestamp),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              subtitle: Row(
                children: [
                  Expanded(
                    child: Text(
                      chat.getLastMessagePreview(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: unreadCount > 0 ? Colors.black : Colors.grey,
                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.teal,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(chatId: chat.id),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return DateFormat.jm().format(timestamp); // Today: 3:30 PM
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat.MMMd().format(timestamp); // Jan 5
    }
  }
}

class _UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final currentUser = chatService.currentUser;
    final availableUsers = chatService.availableUsers;
    
    if (currentUser == null) {
      return const Center(child: Text('Please log in'));
    }

    if (availableUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No other users yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Invite friends to join the app',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: availableUsers.length,
      itemBuilder: (context, index) {
        final user = availableUsers[index];
        
        return Animate(
          effects: [
            FadeEffect(
              duration: 300.ms,
              delay: (50 * index).ms,
            ),
            SlideEffect(
              begin: const Offset(0, 0.1),
              end: const Offset(0, 0),
              duration: 300.ms,
              delay: (50 * index).ms,
            ),
          ],
          child: ListTile(
            leading: Hero(
              tag: 'avatar-${user.id}',
              child: CircleAvatar(
                radius: 25,
                backgroundImage: CachedNetworkImageProvider(user.avatar),
              ),
            ),
            title: Text(
              user.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(user.email),
            trailing: const Icon(Icons.chat_bubble_outline),
            onTap: () async {
              final chatId = await chatService.createNewChat(user.id);
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(chatId: chatId),
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_chat_app/screens/chat_screen.dart';
import 'package:flutter_chat_app/services/chat_service.dart';
import 'package:provider/provider.dart';

class NewChatScreen extends StatelessWidget {
  const NewChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final availableUsers = chatService.availableUsers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
      ),
      body: availableUsers.isEmpty
          ? const Center(
              child: Text(
                'No users available to chat with',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: availableUsers.length,
              itemBuilder: (context, index) {
                final user = availableUsers[index];
                
                return ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(user.avatar),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () {
                    final chatId = chatService.createNewChat(user.id);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(chatId: chatId),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

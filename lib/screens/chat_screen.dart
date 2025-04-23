import 'package:flutter/material.dart';
import 'package:flutter_chat_app/models/chat.dart';
import 'package:flutter_chat_app/models/message.dart';
import 'package:flutter_chat_app/models/user.dart';
import 'package:flutter_chat_app/services/chat_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when opening the chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatService = Provider.of<ChatService>(context, listen: false);
      chatService.markMessagesAsRead(widget.chatId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

void _sendMessage() {
  if (_messageController.text.trim().isEmpty) return;

  final chatService = Provider.of<ChatService>(context, listen: false);
  chatService.sendMessage(
    widget.chatId,
    _messageController.text.trim(),
  );
  _messageController.clear();

  // Optional: simulate typing indicator briefly (can also remove this if not needed)
  setState(() {
    _isTyping = true;
  });

  // Stop typing indicator after a short delay
  Future.delayed(const Duration(seconds: 1), () {
    if (mounted) {
      setState(() {
        _isTyping = false;
      });
    }
  });
}


  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final currentUser = chatService.currentUser!;
    final chat = chatService.getChatById(widget.chatId);
    final otherUser = chat.getOtherUser(currentUser.id);

    // Mark messages as read when viewing the chat
    chatService.markMessagesAsRead(widget.chatId);

    // Scroll to bottom when new messages are added
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        leadingWidth: 30,
        title: Row(
          children: [
            Hero(
              tag: 'avatar-${otherUser.id}',
              child: CircleAvatar(
                radius: 18,
                backgroundImage: CachedNetworkImageProvider(otherUser.avatar),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUser.name,
                    style: const TextStyle(fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isTyping ? 'typing...' : 'online',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isTyping ? Colors.teal : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _ChatInfoBottomSheet(user: otherUser),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: chat.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Say hello to ${otherUser.name}!',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, index) {
                      final message = chat.messages[index];
                      final isMe = message.senderId == currentUser.id;
                      final showTimestamp = index == 0 ||
                          _shouldShowTimestamp(
                              chat.messages[index - 1], message);

                      return Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (showTimestamp)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    _formatMessageDate(message.timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Animate(
                            effects: [
                              if (index == chat.messages.length - 1)
                                SlideEffect(
                                  begin: Offset(isMe ? 0.3 : -0.3, 0),
                                  end: const Offset(0, 0),
                                  duration: 300.ms,
                                )
                              else
                                FadeEffect(duration: Duration.zero),
                            ],
                            child: _MessageBubble(
                              message: message,
                              isMe: isMe,
                              sender: isMe ? currentUser : otherUser,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Typing indicator
          if (_isTyping)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(
                    width: 40,
                    child: _TypingIndicator(),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${otherUser.name} is typing...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

          // Message input
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  color: Colors.grey.shade700,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Image sharing not implemented in this demo'),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 1,
                    maxLines: 5,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.teal,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () {
                      if (_messageController.text.trim().isNotEmpty) {
                        _sendMessage();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowTimestamp(Message previous, Message current) {
    final difference = current.timestamp.difference(previous.timestamp);
    return difference.inMinutes > 30;
  }

  String _formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today, ${DateFormat.jm().format(date)}';
    } else if (messageDate == yesterday) {
      return 'Yesterday, ${DateFormat.jm().format(date)}';
    } else {
      return DateFormat('MMM d, y • h:mm a').format(date);
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final User sender;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.sender,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: CachedNetworkImageProvider(sender.avatar),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Colors.teal : Colors.grey.shade200,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                bottomRight: isMe ? Radius.zero : const Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat.jm().format(message.timestamp),
                      style: TextStyle(
                        color: isMe ? Colors.white70 : Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isRead ? Icons.done_all : Icons.done,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundImage: CachedNetworkImageProvider(sender.avatar),
            ),
          ],
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            _buildDot(0),
            const SizedBox(width: 2),
            _buildDot(1),
            const SizedBox(width: 2),
            _buildDot(2),
          ],
        );
      },
    );
  }

  Widget _buildDot(int index) {
    final delay = index * 0.2;
    final begin = 0.1;
    final end = 0.8;

    final animation = Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          delay,
          delay + 0.6,
          curve: Curves.easeInOut,
        ),
      ),
    );

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(animation.value),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ChatInfoBottomSheet extends StatelessWidget {
  final User user;

  const _ChatInfoBottomSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: CachedNetworkImageProvider(user.avatar),
          ),
          const SizedBox(height: 16),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.email,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.call,
                label: 'Call',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Calling not implemented in this demo'),
                    ),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.videocam,
                label: 'Video',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Video call not implemented in this demo'),
                    ),
                  );
                },
              ),
              _buildActionButton(
                icon: Icons.search,
                label: 'Search',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Search not implemented in this demo'),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.teal,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}

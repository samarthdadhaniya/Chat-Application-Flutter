import 'package:flutter/material.dart';
import 'package:flutter_chat_app/screens/login_screen.dart';
import 'package:flutter_chat_app/services/chat_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  String _avatarUrl = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final chatService = Provider.of<ChatService>(context, listen: false);
    final currentUser = chatService.currentUser;
    
    if (currentUser != null) {
      _nameController = TextEditingController(text: currentUser.name);
      _avatarUrl = currentUser.avatar;
    } else {
      _nameController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.updateProfile(
        _nameController.text.trim(),
        _avatarUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    // In a real app, we would use ImagePicker to select an image
    // and upload it to a storage service. For this demo, we'll
    // just use a random avatar from a placeholder service.
    
    // Simulate picking an image
    setState(() {
      _isLoading = true;
    });
    
    await Future.delayed(const Duration(seconds: 1));
    
    // Generate a random avatar
    final randomNum = DateTime.now().millisecondsSinceEpoch % 70;
    setState(() {
      _avatarUrl = 'https://i.pravatar.cc/300?img=$randomNum';
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    await chatService.logout();
    
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
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
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Avatar
              Center(
                child: Stack(
                  children: [
                    Hero(
                      tag: 'profile-avatar',
                      child: CircleAvatar(
                        radius: 60,
                        backgroundImage: CachedNetworkImageProvider(_avatarUrl),
                      ),
                    ).animate()
                      .fadeIn()
                      .scale(delay: 200.ms),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.teal,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                          onPressed: _isLoading ? null : _pickAvatar,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Email (non-editable)
              TextFormField(
                initialValue: currentUser.email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                readOnly: true,
                enabled: false,
              ).animate()
                .fadeIn(delay: 300.ms)
                .slideX(begin: -0.1, end: 0),
              const SizedBox(height: 16),
              
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ).animate()
                .fadeIn(delay: 400.ms)
                .slideX(begin: -0.1, end: 0),
              const SizedBox(height: 32),
              
              // Update button
              ElevatedButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Update Profile'),
              ).animate()
                .fadeIn(delay: 500.ms)
                .slideY(begin: 0.1, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

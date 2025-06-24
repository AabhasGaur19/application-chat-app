import 'package:application_chat/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'chat_list_screen.dart';

class LoginScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Chat App',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  final user = await _authService.signInWithGoogle();
                  if (user != null && context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => ChatListScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sign-in failed. Try again.')),
                    );
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
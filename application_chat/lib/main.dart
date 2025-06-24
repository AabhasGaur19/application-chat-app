import 'package:application_chat/services/auth_service.dart';
import 'package:application_chat/utils/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:application_chat/screens/login_screen.dart';
import 'package:application_chat/screens/chat_list_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  tz.initializeTimeZones();
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return MaterialApp(
      title: 'Chat App',
      theme: AppTheme.material3Theme,
      home: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const ChatListScreen();
          }
          return LoginScreen();
        },
      ),
    );
  }
}
import 'package:application_chat/services/api_service.dart';
import 'package:application_chat/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'chat_list_screen.dart';

class ProfileScreen extends StatefulWidget {
  ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _displayName;
  String? _email;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await _apiService.getProfile();
      if (user != null) {
        setState(() {
          _displayName = user.displayName;
          _email = user.email;
          _photoUrl = user.photoUrl;
        });
      } else {
        final firebaseUser = _authService.currentUser;
        await _apiService.createOrUpdateProfile(firebaseUser?.displayName ?? 'User');
        setState(() {
          _displayName = firebaseUser?.displayName ?? 'User';
          _email = firebaseUser?.email ?? 'No email';
          _photoUrl = firebaseUser?.photoURL;
        });
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_photoUrl != null)
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: NetworkImage(_photoUrl!),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      _displayName ?? 'User',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _email ?? 'No email',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfileScreen(
                              initialDisplayName: _displayName ?? 'User',
                              initialPhotoUrl: _photoUrl,
                            ),
                          ),
                        );
                        if (result != null && context.mounted) {
                          setState(() {
                            _displayName = result['displayName'];
                            if (result['photoUrl'] != null) {
                              _photoUrl = result['photoUrl'];
                            }
                          });
                        }
                      },
                      child: const Text('Edit Profile'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await _authService.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => LoginScreen()),
                          );
                        }
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
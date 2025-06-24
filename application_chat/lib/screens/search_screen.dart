import 'package:application_chat/models/user_model.dart';
import 'package:application_chat/services/api_service.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<UserModel> _searchResults = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load all users on init
    _searchUsers('');
    // Listen for text changes
    _searchController.addListener(() {
      _searchUsers(_searchController.text);
    });
  }

  Future<void> _searchUsers(String query) async {
    setState(() => _isLoading = true);
    try {
      final results = await _apiService.searchUsers(query);
      if (mounted) {
        setState(() => _searchResults = results);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _startChat(UserModel user) async {
    try {
      final chat = await _apiService.createChat(user.uid);
      if (chat != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              chatId: chat.id,
              recipient: user,
            ),
          ),
        );
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to start chat: Unable to create chat')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          leading: user.photoUrl != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(user.photoUrl!),
                                )
                              : const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(user.displayName),
                          subtitle: Text(user.email),
                          onTap: () => _startChat(user),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
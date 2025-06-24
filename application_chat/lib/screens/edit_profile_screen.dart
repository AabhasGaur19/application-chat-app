import 'dart:io';
import 'package:application_chat/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final String initialDisplayName;
  final String? initialPhotoUrl;

  const EditProfileScreen({
    super.key,
    required this.initialDisplayName,
    this.initialPhotoUrl,
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ApiService _apiService = ApiService();
  File? _image;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialDisplayName;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _image = File(pickedFile.path);
        _error = null;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final updatedProfile = await _apiService.updateDisplayName(_nameController.text);
      String? photoUrl;
      if (_image != null) {
        photoUrl = await _apiService.uploadProfilePicture(_image!);
        if (photoUrl == null) {
          throw Exception('Profile picture upload failed');
        }
      }
      if (mounted) {
        Navigator.pop(context, {
          'displayName': _nameController.text,
          'photoUrl': photoUrl ?? widget.initialPhotoUrl,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to save profile: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_error != null)
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : widget.initialPhotoUrl != null
                              ? NetworkImage(widget.initialPhotoUrl!)
                              : null,
                      onBackgroundImageError: widget.initialPhotoUrl != null
                          ? (error, stackTrace) {
                              setState(() {
                                _error = 'Failed to load profile picture';
                              });
                            }
                          : null,
                      child: _image == null && widget.initialPhotoUrl == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save Profile'),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
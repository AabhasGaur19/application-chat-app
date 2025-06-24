// import 'dart:convert';
// import 'dart:io';
// import 'package:http/http.dart' as http;
// import 'package:application_chat/models/user_model.dart';
// import 'package:application_chat/models/chat_model.dart';
// import 'package:application_chat/models/message_model.dart';
// import 'package:application_chat/services/auth_service.dart';

// class ApiService {
//   static const String baseUrl = 'http://192.168.19.149:3000/api';
//   final AuthService _authService = AuthService();

//   Future<Map<String, String>> _getHeaders() async {
//     final user = _authService.currentUser;
//     if (user == null) throw Exception('Not authenticated');
//     final token = await user.getIdToken();
//     return {
//       'Content-Type': 'application/json',
//       'Authorization': 'Bearer $token',
//     };
//   }

//   Future<UserModel?> createOrUpdateProfile(String displayName) async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.post(
//         Uri.parse('$baseUrl/users/profile'),
//         headers: headers,
//         body: jsonEncode({'displayName': displayName}),
//       );
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return UserModel.fromJson(data);
//       }
//       throw Exception('Failed to save profile: ${response.body}');
//     } catch (e) {
//       print('Error: $e');
//       return null;
//     }
//   }

//   Future<UserModel?> getProfile() async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(Uri.parse('$baseUrl/users/profile'), headers: headers);
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return UserModel.fromJson(data);
//       }
//       throw Exception('Failed to fetch profile: ${response.body}');
//     } catch (e) {
//       print('Error: $e');
//       return null;
//     }
//   }

//   Future<UserModel?> updateDisplayName(String displayName) async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.put(
//         Uri.parse('$baseUrl/users/profile'),
//         headers: headers,
//         body: jsonEncode({'displayName': displayName}),
//       );
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         return UserModel.fromJson(data);
//       }
//       throw Exception('Failed to update display name: ${response.body}');
//     } catch (e) {
//       print('Error: $e');
//       return null;
//     }
//   }

//   Future<String?> uploadProfilePicture(File image) async {
//     try {
//       final headers = await _getHeaders();
//       final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/profile/picture'));
//       request.headers.addAll(headers);
//       request.files.add(await http.MultipartFile.fromPath('photo', image.path));
//       final response = await request.send();
//       final responseBody = await response.stream.bytesToString();
//       if (response.statusCode == 200) {
//         final data = jsonDecode(responseBody);
//         return data['photoUrl'];
//       }
//       throw Exception('Failed to upload picture: $responseBody');
//     } catch (e) {
//       print('Error: $e');
//       return null;
//     }
//   }

//   Future<List<UserModel>> searchUsers(String query) async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/users/search?q=$query'),
//         headers: headers,
//       );
//       print('SearchUsers Response: ${response.statusCode} - ${response.body}');
//       if (response.statusCode == 200) {
//         final List data = jsonDecode(response.body);
//         return data.map((item) => UserModel.fromJson(item)).toList();
//       }
//       throw Exception('Search failed: ${response.body}');
//     } catch (e) {
//       print('Error: $e');
//       throw e;
//     }
//   }

//   Future<ChatModel?> createChat(String participantId) async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.post(
//         Uri.parse('$baseUrl/chats'),
//         headers: headers,
//         body: jsonEncode({'participantId': participantId}),
//       );
//       print('CreateChat Response: ${response.statusCode} - ${response.body}');
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final body = response.body;
//         if (body.isEmpty) {
//           throw Exception('Empty response body');
//         }
//         final data = jsonDecode(body);
//         if (data is! Map<String, dynamic>) {
//           throw Exception('Invalid response format: expected JSON object, got $body');
//         }
//         return ChatModel.fromJson(data);
//       }
//       final errorData = jsonDecode(response.body);
//       throw Exception('Failed to create chat: ${errorData['error']} - ${errorData['details']}');
//     } catch (e) {
//       print('Error creating chat: $e');
//       throw e;
//     }
//   }

//   Future<List<ChatModel>> getChats() async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/chats'),
//         headers: headers,
//       );
//       if (response.statusCode == 200) {
//         final List data = jsonDecode(response.body);
//         return data.map((item) => ChatModel.fromJson(item)).toList();
//       }
//       throw Exception('Failed to fetch chats: ${response.body}');
//     } catch (e) {
//       print('Error: $e');
//       return [];
//     }
//   }

//   Future<List<MessageModel>> getMessages(String chatId) async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.get(
//         Uri.parse('$baseUrl/chats/$chatId/messages'),
//         headers: headers,
//       );
//       // print('GetMessages Response: ${response.statusCode} - ${response.body}');
//       if (response.statusCode == 200) {
//         final List data = jsonDecode(response.body);
//         return data.map((item) => MessageModel.fromJson(item)).toList();
//       }
//       throw Exception('Failed to fetch messages: ${response.body}');
//     } catch (e) {
//       print('Error: $e');
//       return [];
//     }
//   }

//   Future<MessageModel?> sendMessage(String chatId, String content) async {
//     try {
//       final headers = await _getHeaders();
//       final response = await http.post(
//         Uri.parse('$baseUrl/chats/$chatId/messages'),
//         headers: headers,
//         body: jsonEncode({'content': content}),
//       );
//       if (response.statusCode == 201) {
//         final data = jsonDecode(response.body);
//         return MessageModel.fromJson(data);
//       }
//       throw Exception('Failed to send message: ${response.body}');
//     } catch (e) {
//       print('Error: $e');
//       return null;
//     }
//   }
// }



import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:application_chat/models/user_model.dart';
import 'package:application_chat/models/chat_model.dart';
import 'package:application_chat/models/message_model.dart';
import 'package:application_chat/services/auth_service.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.19.149:3000/api';
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _getHeaders() async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('Not authenticated');
    final token = await user.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<UserModel?> createOrUpdateProfile(String displayName) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
        body: jsonEncode({'displayName': displayName}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      }
      throw Exception('Failed to save profile: ${response.body}');
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<UserModel?> getProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/users/profile'), headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      }
      throw Exception('Failed to fetch profile: ${response.body}');
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  Future<UserModel?> updateDisplayName(String displayName) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
        body: jsonEncode({'displayName': displayName}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel.fromJson(data);
      }
      throw Exception('Failed to update display name: ${response.body}');
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }

  // Future<String?> uploadProfilePicture(File image) async {
  //   try {
  //     final headers = await _getHeaders();
  //     final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/profile/picture'));
  //     request.headers.addAll(headers);
  //     request.files.add(await http.MultipartFile.fromPath('photo', image.path));
  //     final response = await request.send();
  //     final responseBody = await response.stream.bytesToString();
  //     print('UploadProfilePicture Response: ${response.statusCode} - $responseBody');
  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(responseBody);
  //       return data['photoUrl'];
  //     }
  //     throw Exception('Failed to upload picture: $responseBody');
  //   } catch (e) {
  //     print('Error: $e');
  //     return null;
  //   }
  // }
  Future<String?> uploadProfilePicture(File image) async {
  try {
    final headers = await _getHeaders();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/profile/picture'));
    request.headers.addAll(headers);
    
    // Read file as bytes
    final bytes = await image.readAsBytes();
    final fileName = image.path.split('/').last;
    final fileExtension = fileName.split('.').last.toLowerCase();
    
    // Determine content type
    String contentType;
    switch (fileExtension) {
      case 'jpg':
      case 'jpeg':
        contentType = 'image/jpeg';
        break;
      case 'png':
        contentType = 'image/png';
        break;
      case 'gif':
        contentType = 'image/gif';
        break;
      case 'webp':
        contentType = 'image/webp';
        break;
      default:
        contentType = 'image/jpeg';
    }
    
    print('File: $fileName, Extension: $fileExtension, Content-Type: $contentType');
    
    // Create multipart file from bytes
    final multipartFile = http.MultipartFile.fromBytes(
      'photo',
      bytes,
      filename: fileName,
      contentType: MediaType.parse(contentType),
    );
    
    request.files.add(multipartFile);
    
    print('Sending request with ${bytes.length} bytes');
    
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    print('UploadProfilePicture Response: ${response.statusCode} - $responseBody');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['photoUrl'];
    }
    throw Exception('Failed to upload picture: $responseBody');
  } catch (e) {
    print('Error: $e');
    return null;
  }
}

  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/search?q=$query'),
        headers: headers,
      );
      print('SearchUsers Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => UserModel.fromJson(item)).toList();
      }
      throw Exception('Search failed: ${response.body}');
    } catch (e) {
      print('Error: $e');
      throw e;
    }
  }

  Future<ChatModel?> createChat(String participantId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/chats'),
        headers: headers,
        body: jsonEncode({'participantId': participantId}),
      );
      print('CreateChat Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.body;
        if (body.isEmpty) {
          throw Exception('Empty response body');
        }
        final data = jsonDecode(body);
        if (data is! Map<String, dynamic>) {
          throw Exception('Invalid response format: expected JSON object, got $body');
        }
        return ChatModel.fromJson(data);
      }
      final errorData = jsonDecode(response.body);
      throw Exception('Failed to create chat: ${errorData['error']} - ${errorData['details']}');
    } catch (e) {
      print('Error creating chat: $e');
      throw e;
    }
  }

  Future<List<ChatModel>> getChats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chats'),
        headers: headers,
      );
      print('GetChats Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => ChatModel.fromJson(item)).toList();
      }
      throw Exception('Failed to fetch chats: ${response.body}');
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  Future<List<MessageModel>> getMessages(String chatId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/chats/$chatId/messages'),
        headers: headers,
      );
      print('GetMessages Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        return data.map((item) => MessageModel.fromJson(item)).toList();
      }
      throw Exception('Failed to fetch messages: ${response.body}');
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  Future<MessageModel?> sendMessage(String chatId, String content) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/chats/$chatId/messages'),
        headers: headers,
        body: jsonEncode({'content': content}),
      );
      print('SendMessage Response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return MessageModel.fromJson(data);
      }
      throw Exception('Failed to send message: ${response.body}');
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}
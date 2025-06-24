// import 'package:application_chat/services/auth_service.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;

// class SocketService {
//   late IO.Socket _socket;
//   final AuthService _authService = AuthService();
//   final Map<String, Function(dynamic)> _listeners = {};

//   SocketService() {
//     _initSocket();
//   }

//   void _initSocket() async {
//     final token = await _authService.currentUser?.getIdToken();
//     _socket = IO.io('http://192.168.91.251:3000', <String, dynamic>{
//       'transports': ['websocket'],
//       'autoConnect': false,
//       'auth': {'token': token},
//     });

//     _socket.onConnect((_) => print('Socket connected'));
//     _socket.onDisconnect((_) => print('Socket disconnected'));
//     _socket.onConnectError((data) => print('Socket connect error: $data'));
//     _socket.onError((data) => print('Socket error: $data'));

//     _socket.connect();
//   }

//   void on(String event, Function(dynamic) callback) {
//     _listeners[event] = callback;
//     _socket.on(event, callback);
//   }

//   void emit(String event, dynamic data) {
//     _socket.emit(event, data);
//   }

//   void disconnect() {
//     _listeners.forEach((event, callback) {
//       _socket.off(event, callback);
//     });
//     _listeners.clear();
//     _socket.disconnect();
//   }
// }

import 'package:application_chat/services/auth_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? _socket; // Change to nullable to avoid late initialization
  final AuthService _authService = AuthService();
  final Map<String, Function(dynamic)> _listeners = {};
  bool _isInitialized = false;

  SocketService() {
    _initSocket();
  }

  Future<void> _initSocket() async {
    try {
      final token = await _authService.currentUser?.getIdToken();
      _socket = IO.io('http://192.168.19.149:3000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'auth': {'token': token},
      });

      _socket!.onConnect((_) => print('Socket connected'));
      _socket!.onDisconnect((_) => print('Socket disconnected'));
      _socket!.onConnectError((data) => print('Socket connect error: $data'));
      _socket!.onError((data) => print('Socket error: $data'));

      _socket!.connect();
      _isInitialized = true;
    } catch (e) {
      print('Socket initialization error: $e');
      _isInitialized = false;
    }
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await _initSocket();
    }
  }

  void on(String event, Function(dynamic) callback) {
    if (!_isInitialized || _socket == null) {
      print('Socket not initialized for event: $event');
      return;
    }
    _listeners[event] = callback;
    _socket!.on(event, callback);
  }

  void emit(String event, dynamic data) {
    if (!_isInitialized || _socket == null) {
      print('Socket not initialized for emit: $event');
      return;
    }
    _socket!.emit(event, data);
  }

  void disconnect() {
    if (_socket != null) {
      _listeners.forEach((event, callback) {
        _socket!.off(event, callback);
      });
      _listeners.clear();
      _socket!.disconnect();
      _socket = null;
      _isInitialized = false;
    }
  }
}
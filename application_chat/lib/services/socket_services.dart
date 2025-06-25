//application_chat/lib/services/socket_services.dart

import 'package:application_chat/services/auth_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  IO.Socket? _socket;
  final AuthService _authService = AuthService();
  final Map<String, Function(dynamic)> _listeners = {};
  bool _isInitialized = false;

  SocketService() {
    _initSocket();
  }

  Future<void> _initSocket() async {
    try {
      final token = await _authService.currentUser?.getIdToken();
      _socket = IO.io('https://application-chat-app.onrender.com', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true, // Changed to true for better connection
        'auth': {'token': token},
        'forceNew': true, // Force new connection
      });
//       // _socket = IO.io('http://192.168.19.149:3000', <String, dynamic>{
//       //   'transports': ['websocket'],
//       //   'autoConnect': false,
//       //   'auth': {'token': token},
//       // });

      _socket!.onConnect((_) {
        print('Socket connected');
        _isInitialized = true;
      });
      
      _socket!.onDisconnect((_) {
        print('Socket disconnected');
        _isInitialized = false;
      });
      
      _socket!.onConnectError((data) {
        print('Socket connect error: $data');
        _isInitialized = false;
      });
      
      _socket!.onError((data) {
        print('Socket error: $data');
      });

      // Auto-reconnect logic
      _socket!.on('disconnect', (_) {
        print('Attempting to reconnect...');
        Future.delayed(Duration(seconds: 2), () {
          if (_socket != null && !_socket!.connected) {
            _socket!.connect();
          }
        });
      });

    } catch (e) {
      print('Socket initialization error: $e');
      _isInitialized = false;
    }
  }

  Future<void> ensureInitialized() async {
    if (!_isInitialized || _socket == null || !_socket!.connected) {
      await _initSocket();
      // Wait a bit for connection to establish
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  void on(String event, Function(dynamic) callback) {
    if (_socket == null) {
      print('Socket not initialized for event: $event');
      return;
    }
    _listeners[event] = callback;
    _socket!.on(event, callback);
  }

  void emit(String event, dynamic data) {
    if (_socket == null || !_socket!.connected) {
      print('Socket not connected for emit: $event');
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
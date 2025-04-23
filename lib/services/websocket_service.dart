import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error
}

class WebSocketService {
  // This is a reference implementation - not used in the app yet
  
  // WebSocket server URL
  final String _serverUrl;
  
  // WebSocket channel
  WebSocketChannel? _channel;
  
  // Connection status
  ConnectionStatus _status = ConnectionStatus.disconnected;
  
  // Stream controller for messages
  final StreamController<Map<String, dynamic>> _messageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Stream controller for connection status
  final StreamController<ConnectionStatus> _statusController = 
      StreamController<ConnectionStatus>.broadcast();
  
  // Reconnect timer
  Timer? _reconnectTimer;
  
  // Heartbeat timer
  Timer? _heartbeatTimer;
  
  // Auth token
  String? _authToken;
  
  // Getters
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  ConnectionStatus get status => _status;
  
  // Constructor
  WebSocketService(this._serverUrl);
  
  // Connect to WebSocket server
  Future<void> connect({String? authToken}) async {
    if (_status == ConnectionStatus.connected || 
        _status == ConnectionStatus.connecting) {
      return;
    }
    
    _updateStatus(ConnectionStatus.connecting);
    _authToken = authToken;
    
    try {
      // Create WebSocket connection
      final uri = Uri.parse(_serverUrl);
      _channel = IOWebSocketChannel.connect(
        uri,
        headers: authToken != null ? {'Authorization': 'Bearer $authToken'} : null,
      );
      
      // Listen for messages
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      
      _updateStatus(ConnectionStatus.connected);
      debugPrint('WebSocket connected to $_serverUrl');
      
      // Start heartbeat
      _startHeartbeat();
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _updateStatus(ConnectionStatus.error);
      _scheduleReconnect();
    }
  }
  
  // Disconnect from WebSocket server
  void disconnect() {
    _stopHeartbeat();
    _stopReconnectTimer();
    
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }
    
    _updateStatus(ConnectionStatus.disconnected);
    debugPrint('WebSocket disconnected');
  }
  
  // Send message to WebSocket server
  void sendMessage(Map<String, dynamic> message) {
    if (_status != ConnectionStatus.connected) {
      debugPrint('Cannot send message: WebSocket not connected');
      return;
    }
    
    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      debugPrint('Message sent: $jsonMessage');
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }
  
  // Handle incoming message
  void _onMessage(dynamic message) {
    try {
      final Map<String, dynamic> jsonMessage = 
          message is String ? jsonDecode(message) : message;
      
      // Handle heartbeat response
      if (jsonMessage['type'] == 'pong') {
        debugPrint('Heartbeat response received');
        return;
      }
      
      // Forward message to stream
      _messageController.add(jsonMessage);
      debugPrint('Message received: $jsonMessage');
    } catch (e) {
      debugPrint('Error processing message: $e');
    }
  }
  
  // Handle WebSocket error
  void _onError(dynamic error) {
    debugPrint('WebSocket error: $error');
    _updateStatus(ConnectionStatus.error);
    _scheduleReconnect();
  }
  
  // Handle WebSocket connection closed
  void _onDone() {
    debugPrint('WebSocket connection closed');
    _updateStatus(ConnectionStatus.disconnected);
    _scheduleReconnect();
  }
  
  // Update connection status
  void _updateStatus(ConnectionStatus status) {
    _status = status;
    _statusController.add(status);
  }
  
  // Schedule reconnect
  void _scheduleReconnect() {
    _stopHeartbeat();
    _stopReconnectTimer();
    
    _updateStatus(ConnectionStatus.reconnecting);
    
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('Attempting to reconnect...');
      connect(authToken: _authToken);
    });
  }
  
  // Start heartbeat
  void _startHeartbeat() {
    _stopHeartbeat();
    
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_status == ConnectionStatus.connected) {
        sendMessage({'type': 'ping'});
        debugPrint('Heartbeat sent');
      }
    });
  }
  
  // Stop heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
  
  // Stop reconnect timer
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  // Dispose
  void dispose() {
    disconnect();
    _messageController.close();
    _statusController.close();
    debugPrint('WebSocket service disposed');
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

typedef WebSocketEventCallback = void Function(String eventType, Map<String, dynamic> data);

class WebSocketService {
  final String wsUrl;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  final List<WebSocketEventCallback> _listeners = [];
  Timer? _reconnectTimer;

  WebSocketService({this.wsUrl = 'ws://127.0.0.1:8000/ws/telemetry'});

  bool get isConnected => _isConnected;

  void addListener(WebSocketEventCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(WebSocketEventCallback callback) {
    _listeners.remove(callback);
  }

  void connect() {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _isConnected = true;

      _subscription = _channel?.stream.listen(
        (message) {
          try {
            final Map<String, dynamic> decoded = jsonDecode(message);
            final String event = decoded['event'] ?? 'UNKNOWN';
            final Map<String, dynamic> data = decoded['data'] ?? decoded;
            
            for (var listener in _listeners) {
              listener(event, data);
            }
          } catch (e) {
            // Raw text ignore
          }
        },
        onDone: () {
          _isConnected = false;
          _scheduleReconnect();
        },
        onError: (error) {
          _isConnected = false;
          _scheduleReconnect();
        },
      );
    } catch (e) {
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _isConnected = false;
  }
}

final wsService = WebSocketService();

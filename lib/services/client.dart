import 'dart:io';
import 'dart:convert';

class TcpClient {
  Socket? _socket;
  bool _isConnected = false;
  final List<void Function(String)> _messageCallbacks = [];

  bool get isConnected => _isConnected;

  void addMessageListener(void Function(String message) callback) {
    _messageCallbacks.add(callback);
  }

  void _notifyListeners(String message) {
    for (var callback in _messageCallbacks) {
      callback(message);
    }
  }

  Future<bool> connect(String host, int port) async {
    try {
      _notifyListeners('🔌 Подключение к $host:$port...');
      _socket = await Socket.connect(host, port);
      _isConnected = true;
      _notifyListeners('✅ Подключено!');

      _socket!.listen(
            (List<int> data) {
          final message = utf8.decode(data).trim();
          _notifyListeners('📥 $message');
        },
        onDone: () {
          _notifyListeners('🔌 Соединение закрыто');
          _isConnected = false;
        },
        onError: (error) {
          _notifyListeners('❌ Ошибка: $error');
          _isConnected = false;
        },
      );

      return true;
    } catch (e) {
      _notifyListeners('❌ Ошибка подключения: $e');
      _isConnected = false;
      return false;
    }
  }

  void sendMessage(String message) {
    if (_socket == null || !_isConnected) {
      _notifyListeners('❌ Нет подключения к серверу');
      return;
    }

    _socket!.writeln(message);
    _notifyListeners('📤 Отправлено: "$message"');
  }

  Future<void> disconnect() async {
    if (_socket != null && _isConnected) {
      _socket!.writeln('exit');
      await Future.delayed(Duration(milliseconds: 500));
      await _socket!.close();
    }
    _socket = null;
    _isConnected = false;
    _notifyListeners('🔌 Отключено');
  }
}
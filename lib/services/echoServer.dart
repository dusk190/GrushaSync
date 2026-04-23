// import 'dart:io';
//
// void main() async {
//   const port = 8080;
//
//   try {
//     final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
//     print('Эхо сервер запущен на порту: $port');
//
//     await for (var client in server) {
//       print('Новое подключение: ${client.remoteAddress.address}');
//       handleClient(client);
//     }
//   } catch (e) {
//     print('Ошибка: $e');
//   }
// }
//
// void handleClient(Socket client) {
//   final clientAddr = client.remoteAddress.address;
//
//   client.writeln('Подключено к серверу!');
//   client.writeln('Отправьте сообщение');
//
//   client.listen(
//         (List<int> data) {
//       final message = String.fromCharCodes(data).trim();
//       print('[$clientAddr] Получено: "$message"');
//
//       if (message.toLowerCase() == 'exit' || message.toLowerCase() == 'quit') {
//         client.writeln('Goodbye!');
//         client.close();
//       } else {
//         client.writeln('Echo: $message');
//       }
//     },
//     onDone: () {
//       print('[$clientAddr] Отключено');
//       client.close();
//     },
//     onError: (error) {
//       print('[$clientAddr] Ошибка: $error');
//     },
//   );
// }
import 'dart:io';
import 'dart:convert';

class TcpServer {
  ServerSocket? _server;
  bool _isRunning = false;
  final List<void Function(String)> _messageCallbacks = [];

  bool get isRunning => _isRunning;

  void addMessageListener(void Function(String message) callback) {
    _messageCallbacks.add(callback);
  }

  void _notifyListeners(String message) {
    for (var callback in _messageCallbacks) {
      callback(message);
    }
  }

  Future<bool> start(int port) async {
    try {
      _server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
      _isRunning = true;
      _notifyListeners('✅ Сервер запущен на порту $port');

      _server!.listen((Socket client) {
        final clientAddr = client.remoteAddress.address;
        _notifyListeners('🔌 Подключение от $clientAddr');

        _handleClient(client);
      });

      return true;
    } catch (e) {
      _notifyListeners('❌ Ошибка запуска сервера: $e');
      return false;
    }
  }

  void _handleClient(Socket client) {
    final clientAddr = client.remoteAddress.address;

    client.writeln('🔊 Подключено к эхо-серверу!');
    client.writeln('💬 Отправьте сообщение');

    client.listen(
          (List<int> data) {
        final message = utf8.decode(data).trim();
        _notifyListeners('📨 [$clientAddr] Получено: "$message"');

        if (message.toLowerCase() == 'exit') {
          client.writeln('👋 До свидания!');
          client.close();
        } else {
          client.writeln('Эхо: $message');
        }
      },
      onDone: () {
        _notifyListeners('🔌 [$clientAddr] Отключено');
        client.close();
      },
      onError: (error) {
        _notifyListeners('⚠️ [$clientAddr] Ошибка: $error');
      },
    );
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
    _isRunning = false;
    _notifyListeners('🛑 Сервер остановлен');
  }
}
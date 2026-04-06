import 'dart:io';
import 'dart:convert';

Future<void> sendHello(String host, int port) async {
  try {
    final socket = await Socket.connect(host, port);
    socket.writeln('Hello');

    await for (var data in socket) {
      print('Ответ: ${utf8.decode(data).trim()}');
      socket.close();
      break;
    }
  } catch (e) {
    print('Ошибка: $e');
  }
}

void main() async {
  await sendHello('127.0.0.1', 8080);
}
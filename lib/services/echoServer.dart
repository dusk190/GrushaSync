import 'dart:io';

void main() async {
  const port = 8080;

  try {
    final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
    print('Эхо сервер запущен на порту: $port');

    await for (var client in server) {
      print('Новое подключение: ${client.remoteAddress.address}');
      handleClient(client);
    }
  } catch (e) {
    print('Ошибка: $e');
  }
}

void handleClient(Socket client) {
  final clientAddr = client.remoteAddress.address;

  client.writeln('Подключено к серверу!');
  client.writeln('Отправьте сообщение');

  client.listen(
        (List<int> data) {
      final message = String.fromCharCodes(data).trim();
      print('[$clientAddr] Получено: "$message"');

      if (message.toLowerCase() == 'exit' || message.toLowerCase() == 'quit') {
        client.writeln('Goodbye!');
        client.close();
      } else {
        client.writeln('Echo: $message');
      }
    },
    onDone: () {
      print('[$clientAddr] Отключено');
      client.close();
    },
    onError: (error) {
      print('[$clientAddr] Ошибка: $error');
    },
  );
}
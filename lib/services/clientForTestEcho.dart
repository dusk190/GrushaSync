import 'dart:io';

void main() async {
  const host = 'localhost';
  const port = 8080;

  print('Подключнеие к $host:$port');

  try {
    final socket = await Socket.connect(host, port);
    print('Подключено\n');

    // Слушаем ответы от сервера
    socket.listen(
          (data) {
        final message = String.fromCharCodes(data);
        print(message.trim());
      },
      onDone: () {
        print('\nСоединение закрыто');
        exit(0);
      },
      onError: (error) {
        print('Ошибка: $error');
      },
    );

    // Читаем ввод пользователя
    print('Введите сообщение (exit для выхода):');

    await for (var line in stdin) {
      final message = String.fromCharCodes(line).trim();

      if (message.toLowerCase() == 'exit' || message.toLowerCase() == 'quit') {
        print('Завершение');
        socket.close();
        break;
      }

      if (message.isNotEmpty) {
        socket.writeln(message);
      }
    }
  } catch (e) {
    print('Не удалось подключиться: $e');
    print('Проверьте, запущен ли сервер на порту $port');
  }
}
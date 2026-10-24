import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/shared_file.dart';
import 'network_utils.dart';

class FileServerService {
  HttpServer? _httpServer;
  bool _isRunning = false;

  final String filesPath;
  final String downloadPath;
  final List<SharedFile> Function() getSharedFiles;
  final VoidCallback onNotifyReceived;

  bool get isRunning => _isRunning;

  FileServerService({
    required this.filesPath,
    required this.downloadPath,
    required this.getSharedFiles,
    required this.onNotifyReceived,
  });

  Future<bool> start(int port) async {
    try {
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _isRunning = true;
      _handleIncomingRequests();
      if (kDebugMode) print('HTTP Сервер успешно запущен на порту $port');
      return true;
    } catch (e) {
      if (kDebugMode) print('Ошибка запуска HTTP сервера: $e');
      _isRunning = false;
      return false;
    }
  }

  void _handleIncomingRequests() {
    _httpServer?.listen((HttpRequest request) async {
      final path = request.uri.path;

      // GET /api/ping
      if (path == '/api/ping') {
        request.response
          ..statusCode = 200
          ..write('pong')
          ..close();
        return;
      }

      // GET /files - список файлов
      if (path == filesPath) {
        final response = _generateFileListJson();
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(response)
          ..close();
        return;
      }

      // GET /download/{fileId} - скачивание файла
      if (path.startsWith(downloadPath)) {
        final fileId = path.substring(downloadPath.length + 1);
        await _handleDownloadRequest(request, fileId);
        return;
      }

      // POST /api/notify - уведомление об обновлении файлов от пира
      if (request.uri.path == '/api/notify' && request.method == 'POST') {
        try {
          final body = await utf8.decoder.bind(request).join();
          final data = jsonDecode(body);
          final senderName = data['deviceName'] ?? 'Unknown';

          if (kDebugMode) {
            print('Получено уведомление об обновлении файлов от $senderName');
          }

          onNotifyReceived();

          request.response
            ..statusCode = 200
            ..write('OK')
            ..close();
        } catch (e) {
          request.response
            ..statusCode = 400
            ..write('Bad Request')
            ..close();
        }
        return;
      }

      // 404
      request.response
        ..statusCode = 404
        ..write('Not Found')
        ..close();
    });
  }

  String _generateFileListJson() {
    final sharedFiles = getSharedFiles();
    final files = sharedFiles.map((f) => {
      'id': f.id,
      'name': f.name,
      'size': f.size,
      'sizeFormatted': NetworkUtils.formatSize(f.size),
    }).toList();

    return jsonEncode({
      'deviceName': 'Моё устройство',
      'files': files,
    });
  }

  Future<void> _handleDownloadRequest(HttpRequest request, String encodedFileId) async {
    try {
      final fileId = Uri.decodeComponent(encodedFileId);
      final sharedFiles = getSharedFiles();

      final fileInfo = sharedFiles.firstWhere(
        (f) => f.id == fileId || f.name == fileId,
        orElse: () => throw Exception('File not found: $fileId'),
      );

      final file = File(fileInfo.path);

      if (!await file.exists()) {
        if (kDebugMode) print('Файл не найден на диске: ${fileInfo.path}');
        request.response
          ..statusCode = 404
          ..write('File not found')
          ..close();
        return;
      }

      final fileSize = await file.length();
      final encodedFilename = Uri.encodeComponent(fileInfo.name);

      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.binary
        ..headers.add('Content-Disposition', 'attachment; filename*=UTF-8\'\'$encodedFilename')
        ..headers.add('Content-Length', fileSize.toString());

      final stream = file.openRead();
      await request.response.addStream(stream);
      await request.response.close();

      if (kDebugMode) {
        print('Файл успешно отдан клиенту: ${fileInfo.name} (${NetworkUtils.formatSize(fileSize)})');
      }
    } catch (e) {
      if (kDebugMode) print('Ошибка отправки файла $encodedFileId: $e');
      try {
        request.response
          ..statusCode = 500
          ..write('Internal Server Error')
          ..close();
      } catch (_) {}
    }
  }

  Future<void> stop() async {
    await _httpServer?.close();
    _httpServer = null;
    _isRunning = false;
  }
}

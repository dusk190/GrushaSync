import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/peer_device.dart';
import '../models/peer_file.dart';
import 'network_utils.dart';
import 'log_service.dart';

class FileClientService {
  final Map<String, ValueNotifier<double>> downloadProgresses = {};
  final Map<String, bool> downloadingStates = {};

  bool isFileDownloading(String fileId) => downloadingStates[fileId] ?? false;

  ValueNotifier<double> getProgressNotifier(String fileId) {
    return downloadProgresses.putIfAbsent(fileId, () => ValueNotifier<double>(0.0));
  }

  /// Получение списка расшаренных файлов с удаленного устройства
  Future<List<PeerFile>> fetchPeerFiles(
    PeerDevice peer,
    String filesPath, {
    void Function(PeerDevice peer)? onPeerFailed,
  }) async {
    try {
      final url = Uri.http('${peer.host}:${peer.port}', filesPath);
      LogService.info('Client', 'Запрос списка файлов у "${peer.name}" (${peer.host}:${peer.port})');
      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = (data['files'] as List).map((f) => PeerFile(
          id: f['id']?.toString() ?? f['name'].toString(),
          name: f['name'],
          size: f['size'],
          sizeFormatted: f['sizeFormatted'] ?? NetworkUtils.formatSize(f['size'] ?? 0),
          peerId: peer.id,
          peerName: peer.name,
        )).toList();

        LogService.info('Client', 'Получен список файлов (${files.length} шт.) от "${peer.name}"');
        return files;
      }
    } catch (e) {
      LogService.error('Client', 'Ошибка получения списка файлов от "${peer.name}"', e);
      onPeerFailed?.call(peer);
    }
    return [];
  }

  /// Потоковое скачивание файла с пира
  Future<bool> downloadFile(
    PeerDevice peer,
    PeerFile file,
    String downloadPath,
    Function(double) onProgress, {
    void Function(PeerDevice peer)? onPeerFailed,
    VoidCallback? onStateChanged,
  }) async {
    try {
      final url = Uri.http('${peer.host}:${peer.port}', '$downloadPath/${file.id}');
      final request = http.Request('GET', url);
      LogService.info('Client', 'Отправлен запрос на скачивание "${file.name}" к $url');
      final response = await request.send().timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        LogService.error('Client', 'Сервер "${peer.name}" вернул статус HTTP ${response.statusCode} при скачивании "${file.name}"');
        return false;
      }

      final downloadDir = await NetworkUtils.getDownloadDirectory();
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      // Проверка прав записи
      final testFile = File('${downloadDir.path}/.test');
      try {
        await testFile.writeAsString('test');
        await testFile.delete();
      } catch (e) {
        LogService.error('Client', 'Нет прав на запись в папку загрузок "${downloadDir.path}"', e);
        return false;
      }

      // Разрешение дубликатов имен файлов (file_1.ext, file_2.ext)
      final originalPath = '${downloadDir.path}/${file.name}';
      String finalPath = originalPath;
      int counter = 1;
      while (await File(finalPath).exists()) {
        final ext = file.extension;
        final base = file.nameWithoutExtension;
        finalPath = '${downloadDir.path}/${base}_$counter$ext';
        counter++;
      }

      downloadingStates[file.id] = true;
      downloadingStates[file.name] = true;
      onStateChanged?.call();

      final outputFileFinal = File(finalPath);
      final sink = outputFileFinal.openWrite();

      int bytesReceived = 0;
      final contentLength = response.contentLength ?? file.size;
      int lastUpdateTime = 0;

      await for (var chunk in response.stream) {
        sink.add(chunk);
        bytesReceived += chunk.length;

        final currentTime = DateTime.now().millisecondsSinceEpoch;
        if (currentTime - lastUpdateTime > 100 || bytesReceived == contentLength) {
          onProgress(bytesReceived / (contentLength > 0 ? contentLength : 1));
          lastUpdateTime = currentTime;
        }
      }

      await sink.close();
      downloadingStates[file.id] = false;
      downloadingStates[file.name] = false;
      onStateChanged?.call();

      if (await outputFileFinal.exists()) {
        final fileSize = await outputFileFinal.length();
        LogService.info('Client', 'Успешно скачан файл: "${file.name}" (${NetworkUtils.formatSize(fileSize)}) в ${downloadDir.path}');
        return true;
      }
      LogService.error('Client', 'Файл не найден после записи на диск: $finalPath');
      return false;
    } catch (e) {
      downloadingStates[file.id] = false;
      downloadingStates[file.name] = false;
      onStateChanged?.call();
      LogService.error('Client', 'Ошибка скачивания "${file.name}" с "${peer.name}"', e);
      onPeerFailed?.call(peer);
      return false;
    }
  }

  /// Оповещение всех доступных пиров об обновлении списка файлов
  Future<void> notifyPeers(
    List<PeerDevice> peers,
    String myDeviceName, {
    void Function(PeerDevice peer)? onPeerFailed,
  }) async {
    if (peers.isEmpty) return;

    final notificationData = jsonEncode({
      'deviceName': myDeviceName,
      'timestamp': DateTime.now().toIso8601String(),
    });

    for (var peer in List<PeerDevice>.from(peers)) {
      try {
        final url = Uri.parse('http://${peer.host}:${peer.port}/api/notify');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: notificationData,
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          LogService.info('Client', 'Уведомление об обновлении отправлено на "${peer.name}"');
        }
      } catch (e) {
        LogService.warn('Client', 'Не удалось уведомить "${peer.name}" (оффлайн): $e');
        onPeerFailed?.call(peer);
      }
    }
  }
}

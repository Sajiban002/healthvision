// lib/services/pdf_saver/pdf_saver_mobile.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

Future<void> savePdfFile(String fileName, Uint8List fileBytes) async {
  Directory? directory;
  if (Platform.isAndroid) {
    directory = await getExternalStorageDirectory();
  } else {
    directory = await getApplicationDocumentsDirectory();
  }
  if (directory == null) {
    throw Exception('Не удалось получить директорию для сохранения');
  }
  final filePath = '${directory.path}/$fileName';
  final file = File(filePath);
  await file.writeAsBytes(fileBytes);
  
  await OpenFile.open(filePath);
}
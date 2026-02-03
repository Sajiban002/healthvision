// lib/services/pdf_saver/pdf_saver_web.dart
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

Future<void> savePdfFile(String fileName, Uint8List fileBytes) async {
  final blob = html.Blob([fileBytes], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
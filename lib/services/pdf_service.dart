import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:mobile_app/services/pdf_saver/pdf_saver_mobile.dart'
    if (dart.library.html) 'package:mobile_app/services/pdf_saver/pdf_saver_web.dart';

class PdfService {
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  static Future<void> _loadFonts() async {
    if (_regularFont != null && _boldFont != null) return;
    
    final boldFontAsset = 'assets/fonts/Roboto-Bold.ttf';

    final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldData = await rootBundle.load(boldFontAsset);
    
    _regularFont = pw.Font.ttf(regularData);
    _boldFont = pw.Font.ttf(boldData);
  }
  
  static Future<void> generateAndSaveReport({
    required String userName,
    required String summary,
    required String recommendations,
    required String fullReport,
    required DateTime date,
  }) async {
    try {
      await _loadFonts();
      if (_regularFont == null || _boldFont == null) {
        throw Exception('Не удалось загрузить шрифты для PDF');
      }

      final pdf = pw.Document();
      final dateFormat = DateFormat('dd.MM.yyyy', 'ru');
      final timeFormat = DateFormat('HH:mm', 'ru');
      final now = DateTime.now();
      final createdDate = dateFormat.format(now);
      final createdTime = timeFormat.format(now);
      final reportDate = dateFormat.format(date);

      final theme = pw.ThemeData.withFont(
        base: _regularFont!,
        bold: _boldFont!,
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: theme,
          build: (pw.Context context) {
            return [
              _buildHeader(),
              pw.SizedBox(height: 20),
              _buildUserInfo(userName, createdDate, createdTime, reportDate),
              pw.SizedBox(height: 30),
              _buildSectionCard(
                title: 'Оценка дня', 
                content: summary, 
                headerColor: PdfColor.fromHex('#1F2937'), 
                bgColor: PdfColor.fromHex('#F3F4F6')
              ),
              pw.SizedBox(height: 20),
              _buildSectionCard(
                title: 'Рекомендации', 
                content: recommendations, 
                headerColor: PdfColor.fromHex('#059669'), 
                bgColor: PdfColor.fromHex('#ECFDF5'), 
                borderColor: PdfColor.fromHex('#10B981')
              ),
              pw.SizedBox(height: 20),
              _buildDetailedReport(fullReport),
              pw.SizedBox(height: 30),
              _buildFooter(),
            ];
          },
        ),
      );

      final Uint8List fileBytes = await pdf.save();
      final fileName = 'health_report_${dateFormat.format(date).replaceAll('.', '_')}.pdf';
      
      await savePdfFile(fileName, fileBytes);
      
    } catch (e) {
      rethrow;
    }
  }


  static pw.Widget _buildHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#2E5BFF'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('HealthVision', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          pw.SizedBox(height: 8),
          pw.Text('AI Анализ здоровья за день', style: const pw.TextStyle(fontSize: 16, color: PdfColors.white)),
        ],
      ),
    );
  }

  static pw.Widget _buildUserInfo(String userName, String createdDate, String createdTime, String reportDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Пользователь: $userName', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Создан: $createdDate | $createdTime', style: const pw.TextStyle(fontSize: 12)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text('Дата анализа: $reportDate', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2E5BFF'))),
        ],
      ),
    );
  }

  static pw.Widget _buildSectionCard({
    required String title,
    required String content,
    required PdfColor headerColor,
    required PdfColor bgColor,
    PdfColor? borderColor,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: bgColor,
        border: borderColor != null ? pw.Border.all(color: borderColor) : null,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: headerColor)),
          pw.SizedBox(height: 12),
          pw.Text(content, style: const pw.TextStyle(fontSize: 12, height: 1.5), textAlign: pw.TextAlign.justify),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailedReport(String fullReport) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Детальный анализ', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1F2937'))),
        pw.SizedBox(height: 8),
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 8),
        pw.Text(fullReport, style: const pw.TextStyle(fontSize: 12, height: 1.5), textAlign: pw.TextAlign.justify),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#E5E7EB')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          pw.Text('Этот отчет сгенерирован автоматически на основе AI анализа', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 4),
          pw.Text('Для получения медицинской консультации обратитесь к врачу', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),
          pw.Text('HealthVision © 2025', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey), textAlign: pw.TextAlign.center),
        ],
      ),
    );
  }
}
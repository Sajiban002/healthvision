import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';

class AIService {
  static const String _apiKey = 'AIzaSyD8D3UGjw7vSBPAgLvHLeX_GHMd6oHYslE';

  static Future<Map<String, dynamic>> analyzeDailyHealth({
    required int waterIntake,
    required double sleepHours,
    required int steps,
    required String mood,
    required DateTime date,
  }) async {
    try {
      final apiKey = _apiKey;
      
      if (apiKey.isEmpty) {
        return _errorResponse(
          'Ошибка: API ключ не найден',
          'Ключ API не был предоставлен в коде.',
          date,
        );
      }

      GenerativeModel? model;
      String? lastError;

      final modelsToTry = [
        'gemini-2.0-flash-exp',
        'gemini-1.5-flash',
        'gemini-1.5-flash-latest',
        'models/gemini-2.0-flash-exp',
        'models/gemini-1.5-flash',
      ];

      for (String modelName in modelsToTry) {
        try {
          print('🔄 Попытка использовать модель: $modelName');
          model = GenerativeModel(model: modelName, apiKey: apiKey);
          
          final testResponse = await model.generateContent([
            Content.text('Test')
          ]).timeout(Duration(seconds: 5));
          
          if (testResponse.text != null) {
            print('✅ Модель $modelName работает!');
            break;
          }
        } catch (e) {
          lastError = e.toString();
          print('❌ Модель $modelName не работает: $e');
          model = null;
        }
      }

      if (model == null) {
        return _errorResponse(
          'Не удалось найти рабочую модель Gemini',
          'Попробованные модели: ${modelsToTry.join(", ")}',
          date,
          details: 'Последняя ошибка: $lastError',
        );
      }
    
      final dateFormat = DateFormat('d MMMM yyyy', 'ru_RU');
      final dateStr = dateFormat.format(date);
      final waterLiters = (waterIntake / 1000).toStringAsFixed(1);
      
      final prompt = '''
Ты — профессиональный аналитик здоровья. Проанализируй показатели пользователя за $dateStr.

Данные за день:
• Вода: $waterLiters л ($waterIntake мл)
• Сон: ${sleepHours.toStringAsFixed(1)} часов
• Шаги: $steps шагов
• Настроение: $mood

Создай короткий но содержательный анализ в следующем формате:

1. КРАТКАЯ ОЦЕНКА (1-2 предложения о результатах дня)
2. РЕКОМЕНДАЦИИ (3-4 конкретных совета для улучшения показателей)
3. ДЕТАЛЬНЫЙ АНАЛИЗ (подробный разбор каждого показателя с оценкой)

Раздели ответ на три части с маркерами:
[SUMMARY]...[/SUMMARY]
[RECOMMENDATIONS]...[/RECOMMENDATIONS]
[FULLREPORT]...[/FULLREPORT]

ВАЖНО: НЕ используй эмодзи в тексте ответа! Только обычный текст.

Будь конкретным, позитивным и мотивирующим.
Обязательно оцени:
- Достаточно ли воды (норма 2-2.5л)
- Качество сна (норма 7-9 часов)
- Уровень активности (норма 8000-10000 шагов)
''';

      try {
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text ?? "";
        
        if (text.isEmpty) {
          return _errorResponse(
            'AI вернул пустой ответ',
            'Попробуйте еще раз',
            date,
            details: 'Gemini API не вернул данные. Проверьте подключение к интернету.',
          );
        }

        return _parseResponse(text, dateStr);
        
      } catch (e, stackTrace) {
        print('❌ Ошибка генерации контента: $e');
        print('Stack trace: $stackTrace');
        
        return _errorResponse(
          'Произошла ошибка при анализе',
          'Попробуйте позже или проверьте подключение к интернету.',
          date,
          details: 'Ошибка: $e',
        );
      }
      
    } catch (e, stackTrace) {
      print('❌ Критическая ошибка: $e');
      print('Stack trace: $stackTrace');
      
      return _errorResponse(
        'Критическая ошибка',
        'Перезапустите приложение',
        date,
        details: 'Произошла критическая ошибка: $e',
      );
    }
  }

  static Map<String, dynamic> _errorResponse(
    String summary,
    String recommendations,
    DateTime date, {
    String? details,
  }) {
    final dateFormat = DateFormat('d MMMM yyyy', 'ru_RU');
    return {
      'summary': summary,
      'recommendations': recommendations,
      'fullReport': details ?? 'Подробности недоступны',
      'date': dateFormat.format(date),
      'status': 'error',
    };
  }

  static Map<String, dynamic> _parseResponse(String text, String dateStr) {
    var summaryMatch = RegExp(
      r'\[SUMMARY\](.*?)\[/SUMMARY\]',
      dotAll: true,
    ).firstMatch(text);
    
    var recommendationsMatch = RegExp(
      r'\[RECOMMENDATIONS\](.*?)\[/RECOMMENDATIONS\]',
      dotAll: true,
    ).firstMatch(text);
    
    var reportMatch = RegExp(
      r'\[FULLREPORT\](.*?)\[/FULLREPORT\]',
      dotAll: true,
    ).firstMatch(text);

    if (summaryMatch == null) {
      summaryMatch = RegExp(
        r'(?:КРАТКАЯ ОЦЕНКА|1\.|Краткая оценка)[\s:]*\n(.*?)(?=\n\s*(?:2\.|РЕКОМЕНДАЦИИ|Рекомендации)|$)',
        dotAll: true,
        caseSensitive: false,
      ).firstMatch(text);
    }
    
    if (recommendationsMatch == null) {
      recommendationsMatch = RegExp(
        r'(?:РЕКОМЕНДАЦИИ|2\.|Рекомендации)[\s:]*\n(.*?)(?=\n\s*(?:3\.|ДЕТАЛЬНЫЙ АНАЛИЗ|Детальный анализ)|$)',
        dotAll: true,
        caseSensitive: false,
      ).firstMatch(text);
    }
    
    if (reportMatch == null) {
      reportMatch = RegExp(
        r'(?:ДЕТАЛЬНЫЙ АНАЛИЗ|3\.|Детальный анализ)[\s:]*\n(.*?)$',
        dotAll: true,
        caseSensitive: false,
      ).firstMatch(text);
    }

    String summary = summaryMatch?.group(1)?.trim() ?? "";
    String recommendations = recommendationsMatch?.group(1)?.trim() ?? "";
    String fullReport = reportMatch?.group(1)?.trim() ?? "";

    if (summary.isEmpty && recommendations.isEmpty && fullReport.isEmpty) {
      final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
      if (lines.length >= 3) {
        final third = (lines.length / 3).ceil();
        summary = lines.sublist(0, third).join('\n');
        recommendations = lines.sublist(third, third * 2).join('\n');
        fullReport = lines.sublist(third * 2).join('\n');
      } else {
        summary = text.length > 150 ? text.substring(0, 150) : text;
        recommendations = "Продолжайте следить за своими показателями и стремитесь к улучшению.";
        fullReport = text;
      }
    }

    if (summary.isEmpty) {
      summary = text.length > 150 ? text.substring(0, 150) : text;
    }

    if (recommendations.isEmpty) {
      recommendations = "Продолжайте следить за своими показателями и стремитесь к улучшению каждый день.";
    }

    if (fullReport.isEmpty) {
      fullReport = text;
    }
    
    return {
      'summary': summary.isEmpty ? "Анализ завершен." : summary,
      'recommendations': recommendations.isEmpty ? "Следите за показателями." : recommendations,
      'fullReport': fullReport.isEmpty ? text : fullReport,
      'date': dateStr,
      'status': 'success',
    };
  }
}
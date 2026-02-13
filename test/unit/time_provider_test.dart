// test/unit/time_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/providers/time_provider.dart';

void main() {
  late TimeProvider provider;

  setUp(() {
    provider = TimeProvider();
  });
  test('currentDate при создании равен сегодняшней дате', () {
    final today = DateTime.now();
    expect(provider.currentDate.year, equals(today.year));
    expect(provider.currentDate.month, equals(today.month));
    expect(provider.currentDate.day, equals(today.day));
  });
  test('nextDay увеличивает дату ровно на 1 день', () {
    final before = provider.currentDate;
    provider.nextDay();
    expect(provider.currentDate.difference(before).inDays, equals(1));
  });
  test('goBack возвращает на предыдущую дату', () {
    final original = provider.currentDate;
    provider.nextDay();
    provider.goBack();
    expect(provider.currentDate.day, equals(original.day));
    expect(provider.currentDate.month, equals(original.month));
    expect(provider.currentDate.year, equals(original.year));
  });
  test('resetToToday сбрасывает дату и очищает историю', () {
    provider.nextDay();
    provider.nextDay();
    provider.resetToToday();
    final today = DateTime.now();
    expect(provider.currentDate.day, equals(today.day));
    expect(provider.canGoBack, isFalse);
  });
}
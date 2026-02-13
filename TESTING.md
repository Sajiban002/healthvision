# TESTING.md
# Project
HealthVision — мобильного трекера здоровья (вода, сон, шаги, настроение) на базе Firebase Firestore.

# Необходимые зависимости 
Зависимости уже добавлены в pubspec.yaml:
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.8
  fake_cloud_firestore: ^3.0.3

# Установить зависимости
flutter pub get

# Запустить все тесты с именем каждого
flutter test --reporter=expanded

Ожидаемый результат должен быть:
00:XX +14: All tests passed

## Структура файлов тестов

├── unit/
│   ├── time_provider_test.dart    
│   ├── health_data_test.dart       
│   └── health_provider_test.dart 
├── integration/
│   └── firestore_test.dart 
└── widget/
    └── widget_test.dart 

## Запустить по отдельности:
flutter test test/unit/

flutter test test/integration/

flutter test test/widget/

# Ожидаемый результат
00:XX +14: All tests passed



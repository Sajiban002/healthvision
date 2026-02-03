import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String get verificationServerUrl {
    if (kIsWeb) {
      return 'http://localhost:5000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    } else {
      return 'http://localhost:5000';
    }
  }

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<Map<String, dynamic>> registerWithEmail({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      print('🔵 AuthService: Создание пользователя в Firebase Auth...');
      
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Пользователь создан в Firebase Auth: ${userCredential.user?.uid}');

      await userCredential.user?.updateDisplayName(nickname);
      print('✅ Имя обновлено: $nickname');

      print('🔵 Создание профиля в Firestore...');
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'nickname': nickname,
        'createdAt': FieldValue.serverTimestamp(),
        'profileCompleted': false,
      });
      
      print('✅ Профиль создан в Firestore');

      return {
        'success': true,
        'user': userCredential.user,
        'message': 'Регистрация успешна'
      };
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      
      String message = 'Ошибка регистрации';
      
      switch (e.code) {
        case 'weak-password':
          message = 'Пароль слишком слабый';
          break;
        case 'email-already-in-use':
          message = 'Email уже используется';
          break;
        case 'invalid-email':
          message = 'Неверный формат email';
          break;
      }

      return {'success': false, 'message': message};
    } catch (e) {
      print('❌ Неизвестная ошибка регистрации: $e');
      return {'success': false, 'message': 'Неизвестная ошибка: $e'};
    }
  }

  Future<Map<String, dynamic>> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔵 AuthService: Вход пользователя...');
      
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Вход выполнен: ${userCredential.user?.uid}');

      return {
        'success': true,
        'user': userCredential.user,
        'message': 'Вход выполнен успешно'
      };
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      
      String message = 'Ошибка входа';
      
      switch (e.code) {
        case 'user-not-found':
          message = 'Пользователь не найден';
          break;
        case 'wrong-password':
          message = 'Неверный пароль';
          break;
        case 'invalid-email':
          message = 'Неверный формат email';
          break;
        case 'user-disabled':
          message = 'Аккаунт заблокирован';
          break;
      }

      return {'success': false, 'message': message};
    } catch (e) {
      print('❌ Неизвестная ошибка входа: $e');
      return {'success': false, 'message': 'Неизвестная ошибка: $e'};
    }
  }

  Future<Map<String, dynamic>> sendVerificationCode(String email) async {
    try {
      final String serverUrl = verificationServerUrl;
      print('🔵 AuthService: Отправка запроса на $serverUrl/api/send-verification-code');
      print('📧 Email: $email');
      
      final response = await http.post(
        Uri.parse('$serverUrl/api/send-verification-code'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email}),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('❌ Timeout: Сервер не отвечает более 30 секунд');
          throw TimeoutException('Сервер не отвечает');
        },
      );

      print('📡 Статус ответа: ${response.statusCode}');
      print('📡 Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success']) {
          print('✅ Код успешно отправлен на $email');
          return {
            'success': true,
            'message': data['message'] ?? 'Код отправлен на email',
            'expiresInMinutes': data['expires_in_minutes'] ?? 10
          };
        } else {
          print('❌ Сервер вернул success=false: ${data['error']}');
          return {
            'success': false,
            'message': data['error'] ?? 'Не удалось отправить код'
          };
        }
      } else {
        print('❌ HTTP ошибка: ${response.statusCode}');
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['error'] ?? 'Ошибка сервера (${response.statusCode})'
        };
      }
    } on SocketException catch (e) {
      print('❌ SocketException: $e');
      return {
        'success': false,
        'message': 'Не удалось подключиться к серверу.\nПроверьте:\n1. Запущен ли Python сервер\n2. Правильный ли URL: ${verificationServerUrl}'
      };
    } on TimeoutException catch (e) {
      print('❌ TimeoutException: $e');
      return {
        'success': false,
        'message': 'Превышено время ожидания.\nСервер не отвечает.'
      };
    } on FormatException catch (e) {
      print('❌ FormatException: $e');
      return {
        'success': false,
        'message': 'Неверный формат ответа от сервера'
      };
    } catch (e) {
      print('❌ Неизвестная ошибка отправки кода: $e');
      return {
        'success': false,
        'message': 'Ошибка подключения: $e'
      };
    }
  }

  Future<Map<String, dynamic>> verifyCode({
    required String email,
    required String code,
  }) async {
    try {
      final String serverUrl = verificationServerUrl;
      print('🔵 AuthService: Проверка кода для $email');
      
      final response = await http.post(
        Uri.parse('$serverUrl/api/verify-code'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'email': email,
          'code': code,
        }),
      ).timeout(const Duration(seconds: 10));

      print('📡 Статус ответа: ${response.statusCode}');
      
      final data = json.decode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        print('✅ Код подтвержден');
        
        if (currentUser != null) {
          await _firestore.collection('users').doc(currentUser!.uid).update({
            'emailVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          });
          print('✅ Статус верификации обновлен в Firestore');
        }
        
        return {'success': true, 'message': data['message']};
      } else {
        print('❌ Код неверный или истек');
        return {'success': false, 'message': data['error'] ?? 'Неверный код'};
      }
    } catch (e) {
      print('❌ Ошибка проверки кода: $e');
      return {'success': false, 'message': 'Ошибка проверки кода: $e'};
    }
  }

  Future<Map<String, dynamic>> completeProfile({
    required int age,
    required String gender,
    required String location,
    required int height,
    required double weight,
  }) async {
    try {
      if (currentUser == null) {
        return {'success': false, 'message': 'Пользователь не авторизован'};
      }

      print('🔵 AuthService: Завершение профиля для ${currentUser!.uid}');

      await _firestore.collection('users').doc(currentUser!.uid).update({
        'age': age,
        'gender': gender,
        'location': location,
        'height': height,
        'weight': weight,
        'profileCompleted': true,
        'profileCompletedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Профиль обновлен');

      await _firestore.collection('health_goals').doc(currentUser!.uid).set({
        'userId': currentUser!.uid,
        'dailyWaterGoal': 2000,
        'dailySleepGoal': 8.0,
        'dailyStepsGoal': 10000,
        'dailyCaloriesGoal': 2000,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Цели созданы');

      return {'success': true, 'message': 'Профиль успешно создан'};
    } catch (e) {
      print('❌ Ошибка завершения профиля: $e');
      return {'success': false, 'message': 'Ошибка создания профиля: $e'};
    }
  }

  Future<bool> isProfileComplete() async {
    if (currentUser == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      return doc.data()?['profileCompleted'] ?? false;
    } catch (e) {
      print('❌ Ошибка проверки профиля: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      return doc.data();
    } catch (e) {
      print('❌ Ошибка получения данных пользователя: $e');
      return null;
    }
  }

  Future<DateTime?> getRegistrationDate() async {
    if (currentUser == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      final data = doc.data();
      if (data != null && data['createdAt'] != null) {
        final timestamp = data['createdAt'] as Timestamp;
        return timestamp.toDate();
      }
      return null;
    } catch (e) {
      print('❌ Ошибка получения даты регистрации: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    print('✅ Пользователь вышел');
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Инструкция отправлена на email'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Ошибка отправки: $e'
      };
    }
  }

  Future<Map<String, dynamic>> testServerConnection() async {
    try {
      final String serverUrl = verificationServerUrl;
      print('🔵 Тестирование подключения к $serverUrl/api/health');
      
      final response = await http.get(
        Uri.parse('$serverUrl/api/health'),
      ).timeout(const Duration(seconds: 5));

      print('📡 Статус: ${response.statusCode}');
      print('📡 Ответ: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': 'Сервер работает',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': 'Сервер вернул код ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Ошибка подключения: $e');
      return {
        'success': false,
        'message': 'Не удалось подключиться: $e',
      };
    }
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}
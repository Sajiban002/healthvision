// test/integration/firestore_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mobile_app/models/health_data.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  const userId = 'test_user_123';
  final testDate = DateTime(2024, 6, 15);

  setUp(() {
    // Свежая пустая база перед каждым тестом
    fakeFirestore = FakeFirebaseFirestore();
  });
  test('сохранённая запись HealthData появляется в Firestore с правильными полями', () async {
    final data = HealthData(
      userId: userId,
      date: testDate,
      waterIntake: 1500,
      steps: 6000,
      mood: 'happy',
    );

    await fakeFirestore.collection('health_data').add(data.toMap());

    final snapshot = await fakeFirestore
        .collection('health_data')
        .where('userId', isEqualTo: userId)
        .get();

    expect(snapshot.docs.length, equals(1));
    expect(snapshot.docs.first.data()['waterIntake'], equals(1500));
    expect(snapshot.docs.first.data()['steps'], equals(6000));
    expect(snapshot.docs.first.data()['mood'], equals('happy'));
  });
  test('обновление записи меняет значения в документе', () async {
    final data = HealthData(userId: userId, date: testDate, waterIntake: 500, steps: 2000);
    final docRef = await fakeFirestore.collection('health_data').add(data.toMap());

    final updated = data.copyWith(waterIntake: 2000, steps: 8000);
    await docRef.update(updated.toMap());

    final doc = await docRef.get();
    expect(doc.data()?['waterIntake'], equals(2000));
    expect(doc.data()?['steps'], equals(8000));
  });
  test('данные разных пользователей не смешиваются', () async {
    await fakeFirestore.collection('health_data').add(
      HealthData(userId: 'user_A', date: testDate, waterIntake: 1000).toMap(),
    );
    await fakeFirestore.collection('health_data').add(
      HealthData(userId: 'user_B', date: testDate, waterIntake: 2000).toMap(),
    );

    final snapshot = await fakeFirestore
        .collection('health_data')
        .where('userId', isEqualTo: 'user_A')
        .get();

    expect(snapshot.docs.length, equals(1));
    expect(snapshot.docs.first.data()['waterIntake'], equals(1000));
  });

  test('цели пользователя сохраняются и читаются корректно', () async {
    final goals = HealthGoals(
      userId: userId,
      dailyWaterGoal: 3000,
      dailySleepGoal: 9.0,
      dailyStepsGoal: 15000,
    );

    await fakeFirestore
        .collection('health_goals')
        .doc(userId)
        .set(goals.toMap());

    final doc = await fakeFirestore
        .collection('health_goals')
        .doc(userId)
        .get();

    expect(doc.exists, isTrue);
    expect(doc.data()?['dailyWaterGoal'], equals(3000));
    expect(doc.data()?['dailySleepGoal'], equals(9.0));
    expect(doc.data()?['dailyStepsGoal'], equals(15000));
  });
}
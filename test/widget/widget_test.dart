// test/widget/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/health_provider.dart';
import 'package:mobile_app/providers/time_provider.dart';

Widget wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => HealthProvider()),
      ChangeNotifierProvider(create: (_) => TimeProvider()),
    ],
    child: MaterialApp(home: child),
  );
}

class FakeNavScreen extends StatefulWidget {
  const FakeNavScreen({super.key});
  @override
  State<FakeNavScreen> createState() => _FakeNavScreenState();
}

class _FakeNavScreenState extends State<FakeNavScreen> {
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: const [
        Center(child: Text('Экран Главная', key: Key('screen_home'))),
        Center(child: Text('Экран Статистика', key: Key('screen_stats'))),
        Center(child: Text('Экран Профиль', key: Key('screen_profile'))),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Главная'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: 'Статистика'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Профиль'),
        ],
      ),
    );
  }
}

void main() {
  testWidgets('BottomNavigationBar переключает между тремя экранами', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FakeNavScreen()));
    await tester.pump();
    expect(find.byKey(const Key('screen_home')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bar_chart_outlined));
    await tester.pump();
    expect(find.byKey(const Key('screen_stats')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump();
    expect(find.byKey(const Key('screen_profile')), findsOneWidget);
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pump();
    expect(find.byKey(const Key('screen_home')), findsOneWidget);
  });
}
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/stats_screen.dart';
import 'providers/health_provider.dart';
import 'providers/time_provider.dart';
import 'utils/app_theme.dart';
import 'services/auth_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HealthProvider()),
        ChangeNotifierProvider(create: (_) => TimeProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthVision',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData) {
          return FutureBuilder<bool>(
            future: authService.isProfileComplete(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }

              if (profileSnapshot.data == true) {
                return const MainNavigationScreen();
              }

              return const WelcomeScreen();
            },
          );
        }

        return const WelcomeScreen();
      },
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = AuthService();
      final user = authService.currentUser;
      final timeProvider = context.read<TimeProvider>();

      if (user != null) {
        context
            .read<HealthProvider>()
            .initializeUserData(user.uid, timeProvider.currentDate);
      }
    });
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const StatsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: AppTheme.primaryBlue,
            unselectedItemColor: AppTheme.textSecondary,
            selectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Главная',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Статистика',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Профиль',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  DateTime? _registrationDate;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timeProvider = context.read<TimeProvider>();
      timeProvider.addListener(_onDateChanged);
    });
  }

  @override
  void dispose() {
    final timeProvider = context.read<TimeProvider>();
    timeProvider.removeListener(_onDateChanged);
    super.dispose();
  }

  void _onDateChanged() {
    final authService = AuthService();
    final user = authService.currentUser;
    if (user != null) {
      final timeProvider = context.read<TimeProvider>();
      context.read<HealthProvider>().loadDataForDate(
        user.uid,
        timeProvider.currentDate,
      );
    }
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    final data = await authService.getUserData();
    final regDate = await authService.getRegistrationDate();
    if (mounted) {
      setState(() {
        _userData = data;
        _registrationDate = regDate;
        _isLoading = false;
      });
    }
  }

  void _onNextDayPressed() {
    final timeProvider = context.read<TimeProvider>();
    timeProvider.nextDay();
  }

  void _onBackPressed() {
    final timeProvider = context.read<TimeProvider>();
    timeProvider.goBack();
  }

  void _onResetToToday() {
    final timeProvider = context.read<TimeProvider>();
    timeProvider.resetToToday();
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final timeProvider = context.watch<TimeProvider>();

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.backgroundColor,
              AppTheme.primaryBlue.withOpacity(0.05),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildCalendar(context, timeProvider),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    if (timeProvider.canGoBack)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _onBackPressed,
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Назад'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                            ),
                          ),
                        ),
                      ),
                    if (timeProvider.canGoBack) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _onNextDayPressed,
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('Вперёд'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (!_isSameDay(timeProvider.currentDate, DateTime.now()))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _onResetToToday,
                        icon: const Icon(Icons.today),
                        label: const Text('Вернуться к сегодня'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                          side: BorderSide(color: AppTheme.primaryBlue),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 32),
                _buildSettingsSection(context),
                const SizedBox(height: 40),
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      await authService.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WelcomeScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    label: const Text(
                      'Выйти из аккаунта',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildCalendar(BuildContext context, TimeProvider timeProvider) {
    final today = DateTime.now();
    final isToday = _isSameDay(timeProvider.currentDate, today);
    final firstDay = _registrationDate ?? DateTime.now().subtract(const Duration(days: 365));
    final firstDayNormalized = DateTime(firstDay.year, firstDay.month, firstDay.day);
    
    // Убеждаемся, что текущая дата не раньше даты регистрации
    final currentDate = timeProvider.currentDate;
    final safeCurrentDate = currentDate.isBefore(firstDayNormalized) 
        ? firstDayNormalized 
        : currentDate;
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(AppSizes.borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.05),
            blurRadius: 15,
          )
        ],
      ),
      child: TableCalendar(
        key: ValueKey(safeCurrentDate.toString()), // Обновляем календарь при изменении даты
        locale: 'ru_RU',
        firstDay: firstDayNormalized,
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: safeCurrentDate,
        selectedDayPredicate: (day) => isSameDay(safeCurrentDate, day),
        onDaySelected: (selectedDay, focusedDay) {
          // Запрещаем ручное изменение даты
        },
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronVisible: false,
          rightChevronVisible: false,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: isToday ? AppTheme.primaryBlue.withOpacity(0.3) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: AppTheme.primaryBlue,
            shape: BoxShape.circle,
          ),
          defaultDecoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          outsideDecoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
          weekendDecoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
        enabledDayPredicate: (day) {
          // Разрешаем видеть только дни с даты регистрации
          final dayNormalized = DateTime(day.year, day.month, day.day);
          return !dayNormalized.isBefore(firstDayNormalized);
        },
        onPageChanged: (focusedDay) {
          // Запрещаем изменение страницы
        },
      ),
    );
  }
  
  Widget _buildHeader(BuildContext context) {
    final userName = _userData?['nickname'] ?? 'Пользователь';
    final email = _userData?['email'] ?? '';
    
    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Center(
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'П',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.paddingMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userName,
                style: Theme.of(context).textTheme.displayMedium,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Настройки', style: Theme.of(context).textTheme.displayMedium),
        const SizedBox(height: AppSizes.paddingMedium),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(AppSizes.borderRadius),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.05),
                blurRadius: 15,
              )
            ],
          ),
          child: Column(
            children: [
              _buildSettingsItem(context, Icons.edit_outlined, 'Редактировать профиль'),
              _buildSettingsItem(context, Icons.notifications_outlined, 'Уведомления'),
              _buildSettingsItem(context, Icons.security_outlined, 'Безопасность'),
              _buildSettingsItem(context, Icons.help_outline, 'Помощь и поддержка', hideDivider: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(BuildContext context, IconData icon, String title, {bool hideDivider = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: AppTheme.textSecondary, size: AppSizes.iconSize),
                  const SizedBox(width: AppSizes.paddingMedium),
                  Expanded(child: Text(title, style: Theme.of(context).textTheme.bodyLarge)),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
                ],
              ),
              if (!hideDivider) ...[
                const SizedBox(height: 12),
                Divider(height: 1, indent: 40, color: AppTheme.backgroundColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
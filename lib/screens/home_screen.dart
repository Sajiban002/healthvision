import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../utils/app_theme.dart';
import '../utils/health_evaluator.dart';
import '../providers/health_provider.dart';
import '../services/auth_service.dart';
import '../services/ai_service.dart';
import 'add_data_screen.dart';
import 'ai_report_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  
  Map<String, dynamic>? _userData;
  bool _isGeneratingAI = false;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authService = AuthService();
    final data = await authService.getUserData();
    if (mounted) {
      setState(() => _userData = data);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  // Проверяем есть ли данные за сегодня
  bool _hasTodayData(HealthProvider provider) {
    final data = provider.currentData;
    if (data == null) return false;
    return data.waterIntake > 0 || data.sleepHours > 0 || data.steps > 0;
  }

  Future<void> _generateAIAnalysis() async {
    if (!mounted) return;
    
    final provider = context.read<HealthProvider>();
    final data = provider.currentData;
    
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Нет данных для анализа')),
      );
      return;
    }

    // Проверяем есть ли хоть какие-то данные
    if (data.waterIntake == 0 && data.sleepHours == 0 && data.steps == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните данные перед анализом'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isGeneratingAI = true);

    try {
      // Получаем анализ для одного дня
      final analysis = await AIService.analyzeDailyHealth(
        waterIntake: data.waterIntake,
        sleepHours: data.sleepHours,
        steps: data.steps,
        mood: data.mood,
        date: data.date,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AiReportScreen(
              analysis: analysis,
              userName: _userData?['nickname'] ?? 'Пользователь',
              date: data.date,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка AI анализа: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingAI = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HealthProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.currentData == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (provider.currentData == null) {
          return const Scaffold(
            body: Center(
              child: Text('Нет данных для отображения'),
            ),
          );
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
              child: CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.paddingLarge),
                      child: Column(
                        children: [
                          _buildHealthScoreCard(),
                          const SizedBox(height: 24),
                          _buildTodayMetrics(),
                          const SizedBox(height: 24),
                          _buildAIAnalysisSection(provider),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(),
        );
      },
    );
  }

  Widget _buildAppBar() {
    final userName = _userData?['nickname'] ?? 'Пользователь';
    
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLarge, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Привет, $userName! 👋',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Как твоё здоровье сегодня?',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard() {
    return Consumer<HealthProvider>(
      builder: (context, provider, child) {
        final data = provider.currentData!;

        final evaluation = HealthEvaluator.evaluateDay(
          water: data.waterIntake,
          sleep: data.sleepHours,
          steps: data.steps,
        );

        return Container(
          height: 280,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _rotateController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: CirclesPainter(_rotateController.value),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Общий балл здоровья',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1 + (_pulseController.value * 0.05),
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${evaluation['score']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'из 100',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      evaluation['message'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTodayMetrics() {
    return Consumer<HealthProvider>(
      builder: (context, provider, child) {
        final data = provider.currentData!;

        final waterEval = HealthEvaluator.evaluateWater(data.waterIntake);
        final sleepEval = HealthEvaluator.evaluateSleep(data.sleepHours);
        final stepsEval = HealthEvaluator.evaluateSteps(data.steps);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Показатели за день',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildMetricCard(
              icon: Icons.water_drop,
              title: 'Вода',
              value: '${(data.waterIntake / 1000).toStringAsFixed(1)} л',
              message: waterEval['message'],
              color: Color(waterEval['color']),
              emoji: waterEval['icon'],
            ),
            const SizedBox(height: 12),
            _buildMetricCard(
              icon: Icons.bedtime,
              title: 'Сон',
              value: '${data.sleepHours.toStringAsFixed(1)} ч',
              message: sleepEval['message'],
              color: Color(sleepEval['color']),
              emoji: sleepEval['icon'],
            ),
            const SizedBox(height: 12),
            _buildMetricCard(
              icon: Icons.directions_walk,
              title: 'Шаги',
              value: '${data.steps} шагов',
              message: stepsEval['message'],
              color: Color(stepsEval['color']),
              emoji: stepsEval['icon'],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String message,
    required Color color,
    required String emoji,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisSection(HealthProvider provider) {
    final hasData = _hasTodayData(provider);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: hasData
            ? LinearGradient(
                colors: [
                  const Color(0xFF8B5CF6),
                  const Color(0xFFA78BFA),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: hasData ? null : Colors.grey[300],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasData ? const Color(0xFF8B5CF6) : Colors.grey)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasData
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey[400]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasData ? Icons.psychology : Icons.psychology_outlined,
                  color: hasData ? Colors.white : Colors.grey[600],
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Анализ дня',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: hasData ? Colors.white : Colors.grey[700],
                      ),
                    ),
                    Text(
                      hasData ? 'Готов к анализу' : 'Заполните данные',
                      style: TextStyle(
                        fontSize: 12,
                        color: hasData 
                            ? Colors.white.withOpacity(0.8)
                            : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasData
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey[400]?.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasData ? Icons.check : Icons.lock,
                      color: hasData ? Colors.white : Colors.grey[600],
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasData ? 'Активно' : 'Нет данных',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasData ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasData
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey[400]?.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: hasData ? Colors.white : Colors.grey[600],
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasData
                        ? 'Получите персональный AI анализ ваших показателей за сегодня с рекомендациями'
                        : 'Заполните данные за сегодня (вода, сон или шаги) для получения AI анализа',
                    style: TextStyle(
                      fontSize: 13,
                      color: hasData
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_isGeneratingAI || !hasData) ? null : _generateAIAnalysis,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasData ? Colors.white : Colors.grey[400],
                foregroundColor: hasData
                    ? const Color(0xFF8B5CF6)
                    : Colors.grey[600],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[600],
              ),
              icon: _isGeneratingAI
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF8B5CF6)),
                      ),
                    )
                  : Icon(
                      hasData ? Icons.rocket_launch : Icons.lock,
                      color: hasData
                          ? const Color(0xFF8B5CF6)
                          : Colors.grey[600],
                    ),
              label: Text(
                _isGeneratingAI
                    ? 'Анализируем...'
                    : hasData
                        ? 'Получить анализ'
                        : 'Нет данных',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + (_pulseController.value * 0.1),
          child: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddDataScreen(),
                ),
              );
            },
            backgroundColor: AppTheme.primaryBlue,
            icon: const Icon(Icons.add),
            label: const Text('Добавить данные'),
          ),
        );
      },
    );
  }
}

class CirclesPainter extends CustomPainter {
  final double animation;

  CirclesPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    
    for (int i = 0; i < 3; i++) {
      final radius = 40.0 + (i * 30);
      final offset = math.pi * 2 * animation + (i * math.pi / 3);
      
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(offset);
      canvas.drawCircle(Offset.zero, radius, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(CirclesPainter oldDelegate) => true;
}
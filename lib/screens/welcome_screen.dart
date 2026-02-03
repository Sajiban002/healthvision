// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';
import 'dart:math' as math;

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late AnimationController _waterDropController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    
    _cloudController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    )..repeat();
    
    _waterDropController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _fadeController = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _waterDropController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryBlue,
              AppTheme.lightBlue,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Анимированные облака
              AnimatedBuilder(
                animation: _cloudController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: CloudsPainter(_cloudController.value),
                  );
                },
              ),
              
              // Анимированные капли воды
              AnimatedBuilder(
                animation: _waterDropController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: WaterDropsPainter(_waterDropController.value),
                  );
                },
              ),
              
              // Основной контент
              FadeTransition(
                opacity: _fadeController,
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    
                    // Логотип с каплей
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(seconds: 1),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryBlue.withOpacity(0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.water_drop,
                              size: 70,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Название приложения
                    const Text(
                      'HealthVision',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    Text(
                      'Заботься о себе каждый день 💧',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    // Карточка с описанием
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 30),
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildFeatureItem(
                            icon: Icons.water_drop,
                            title: 'Отслеживай воду',
                            description: 'Следи за гидратацией организма',
                            color: const Color(0xFF3B82F6),
                          ),
                          const SizedBox(height: 20),
                          _buildFeatureItem(
                            icon: Icons.bedtime,
                            title: 'Контролируй сон',
                            description: 'Анализируй качество отдыха',
                            color: const Color(0xFF8B5CF6),
                          ),
                          const SizedBox(height: 20),
                          _buildFeatureItem(
                            icon: Icons.directions_walk,
                            title: 'Считай шаги',
                            description: 'Будь активным каждый день',
                            color: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Кнопка "Начать"
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 8,
                          shadowColor: AppTheme.primaryBlue.withOpacity(0.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Начать',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward, size: 24),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Painter для облаков
class CloudsPainter extends CustomPainter {
  final double animation;

  CloudsPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Рисуем плавающие облака
    _drawCloud(canvas, size, paint, 0.2, 0.1, animation);
    _drawCloud(canvas, size, paint, 0.7, 0.15, animation * 0.8);
    _drawCloud(canvas, size, paint, 0.4, 0.25, animation * 1.2);
  }

  void _drawCloud(Canvas canvas, Size size, Paint paint, double xRatio, double yRatio, double anim) {
    final x = size.width * xRatio + math.sin(anim * math.pi * 2) * 30;
    final y = size.height * yRatio;
    
    canvas.drawCircle(Offset(x, y), 25, paint);
    canvas.drawCircle(Offset(x + 20, y - 5), 30, paint);
    canvas.drawCircle(Offset(x + 40, y), 25, paint);
  }

  @override
  bool shouldRepaint(CloudsPainter oldDelegate) => true;
}

// Painter для капель воды
class WaterDropsPainter extends CustomPainter {
  final double animation;

  WaterDropsPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Рисуем падающие капли
    for (int i = 0; i < 8; i++) {
      final x = size.width * (0.1 + i * 0.12);
      final y = (size.height * 0.3) + (animation + i * 0.2) % 1.0 * (size.height * 0.4);
      
      final path = Path();
      path.moveTo(x, y);
      path.quadraticBezierTo(x - 5, y + 10, x, y + 15);
      path.quadraticBezierTo(x + 5, y + 10, x, y);
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(WaterDropsPainter oldDelegate) => true;
}
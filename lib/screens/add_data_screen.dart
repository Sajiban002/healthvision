import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/health_provider.dart';
import '../providers/time_provider.dart';
import '../services/auth_service.dart';

class AddDataScreen extends StatefulWidget {
  const AddDataScreen({super.key});

  @override
  State<AddDataScreen> createState() => _AddDataScreenState();
}

class _AddDataScreenState extends State<AddDataScreen> {
  final _waterController = TextEditingController();
  final _sleepController = TextEditingController();
  final _stepsController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentData();
    });
  }

  void _loadCurrentData() {
    final provider = context.read<HealthProvider>();
    final data = provider.currentData;
    
    if (data != null) {
      if (data.waterIntake > 0) {
        _waterController.text = (data.waterIntake / 1000).toStringAsFixed(1);
      }
      if (data.sleepHours > 0) {
        _sleepController.text = data.sleepHours.toStringAsFixed(1);
      }
      if (data.steps > 0) {
        _stepsController.text = data.steps.toString();
      }
    }
  }

  @override
  void dispose() {
    _waterController.dispose();
    _sleepController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _saveData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final authService = AuthService();
    final userId = authService.currentUser?.uid;

    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final timeProvider = context.read<TimeProvider>();
    final provider = context.read<HealthProvider>();
    final currentDate = timeProvider.currentDate;

    final waterLiters = double.tryParse(_waterController.text) ?? 0.0;
    final waterMl = (waterLiters * 1000).toInt();
    
    final sleepHours = double.tryParse(_sleepController.text) ?? 0.0;
    
    final steps = int.tryParse(_stepsController.text) ?? 0;

    await provider.saveAllData(
      userId: userId,
      date: currentDate,
      waterIntake: waterMl,
      sleepHours: sleepHours,
      steps: steps,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Данные сохранены! 🎉'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Добавить данные',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.paddingLarge),
                  child: Column(
                    children: [
                      _buildInputCard(
                        icon: Icons.water_drop,
                        color: const Color(0xFF3B82F6),
                        title: 'Вода',
                        subtitle: 'Сколько литров выпили сегодня?',
                        controller: _waterController,
                        suffix: 'л',
                        hint: '0.0',
                        isDecimal: true,
                        emoji: '💧',
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildInputCard(
                        icon: Icons.bedtime,
                        color: const Color(0xFF8B5CF6),
                        title: 'Сон',
                        subtitle: 'Сколько часов спали?',
                        controller: _sleepController,
                        suffix: 'ч',
                        hint: '0.0',
                        isDecimal: true,
                        emoji: '😴',
                      ),
                      
                      const SizedBox(height: 20),
                      
                      _buildInputCard(
                        icon: Icons.directions_walk,
                        color: const Color(0xFF10B981),
                        title: 'Шаги',
                        subtitle: 'Сколько шагов прошли?',
                        controller: _stepsController,
                        suffix: 'шагов',
                        hint: '0',
                        emoji: '👟',
                      ),
                      
                      const SizedBox(height: 40),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.accentBlue.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: AppTheme.primaryBlue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Рекомендации',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTip('💧', 'Вода: 2-3 литра в день идеально'),
                            _buildTip('😴', 'Сон: 7-9 часов для взрослых'),
                            _buildTip('👟', 'Шаги: минимум 10,000 в день'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(AppSizes.paddingLarge),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      shadowColor: AppTheme.primaryBlue.withOpacity(0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check, size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Сохранить',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String suffix,
    required String hint,
    required String emoji,
    bool isDecimal = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(emoji, style: const TextStyle(fontSize: 20)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
            inputFormatters: [
              if (isDecimal)
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}'))
              else
                FilteringTextInputFormatter.digitsOnly,
            ],
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.3),
              ),
              suffixText: suffix,
              suffixStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.7),
              ),
              border: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
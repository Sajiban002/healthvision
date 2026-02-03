import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../providers/health_provider.dart';
import '../providers/time_provider.dart';
import '../services/auth_service.dart';
import '../models/health_data.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<HealthData> _weekData = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timeProvider = context.read<TimeProvider>();
      timeProvider.addListener(_onDateChanged);
      
      final healthProvider = context.read<HealthProvider>();
      healthProvider.addListener(_onDataChanged);
    });
  }

  @override
  void dispose() {
    try {
      final timeProvider = context.read<TimeProvider>();
      timeProvider.removeListener(_onDateChanged);
      
      final healthProvider = context.read<HealthProvider>();
      healthProvider.removeListener(_onDataChanged);
    } catch (_) {}
    
    _tabController.dispose();
    super.dispose();
  }

  void _onDateChanged() {
    _loadData();
  }

  void _onDataChanged() {
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final authService = AuthService();
    final userId = authService.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final timeProvider = context.read<TimeProvider>();
    final healthProvider = context.read<HealthProvider>();
    final weekStart = timeProvider.weekStart;
    
    if (weekStart != null) {
      final rawData = await healthProvider.getWeekData(userId, weekStart);
      final processedData = _processWeekData(rawData);

      if (mounted) {
        setState(() {
          _weekData = processedData; 
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<HealthData> _processWeekData(List<HealthData> rawData) {
    if (rawData.isEmpty) return [];

    final Map<DateTime, HealthData> uniqueDataMap = {};

    for (final dataPoint in rawData) {
      final dateKey = DateTime(dataPoint.date.year, dataPoint.date.month, dataPoint.date.day);
      uniqueDataMap[dateKey] = dataPoint;
    }

    final processedList = uniqueDataMap.values.toList();
    processedList.sort((a, b) => a.date.compareTo(b.date));
    
    return processedList;
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
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStepsTab(),
                    _buildWaterTab(),
                    _buildSleepTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: Row(
        children: [
          Text(
            'Статистика',
            style: Theme.of(context).textTheme.displayMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.directions_walk), text: 'Шаги'),
            Tab(icon: Icon(Icons.water_drop), text: 'Вода'),
            Tab(icon: Icon(Icons.bedtime), text: 'Сон'),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_weekData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_walk, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Нет данных за неделю', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    final totalSteps = _weekData.map((d) => d.steps).fold(0, (a, b) => a + b);
    final avgSteps = _weekData.isNotEmpty ? (totalSteps / _weekData.length).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            title: 'Шаги за неделю',
            value: NumberFormat.decimalPattern('ru').format(totalSteps),
            subtitle: 'Среднее: ${NumberFormat.decimalPattern('ru').format(avgSteps)}/день',
            icon: Icons.directions_walk,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 24),
          _buildLineChart(
            title: 'График шагов',
            data: _getStepsData(),
            color: const Color(0xFF10B981),
            unit: 'шагов',
          ),
          const SizedBox(height: 24),
          _buildBarChart(
            title: 'Сравнение по дням',
            data: _getStepsBarData(),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_weekData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Нет данных за неделю', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    final totalWater = _weekData.map((d) => d.waterIntake).fold(0, (a, b) => a + b);
    final avgWater = _weekData.isNotEmpty ? (totalWater / _weekData.length).round() : 0;
    
    final totalWaterLiters = (totalWater / 1000).toStringAsFixed(1);
    final avgWaterLiters = (avgWater / 1000).toStringAsFixed(1);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            title: 'Вода за неделю',
            value: '$totalWaterLiters л',
            subtitle: 'Среднее: $avgWaterLiters л/день',
            icon: Icons.water_drop,
            color: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 24),
          _buildLineChart(
            title: 'График потребления воды',
            data: _getWaterData(),
            color: const Color(0xFF3B82F6),
            unit: 'л',
          ),
          const SizedBox(height: 24),
          _buildProgressRing(
            title: 'Достижение цели',
            progress: _calculateWaterProgress(),
            value: '${(_calculateWaterProgress() * 100).round()}%',
            color: const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }

  double _calculateWaterProgress() {
    if (_weekData.isEmpty) return 0.0;
    final goals = context.read<HealthProvider>().currentGoals;
    if (goals == null || goals.dailyWaterGoal == 0) return 0.0;
    final avgWater = _weekData.map((d) => d.waterIntake).fold(0, (a, b) => a + b) / _weekData.length;
    return (avgWater / goals.dailyWaterGoal).clamp(0.0, 1.0);
  }

  Widget _buildSleepTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_weekData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bedtime, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Нет данных за неделю', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    final totalSleep = _weekData.map((d) => d.sleepHours).fold(0.0, (a, b) => a + b);
    final avgSleep = _weekData.isNotEmpty ? totalSleep / _weekData.length : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(
            title: 'Сон за неделю',
            value: '${totalSleep.toStringAsFixed(1)} ч',
            subtitle: 'Среднее: ${avgSleep.toStringAsFixed(1)} ч/день',
            icon: Icons.bedtime,
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 24),
          _buildLineChart(
            title: 'Качество сна',
            data: _getSleepData(),
            color: const Color(0xFF8B5CF6),
            unit: 'ч',
          ),
          const SizedBox(height: 24),
          _buildSleepQualityCard(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(DateTime date) {
    final dayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final dayName = dayNames[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$dayName\n$day.$month';
  }

  Widget _buildLineChart({
    required String title,
    required List<FlSpot> data,
    required Color color,
    String unit = '',
  }) {
    if (data.isEmpty) return const SizedBox.shrink();

    final sortedData = List<HealthData>.from(_weekData);
    sortedData.sort((a, b) => a.date.compareTo(b.date));

    final maxValue = data.fold(0.0, (max, spot) => spot.y > max ? spot.y : max);
    final calculatedMaxY = maxValue > 0 ? maxValue * 1.2 : 10.0;
    final horizontalInterval = calculatedMaxY > 0 ? calculatedMaxY / 5 : 2.0;

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                maxY: calculatedMaxY,
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: horizontalInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedData.length) {
                          return const SizedBox.shrink();
                        }
                        final label = _getDayLabel(sortedData[index].date);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 9,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      interval: horizontalInterval,
                      getTitlesWidget: (value, meta) {
                        String label;
                        if (unit == 'л' || unit == 'ч') {
                          label = value.toStringAsFixed(1);
                        } else {
                          label = value.toInt().toString();
                        }
                        return Text(
                          label,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: color,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart({
    required String title,
    required List<BarChartGroupData> data,
  }) {
    if (data.isEmpty) return const SizedBox.shrink();

    final sortedData = List<HealthData>.from(_weekData);
    sortedData.sort((a, b) => a.date.compareTo(b.date));

    final maxValue = data.fold(0.0, (max, group) => group.barRods.first.toY > max ? group.barRods.first.toY : max);
    final calculatedMaxY = maxValue > 0 ? maxValue * 1.2 : 10.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: calculatedMaxY,
                minY: 0,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= sortedData.length) {
                          return const SizedBox.shrink();
                        }
                        final label = _getDayLabel(sortedData[index].date);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 9,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: data,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRing({
    required String title,
    required double progress,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: color.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                Center(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Отличный результат! Продолжай в том же духе.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepQualityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Анализ качества сна',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          _buildQualityItem('Глубокий сон', 0.35, const Color(0xFF8B5CF6)),
          const SizedBox(height: 12),
          _buildQualityItem('Легкий сон', 0.50, const Color(0xFFA78BFA)),
          const SizedBox(height: 12),
          _buildQualityItem('REM-сон', 0.15, const Color(0xFFC4B5FD)),
        ],
      ),
    );
  }

  Widget _buildQualityItem(String label, double value, Color color) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 12,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '${(value * 100).toInt()}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<FlSpot> _getStepsData() {
    if (_weekData.isEmpty) return [];
    
    final sortedData = List<HealthData>.from(_weekData);
    sortedData.sort((a, b) => a.date.compareTo(b.date));
    
    return List.generate(sortedData.length, (index) {
      return FlSpot(index.toDouble(), sortedData[index].steps.toDouble());
    });
  }

  List<FlSpot> _getWaterData() {
    if (_weekData.isEmpty) return [];
    
    final sortedData = List<HealthData>.from(_weekData);
    sortedData.sort((a, b) => a.date.compareTo(b.date));
    
    return List.generate(sortedData.length, (index) {
      final waterLiters = sortedData[index].waterIntake / 1000;
      return FlSpot(index.toDouble(), waterLiters);
    });
  }

  List<FlSpot> _getSleepData() {
    if (_weekData.isEmpty) return [];
    
    final sortedData = List<HealthData>.from(_weekData);
    sortedData.sort((a, b) => a.date.compareTo(b.date));
    
    return List.generate(sortedData.length, (index) {
      return FlSpot(index.toDouble(), sortedData[index].sleepHours);
    });
  }

  List<BarChartGroupData> _getStepsBarData() {
    if (_weekData.isEmpty) return [];
    
    final sortedData = List<HealthData>.from(_weekData);
    sortedData.sort((a, b) => a.date.compareTo(b.date));
    
    return List.generate(sortedData.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: sortedData[index].steps.toDouble(),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981),
                const Color(0xFF10B981).withOpacity(0.7),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ],
      );
    });
  }
}
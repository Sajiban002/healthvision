// lib/utils/health_evaluator.dart
import 'dart:math';

class HealthEvaluator {
  static final _random = Random();

  static Map<String, dynamic> evaluateWater(int milliliters) {
    final liters = milliliters / 1000;
    
    if (liters >= 10) {
      return {
        'status': 'critical',
        'color': 0xFFEF4444,
        'icon': '🚨',
        'message': _getRandomMessage(_criticalWaterMessages),
      };
    } else if (liters >= 5) {
      return {
        'status': 'warning_high',
        'color': 0xFFF97316,
        'icon': '⚠️',
        'message': _getRandomMessage(_tooMuchWaterMessages),
      };
    } else if (liters >= 3 && liters < 5) {
      return {
        'status': 'excellent',
        'color': 0xFF10B981,
        'icon': '🏆',
        'message': _getRandomMessage(_perfectWaterMessages),
      };
    } else if (liters >= 2 && liters < 3) {
      return {
        'status': 'good',
        'color': 0xFF3B82F6,
        'icon': '👍',
        'message': _getRandomMessage(_goodWaterMessages),
      };
    } else if (liters >= 1 && liters < 2) {
      return {
        'status': 'low',
        'color': 0xFFF59E0B,
        'icon': '💧',
        'message': _getRandomMessage(_lowWaterMessages),
      };
    } else {
      return {
        'status': 'critical_low',
        'color': 0xFFEF4444,
        'icon': '🚱',
        'message': _getRandomMessage(_criticalLowWaterMessages),
      };
    }
  }

  static Map<String, dynamic> evaluateSleep(double hours) {
    if (hours >= 12) {
      return {
        'status': 'warning_high',
        'color': 0xFFF97316,
        'icon': '😴',
        'message': _getRandomMessage(_tooMuchSleepMessages),
      };
    } else if (hours >= 7 && hours < 9) {
      return {
        'status': 'excellent',
        'color': 0xFF10B981,
        'icon': '✨',
        'message': _getRandomMessage(_perfectSleepMessages),
      };
    } else if (hours >= 6 && hours < 7) {
      return {
        'status': 'good',
        'color': 0xFF3B82F6,
        'icon': '😊',
        'message': _getRandomMessage(_goodSleepMessages),
      };
    } else if (hours >= 5 && hours < 6) {
      return {
        'status': 'low',
        'color': 0xFFF59E0B,
        'icon': '😪',
        'message': _getRandomMessage(_lowSleepMessages),
      };
    } else if (hours < 5) {
      return {
        'status': 'critical_low',
        'color': 0xFFEF4444,
        'icon': '🥱',
        'message': _getRandomMessage(_criticalLowSleepMessages),
      };
    } else {
      return {
        'status': 'high',
        'color': 0xFF8B5CF6,
        'icon': '😌',
        'message': _getRandomMessage(_highSleepMessages),
      };
    }
  }


  static Map<String, dynamic> evaluateSteps(int steps) {
    if (steps >= 30000) {
      return {
        'status': 'warning_high',
        'color': 0xFFF97316,
        'icon': '🏃‍♂️',
        'message': _getRandomMessage(_extremeStepsMessages),
      };
    } else if (steps >= 15000) {
      return {
        'status': 'excellent',
        'color': 0xFF10B981,
        'icon': '🔥',
        'message': _getRandomMessage(_veryHighStepsMessages),
      };
    } else if (steps >= 10000) {
      return {
        'status': 'excellent',
        'color': 0xFF10B981,
        'icon': '🎯',
        'message': _getRandomMessage(_perfectStepsMessages),
      };
    } else if (steps >= 7000) {
      return {
        'status': 'good',
        'color': 0xFF3B82F6,
        'icon': '👟',
        'message': _getRandomMessage(_goodStepsMessages),
      };
    } else if (steps >= 3000) {
      return {
        'status': 'low',
        'color': 0xFFF59E0B,
        'icon': '🚶',
        'message': _getRandomMessage(_lowStepsMessages),
      };
    } else {
      return {
        'status': 'critical_low',
        'color': 0xFFEF4444,
        'icon': '🛋️',
        'message': _getRandomMessage(_criticalLowStepsMessages),
      };
    }
  }


  static String _getRandomMessage(List<String> messages) {
    return messages[_random.nextInt(messages.length)];
  }


  static const List<String> _criticalWaterMessages = [
    'Стоп! Это опасно для здоровья! Немедленно обратитесь к врачу!',
    'Водная интоксикация - реальная угроза! Срочно к доктору!',
    'Такой объем жидкости может быть смертельно опасен! Вызывайте скорую!',
  ];

  static const List<String> _tooMuchWaterMessages = [
    'Это многовато! Рекомендуем проконсультироваться с врачом.',
    'Перебор с водой тоже вреден. Не переусердствуйте!',
    'Столько воды может навредить почкам. Будьте осторожнее!',
  ];

  static const List<String> _perfectWaterMessages = [
    'Идеальная гидратация! Ты - водный чемпион! 🏆',
    'Организм говорит спасибо! Так держать!',
    'Баланс воды на максимуме! Продолжай в том же духе!',
    'Твои почки танцуют от радости! Отличная работа!',
  ];

  static const List<String> _goodWaterMessages = [
    'Неплохо! Но можно еще немного добавить.',
    'Хороший результат! Чуть-чуть до идеала.',
    'Организм доволен, но можно и получше!',
  ];

  static const List<String> _lowWaterMessages = [
    'Маловато будет! Допей еще литр для баланса.',
    'Твой организм просит воды! Не игнорируй его.',
    'Пей больше! Кожа и почки скажут спасибо.',
    'Это же не пустыня! Выпей еще воды! 💧',
  ];

  static const List<String> _criticalLowWaterMessages = [
    'Срочно пей воду! Это критически мало!',
    'Обезвоживание - не шутка! Попей немедленно!',
    'Твой организм в шоке от жажды! Пей СЕЙЧАС!',
    'Ты превращаешься в изюм! Срочно к воде! 🚱',
  ];


  static const List<String> _tooMuchSleepMessages = [
    'Не превращайся в соню! Это многовато для здоровья.',
    'Слишком много сна вредит. Проверься у врача!',
    'Может быть, пора активнее жить? Столько спать не нормально.',
  ];

  static const List<String> _perfectSleepMessages = [
    'Идеальный сон! Ты высыпаешься как младенец! ✨',
    'Золотой стандарт сна! Так держать!',
    'Твой организм полностью восстановлен! Молодец!',
    'Сон чемпиона! Продолжай в том же духе!',
  ];

  static const List<String> _goodSleepMessages = [
    'Неплохо спишь! Но лучше добавить часик.',
    'Хороший результат, но можно и получше!',
    'Почти идеально! Еще чуть-чуть и будет супер.',
  ];

  static const List<String> _lowSleepMessages = [
    'Маловато спишь! Организм не успевает восстанавливаться.',
    'Добавь час сна - и будет отлично!',
    'Недосып накапливается! Спи больше.',
  ];

  static const List<String> _criticalLowSleepMessages = [
    'Это опасно мало! Срочно спать!',
    'Ты превращаешься в зомби! Высыпайся!',
    'Такой недосып приведет к проблемам! Спи больше!',
    'SOS! Твой мозг требует сна! 🥱',
  ];

  static const List<String> _highSleepMessages = [
    'Отлично выспался! Чуть многовато, но ничего страшного.',
    'Хороший отдых! Организм доволен.',
    'Качественный сон! Молодец!',
  ];


  static const List<String> _extremeStepsMessages = [
    'Ты что, марафон бежал? Не переутомляйся!',
    'Впечатляюще! Но не забывай об отдыхе!',
    'Столько шагов - это почти подвиг! Дай ногам отдохнуть.',
  ];

  static const List<String> _veryHighStepsMessages = [
    'Огонь! Ты настоящая машина для ходьбы! 🔥',
    'Невероятный результат! Так держать!',
    'Чемпионский уровень активности!',
    'Ты просто ходячая легенда!',
  ];

  static const List<String> _perfectStepsMessages = [
    'Идеальная активность! Цель достигнута! 🎯',
    '10 тысяч - золотой стандарт! Молодец!',
    'Отличная физическая форма! Продолжай!',
    'Твое сердце тебе благодарно!',
  ];

  static const List<String> _goodStepsMessages = [
    'Хороший результат! Еще немного до цели!',
    'Неплохая активность! Можешь чуть больше.',
    'Ты на правильном пути! Продолжай двигаться!',
  ];

  static const List<String> _lowStepsMessages = [
    'Маловато движения! Прогуляйся еще.',
    'Вставай с дивана чаще! Твое тело просит движения.',
    'Немного лени? Добавь активности!',
    'Ноги забыли, что такое ходьба? 🚶',
  ];

  static const List<String> _criticalLowStepsMessages = [
    'Ты вообще сегодня ходил? Срочно на прогулку!',
    'Диван - не лучший друг! Двигайся больше!',
    'Это катастрофически мало! Вставай и иди!',
    'Ты превращаешься в растение! Пора двигаться! 🛋️',
  ];


  static Map<String, dynamic> evaluateDay({
    required int water,
    required double sleep,
    required int steps,
  }) {
    final waterEval = evaluateWater(water);
    final sleepEval = evaluateSleep(sleep);
    final stepsEval = evaluateSteps(steps);

    int score = 0;
    
    if (waterEval['status'] == 'excellent') score += 33;
    else if (waterEval['status'] == 'good') score += 25;
    else if (waterEval['status'] == 'low') score += 15;
    
    if (sleepEval['status'] == 'excellent') score += 33;
    else if (sleepEval['status'] == 'good') score += 25;
    else if (sleepEval['status'] == 'low') score += 15;
    
    if (stepsEval['status'] == 'excellent') score += 34;
    else if (stepsEval['status'] == 'good') score += 25;
    else if (stepsEval['status'] == 'low') score += 15;

    String overallMessage;
    String emoji;
    
    if (score >= 85) {
      overallMessage = 'Идеальный день! Ты на пике здоровья! 🏆';
      emoji = '🏆';
    } else if (score >= 70) {
      overallMessage = 'Отличный день! Продолжай в том же духе! 🌟';
      emoji = '🌟';
    } else if (score >= 50) {
      overallMessage = 'Неплохо, но есть к чему стремиться! 💪';
      emoji = '💪';
    } else if (score >= 30) {
      overallMessage = 'Нужно постараться больше! 😕';
      emoji = '😕';
    } else {
      overallMessage = 'Срочно займись здоровьем! ⚠️';
      emoji = '⚠️';
    }

    return {
      'score': score,
      'message': overallMessage,
      'emoji': emoji,
      'waterEval': waterEval,
      'sleepEval': sleepEval,
      'stepsEval': stepsEval,
    };
  }
}
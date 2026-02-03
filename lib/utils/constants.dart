// lib/utils/constants.dart

class AppConstants {
  static const int defaultWaterGoal = 2000; // мл
  static const double defaultSleepGoal = 8.0; // часы
  static const int defaultStepsGoal = 10000; // шаги
  static const int defaultCaloriesGoal = 2000; // ккал

  static const String usersCollection = 'users';
  static const String healthDataCollection = 'health_data';
  static const String goalsCollection = 'goals';

  static const String moodHappy = 'happy';
  static const String moodNeutral = 'neutral';
  static const String moodSad = 'sad';

  static const Map<String, String> moodEmojis = {
    moodHappy: '😊',
    moodNeutral: '😐',
    moodSad: '😔',
  };

  static const Map<String, String> moodNames = {
    moodHappy: 'Отлично',
    moodNeutral: 'Нормально',
    moodSad: 'Грустно',
  };

  static const String dateFormat = 'dd.MM.yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd.MM.yyyy HH:mm';

  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyIsLoggedIn = 'is_logged_in';

  static const int waterReminderInterval = 120; 
  static const int activityReminderInterval = 60; 

  static const int maxWaterIntake = 5000;
  static const int maxSteps = 50000; 
  static const double maxSleepHours = 16.0; 
}

class AppStrings {
  static const String appName = 'HealthVision';
  static const String welcome = 'Добро пожаловать!';
  static const String hello = 'Привет';
  
  static const String water = 'Вода';
  static const String sleep = 'Сон';
  static const String steps = 'Шаги';
  static const String mood = 'Настроение';
  static const String calories = 'Калории';
  static const String weight = 'Вес';
  static const String heartRate = 'Пульс';

  static const String ml = 'мл';
  static const String liters = 'л';
  static const String hours = 'ч';
  static const String kg = 'кг';
  static const String kcal = 'ккал';
  static const String bpm = 'уд/мин';

  static const String save = 'Сохранить';
  static const String cancel = 'Отмена';
  static const String login = 'Войти';
  static const String register = 'Зарегистрироваться';
  static const String logout = 'Выйти';
  static const String update = 'Обновить';
  static const String delete = 'Удалить';
  static const String add = 'Добавить';

  static const String dataUpdated = 'Данные обновлены!';
  static const String errorOccurred = 'Произошла ошибка';
  static const String noDataAvailable = 'Нет доступных данных';
  static const String loading = 'Загрузка...';

  static const String emailHint = 'Email';
  static const String passwordHint = 'Пароль';
  static const String nameHint = 'Имя';
  
  static const String emailRequired = 'Введите email';
  static const String passwordRequired = 'Введите пароль';
  static const String nameRequired = 'Введите имя';
  static const String invalidEmail = 'Неверный формат email';
  static const String passwordTooShort = 'Пароль должен быть не менее 6 символов';
}
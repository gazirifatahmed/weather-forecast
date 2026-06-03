class AppStrings {
  static const String apiKey = 'bd78ef1800ee48ccb1c02648260206';
  static const String baseUrl = 'https://api.weatherapi.com/v1';

  static Map<String, Map<String, String>> localizedValues = {
    'en': {
      'search_city': 'Search City...',
      'humidity': 'Humidity',
      'wind': 'Wind Speed',
      'feels_like': 'Feels Like',
      'prayer_friendly': 'Prayer Friendly Weather',
      'smart_feeling': 'Smart Feeling',
      'weather_story': 'Weather Story',
      'drink_water': 'Drink plenty of water!',
      'stay_safe': 'Stay safe and carry an umbrella.',
      'pleasant': 'Weather is pleasant outside.',
    },
    'bn': {
      'search_city': 'শহর খুঁজুন...',
      'humidity': 'আর্দ্রতা',
      'wind': 'বাতাসের গতি',
      'feels_like': 'অনূভুত তাপমাত্রা',
      'prayer_friendly': 'নামাজের সময় আবহাওয়া',
      'smart_feeling': 'স্মার্ট ফিলিং',
      'weather_story': 'আবহাওয়ার গল্প',
      'drink_water': 'পানি বেশি পান করুন!',
      'stay_safe': 'নিরাপদে থাকুন এবং ছাতা সাথে রাখুন।',
      'pleasant': 'বাইরের আবহাওয়া বেশ চমৎকার।',
    }
  };

  static String get(String key, String lang) {
    return localizedValues[lang]?[key] ?? key;
  }
}
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class HourlyForecast extends Equatable {
  final String time;
  final double tempC;
  final String conditionText;
  final String iconUrl;
  final int chanceOfRain;

  const HourlyForecast({
    required this.time,
    required this.tempC,
    required this.conditionText,
    required this.iconUrl,
    required this.chanceOfRain,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    String formattedTime = '';
    try {
      DateTime parsedDate = DateTime.parse(json['time']);
      formattedTime = DateFormat('j').format(parsedDate); // e.g., 3 PM
    } catch (_) {
      formattedTime = json['time'].toString().split(' ').last;
    }

    return HourlyForecast(
      time: formattedTime,
      tempC: (json['temp_c'] as num).toDouble(),
      conditionText: json['condition']['text'] ?? '',
      iconUrl: 'https:${json['condition']['icon']}',
      chanceOfRain: json['chance_of_rain'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [time, tempC, conditionText, iconUrl, chanceOfRain];
}

class DailyForecast extends Equatable {
  final String date;
  final String dayName;
  final double maxTempC;
  final double minTempC;
  final int chanceOfRain;
  final String conditionText;
  final String iconUrl;

  const DailyForecast({
    required this.date,
    required this.dayName,
    required this.maxTempC,
    required this.minTempC,
    required this.chanceOfRain,
    required this.conditionText,
    required this.iconUrl,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    String dayStr = '';
    try {
      DateTime parsedDate = DateTime.parse(json['date']);
      dayStr = DateFormat('E').format(parsedDate); // Wed, Thu etc.
    } catch (_) {
      dayStr = json['date'];
    }

    return DailyForecast(
      date: json['date'] ?? '',
      dayName: dayStr,
      maxTempC: (json['day']['maxtemp_c'] as num).toDouble(),
      minTempC: (json['day']['mintemp_c'] as num).toDouble(),
      chanceOfRain: json['day']['daily_chance_of_rain'] as int? ?? 0,
      conditionText: json['day']['condition']['text'] ?? '',
      iconUrl: 'https:${json['day']['condition']['icon']}',
    );
  }

  @override
  List<Object?> get props => [date, dayName, maxTempC, minTempC, chanceOfRain, conditionText, iconUrl];
}

class WeatherModel extends Equatable {
  final String cityName;
  final double tempC;
  final double feelsLikeC;
  final String condition;
  final int humidity;
  final double windKph;
  
  final double pressureMb;
  final double visKm;
  final String sunrise;
  final String sunset;
  final String moonrise;
  final String moonset;
  final String moonPhase;
  final List<HourlyForecast> hourlyForecast;
  final List<DailyForecast> dailyForecast;

  const WeatherModel({
    required this.cityName,
    required this.tempC,
    required this.feelsLikeC,
    required this.condition,
    required this.humidity,
    required this.windKph,
    required this.pressureMb,
    required this.visKm,
    required this.sunrise,
    required this.sunset,
    required this.moonrise,
    required this.moonset,
    required this.moonPhase,
    required this.hourlyForecast,
    required this.dailyForecast,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    var forecastDayList = json['forecast']['forecastday'] as List? ?? [];
    
    List<HourlyForecast> tempHourly = [];
    if (forecastDayList.isNotEmpty) {
      var hours = forecastDayList[0]['hour'] as List? ?? [];
      for (var h in hours) {
        tempHourly.add(HourlyForecast.fromJson(h));
      }
    }

    List<DailyForecast> tempDaily = [];
    for (var d in forecastDayList) {
      tempDaily.add(DailyForecast.fromJson(d));
    }

    var currentAstro = forecastDayList.isNotEmpty 
        ? forecastDayList[0]['astro'] 
        : {
            'sunrise': '05:11 AM',
            'sunset': '06:41 PM',
            'moonrise': '08:37 PM',
            'moonset': '06:19 AM',
            'moon_phase': 'Waning Gibbous'
          };

    return WeatherModel(
      cityName: json['location']['name'],
      tempC: (json['current']['temp_c'] as num).toDouble(),
      feelsLikeC: (json['current']['feelslike_c'] as num).toDouble(),
      condition: json['current']['condition']['text'],
      humidity: json['current']['humidity'] as int,
      windKph: (json['current']['wind_kph'] as num).toDouble(),
      pressureMb: (json['current']['pressure_mb'] as num).toDouble(),
      visKm: (json['current']['vis_km'] as num).toDouble(),
      sunrise: currentAstro['sunrise'] ?? '',
      sunset: currentAstro['sunset'] ?? '',
      moonrise: currentAstro['moonrise'] ?? '',
      moonset: currentAstro['moonset'] ?? '',
      moonPhase: currentAstro['moon_phase'] ?? '',
      hourlyForecast: tempHourly,
      dailyForecast: tempDaily,
    );
  }

  // --- স্মার্ট অ্যালার্ট সিস্টেমের জন্য নতুন গেটার্স ---
  
  // বর্তমানে বৃষ্টি হচ্ছে কিনা চেক
  bool get isRainingNow {
    final lowerCondition = condition.toLowerCase();
    return lowerCondition.contains('rain') || lowerCondition.contains('drizzle') || lowerCondition.contains('shower');
  }

  // আগামী ১৫-৩০ মিনিটের মধ্যে বৃষ্টি আসার সম্ভাবনা আছে কিনা (পরবর্তী ঘণ্টার পূর্বাভাস চেক করে)
  bool get isRainImminent {
    if (hourlyForecast.isEmpty) return false;
    // বর্তমান সময়ের পরবর্তী ১-২ ঘণ্টার ডাটা চেক
    final nextHour = hourlyForecast.first;
    final lowerNextCondition = nextHour.conditionText.toLowerCase();
    return nextHour.chanceOfRain >= 65 || lowerNextCondition.contains('rain');
  }

  // বৃষ্টির সর্বোচ্চ সম্ভাবনা পার্সেন্টেজ বের করা
  int get rainChance {
    if (hourlyForecast.isEmpty) return 0;
    return hourlyForecast.first.chanceOfRain;
  }

  @override
  List<Object?> get props => [
        cityName, tempC, feelsLikeC, condition, humidity, windKph,
        pressureMb, visKm, sunrise, sunset, moonrise, moonset, moonPhase,
        hourlyForecast, dailyForecast
      ];

  String getSmartFeeling(String lang) {
    if (feelsLikeC >= 36) {
      return lang == 'bn' ? '🔥 খুব গরম অনুভূত হবে। পানি বেশি পান করুন।' : '🔥 Extremely hot outside. Drink plenty of water!';
    } else if (feelsLikeC <= 20) {
      return lang == 'bn' ? '🥶 বেশ ঠান্ডা অনুভূতি। হালকা গরম কাপড় রাখুন।' : '🥶 Chilly weather. Keep warm clothes handy.';
    } else {
      return lang == 'bn' ? '🌿 চমৎকার ও আরামদায়ক আবহাওয়া।' : '🌿 Very pleasant and comfortable weather.';
    }
  }

  String getWeatherStory(String lang) {
    if (lang == 'bn') {
      return 'আজ $cityName-এ আবহাওয়া মূলত "$condition"। বর্তমানে তাপমাত্রা $tempC°C, তবে বাতাসে আর্দ্রতা $humidity% হওয়ায় শরীরী অনুভূতি $feelsLikeC°C এর মতো হতে পারে। বাতাসের গতিবেগ $windKph কিমি/ঘণ্টা।';
    } else {
      return 'Today in $cityName, the weather is mostly "$condition". The actual temperature is $tempC°C, but with $humidity% humidity, it feels closer to $feelsLikeC°C. Winds are blowing at $windKph kph.';
    }
  }
}
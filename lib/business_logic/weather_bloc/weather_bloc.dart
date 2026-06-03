import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'weather_event.dart';
import 'weather_state.dart';
import '../../data/repository/weather_repository.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherRepository repository;
  
  // অডিও প্লেয়ার এবং নোটিফিকেশন প্লাগইন ইনস্ট্যান্স
  final AudioPlayer _appOpenPlayer = AudioPlayer();
  final AudioPlayer _alertPlayer = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  WeatherBloc({required this.repository}) : super(WeatherInitial()) {
    
    // নোটিফিকেশন ইনিশিয়ালাইজেশন
    _initNotificationEngine();

    // ১. নির্দিষ্ট সিটির মেইন আবহাওয়া ফেচ করা ও রেইন অ্যালার্ট ট্রিগার করা
    on<FetchWeatherByCity>((event, emit) async {
      emit(WeatherLoading());
      try {
        final weather = await repository.getWeather(event.cityName);
        emit(WeatherLoaded(weather));
        
        // স্মার্ট রেইন প্রিমিয়াম অ্যালার্ট লজিক চেক
        if (weather.isRainingNow) {
          // বৃষ্টি শুরু হলে ২-৩ বার সাউন্ড প্লে হবে
          _playAlertSound('sounds/rain.mp3', loopCount: 2);
        } else if (weather.isRainImminent) {
          // বৃষ্টি শুরু হওয়ার ১৫ মিনিট আগে নোটিফিকেশন ও সাউন্ড অ্যালার্ট
          _showSmartNotification(
            title: "🌧️ রেইন অ্যালার্ট! (Rain Warning)",
            body: "আগামী ১৫ মিনিটের মধ্যে আপনার এলাকায় বৃষ্টি শুরু হওয়ার সম্ভাবনা রয়েছে (${weather.rainChance}% Chance)!",
          );
          _playAlertSound('sounds/rain.mp3', loopCount: 1);
        }
      } catch (e) {
        emit(const WeatherError("Could not fetch weather. Check city name or connection."));
      }
    });

    // ২. ইনস্ট্যান্ট লোকেশন সাজেশন খোঁজা (Autocomplete)
    on<SearchLocationQueryChanged>((event, emit) async {
      final query = event.query.trim();
      
      if (query.isEmpty || query.length < 2) {
        emit(const WeatherSuggestionsLoaded([]));
        return;
      }
      
      try {
        final suggestions = await repository.searchLocations(query);
        emit(WeatherSuggestionsLoaded(suggestions));
      } catch (_) {
        emit(const WeatherSuggestionsLoaded([]));
      }
    });

    // ৩. সাজেশন লিস্ট ক্লিয়ার করা
    on<ClearSuggestions>((event, emit) {
      emit(const WeatherSuggestionsLoaded([]));
    });

    // ৪. অ্যাপ ওপেন সাউন্ড ইভেন্ট (ইউজার প্রতিবার অ্যাপে ঢুকলে ট্রিপ হবে)
    on<TriggerAppOpenSound>((event, emit) async {
      try {
        await _appOpenPlayer.stop();
        await _appOpenPlayer.play(AssetSource('sounds/open_app.mp3'));
      } catch (e) {
        print("Error playing app open sound: $e");
      }
    });

    // ৫. অ্যাপ ক্লোজ/ব্যাকগ্রাউন্ড সাউন্ড অফ ইভেন্ট (হোম বাটন চাপলে বা অ্যাপ মিনিমাইজ করলে)
    on<StopAppOpenSound>((event, emit) async {
      await _appOpenPlayer.stop();
      await _alertPlayer.stop();
    });

    // ৬. ভূমিকম্প অ্যালার্ট টেস্ট এবং লাইভ ট্রিগার ইভেন্ট (Mock System)
    on<SimulateEarthquakeAlert>((event, emit) async {
      _showSmartNotification(
        title: "🚨 ভূমিকম্প সতর্কবার্তা! (Earthquake Alert)",
        body: "সতর্ক থাকুন! একটি মৃদু কম্পন অনুভূত হয়েছে। নিরাপদ স্থানে আশ্রয় নিন।",
      );
      // আর্থকোয়েক সাউন্ড প্লে করা
      _playAlertSound('sounds/earthquake.mp3', loopCount: 3);
    });
  }

  // নোটিফিকেশন প্লাগইন সেটআপ
  void _initNotificationEngine() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  // পুশ নোটিফিকেশন শো করার মেথড
  void _showSmartNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'weatherly_alerts_id',
      'Weatherly Smart Alerts',
      channelDescription: 'Real-time weather and environment emergency sounds',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false, // যেহেতু আমরা অডিওপ্লেয়ার দিয়ে ম্যানুয়ালি প্রিমিয়াম সাউন্ড কন্ট্রোল করছি
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await _notificationsPlugin.show(0, title, body, platformChannelSpecifics);
  }

  // অ্যালার্ট সাউন্ড কাস্টম লুপে প্লে করার চমৎকার লজিক
  void _playAlertSound(String path, {int loopCount = 1}) async {
    try {
      await _alertPlayer.stop();
      int played = 0;
      
      _alertPlayer.onPlayerComplete.listen((event) async {
        played++;
        if (played < loopCount) {
          await _alertPlayer.play(AssetSource(path));
        }
      });
      
      await _alertPlayer.play(AssetSource(path));
    } catch (e) {
      print("Error playing alert sound: $e");
    }
  }

  @override
  Future<void> close() {
    _appOpenPlayer.dispose();
    _alertPlayer.dispose();
    return super.close();
  }
}
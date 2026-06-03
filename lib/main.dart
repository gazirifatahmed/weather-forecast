import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'data/datasource/weather_remote_datasource.dart';
import 'data/repository/weather_repository.dart';
import 'business_logic/weather_bloc/weather_bloc.dart';
import 'business_logic/weather_bloc/weather_event.dart'; // ইভেন্ট ইমপোর্ট করা হলো
import 'business_logic/language_cubit.dart';
import 'presentation/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // High-performance light bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent)
  );

  // Initialize Architecture Dependencies
  final http.Client httpClient = http.Client();
  final WeatherRemoteDataSource remoteDataSource = WeatherRemoteDataSource(client: httpClient);
  final WeatherRepository weatherRepository = WeatherRepository(remoteDataSource: remoteDataSource);

  runApp(
    WeatherlyApp(weatherRepository: weatherRepository),
  );
}

class WeatherlyApp extends StatelessWidget {
  final WeatherRepository weatherRepository;

  const WeatherlyApp({super.key, required this.weatherRepository});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LanguageCubit>(
          create: (context) => LanguageCubit(),
        ),
        BlocProvider<WeatherBloc>(
          create: (context) => WeatherBloc(repository: weatherRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Weatherly',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Roboto', // Default system fallback to preserve lightweight size
        ),
        // এখানে AppLifecycleWrapper দিয়ে HomeScreen কে র‍্যাপ করা হয়েছে যেন সাউন্ড অটোমেটিক হ্যান্ডেল হয়
        home: const AppLifecycleWrapper(child: HomeScreen()),
      ),
    );
  }
}

// --- অ্যাপ ওপেন, ক্লোজ এবং ব্যাকগ্রাউন্ড লাইফসাইকেল ম্যানেজমেন্ট র্যাপার ---
class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;
  const AppLifecycleWrapper({super.key, required this.child});

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // অ্যাপ একদম প্রথমবার স্ক্রিনে লোড হওয়ার সাথে সাথে ওপেনিং সাউন্ড ট্রিগার হবে
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeatherBloc>().add(TriggerAppOpenSound());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ব্যাকগ্রাউন্ড (মিনিমাইজ) থেকে অ্যাপে আবার ফিরে আসলে সাউন্ড বাজবে
      context.read<WeatherBloc>().add(TriggerAppOpenSound());
    } else if (state == AppLifecycleState.paused) {
      // হোম বাটন প্রেস করে ব্যাকগ্রাউন্ডে চলে গেলে বা অ্যাপ থেকে বের হলে সাউন্ড বন্ধ হয়ে যাবে
      context.read<WeatherBloc>().add(StopAppOpenSound());
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
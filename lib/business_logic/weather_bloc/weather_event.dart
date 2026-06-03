import 'package:equatable/equatable.dart';

abstract class WeatherEvent extends Equatable {
  const WeatherEvent();

  @override
  List<Object?> get props => [];
}

class FetchWeatherByCity extends WeatherEvent {
  final String cityName;

  const FetchWeatherByCity(this.cityName);

  @override
  List<Object?> get props => [cityName];
}

// নতুন ইভেন্ট: ইউজার যখন সার্চ বারে টাইপ করবে (Autocomplete)
class SearchLocationQueryChanged extends WeatherEvent {
  final String query;

  const SearchLocationQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}

// নতুন ইভেন্ট: সার্চ শেষ হলে বা ক্যানসেল করলে সাজেশন লিস্ট ফাকা করার জন্য
class ClearSuggestions extends WeatherEvent {}

// --- আপনার রিকোয়েস্ট করা নতুন ৩টি সাউন্ড এবং অ্যালার্ট ইভেন্ট ---
class TriggerAppOpenSound extends WeatherEvent {}
class StopAppOpenSound extends WeatherEvent {}
class SimulateEarthquakeAlert extends WeatherEvent {}
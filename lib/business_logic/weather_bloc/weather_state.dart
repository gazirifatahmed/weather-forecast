import 'package:equatable/equatable.dart';
import '../../data/models/weather_model.dart';
import '../../data/models/location_suggestion.dart'; // নতুন মডেল ইম্পোর্ট

abstract class WeatherState extends Equatable {
  const WeatherState();
  
  @override
  List<Object?> get props => [];
}

class WeatherInitial extends WeatherState {}
class WeatherLoading extends WeatherState {}

class WeatherLoaded extends WeatherState {
  final WeatherModel weather;
  const WeatherLoaded(this.weather);

  @override
  List<Object?> get props => [weather];
}

// নতুন স্টেট যা এখন গ্লোবাল মডেল ব্যবহার করছে
class WeatherSuggestionsLoaded extends WeatherState {
  final List<LocationSuggestion> suggestions;
  const WeatherSuggestionsLoaded(this.suggestions);

  @override
  List<Object?> get props => [suggestions];
}

class WeatherError extends WeatherState {
  final String message;
  const WeatherError(this.message);

  @override
  List<Object?> get props => [message];
}
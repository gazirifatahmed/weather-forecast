import '../models/weather_model.dart';
import '../models/location_suggestion.dart';
import '../datasource/weather_remote_datasource.dart';

class WeatherRepository {
  final WeatherRemoteDataSource remoteDataSource;

  WeatherRepository({required this.remoteDataSource});

  // 🔹 আবহাওয়া গেট করার মেথড
  Future<WeatherModel> getWeather(String cityName) async {
    try {
      final rawData = await remoteDataSource.getWeather(cityName);
      return WeatherModel.fromJson(rawData);
    } catch (e) {
      throw Exception("Failed to process weather data: $e");
    }
  }

  // 🔹 Photon API থেকে আসা ফিচার লিস্টকে মডেলে রূপান্তর
  Future<List<LocationSuggestion>> searchLocations(String query) async {
    try {
      final rawSuggestions = await remoteDataSource.searchLocations(query);
      
      return rawSuggestions
          .map((json) => LocationSuggestion.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception("Repository search failed: $e");
    }
  }
}
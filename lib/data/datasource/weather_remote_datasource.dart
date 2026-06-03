import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherRemoteDataSource {
  final http.Client client;
  final String apiKey = "772488f7bfb64b1fb46111524260206"; // আপনার আসল WeatherAPI Key
  final String baseUrl = "https://api.weatherapi.com/v1";

  WeatherRemoteDataSource({required this.client});

  // 🔹 মেইন আবহাওয়া ফেচ করার মেথড (এটি নাম অথবা "lat,lon" কোঅর্ডিনেট দুটোরই সাপোর্ট করে)
  Future<Map<String, dynamic>> getWeather(String cityName) async {
    final url = Uri.parse('$baseUrl/forecast.json?key=$apiKey&q=$cityName&days=7&aqi=no&alerts=no');
    
    try {
      final response = await client.get(url);
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("City not found or API error");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }

  // 🔹 🔥 ১০০% ফ্রি Photon Geocoding API ব্যবহার করে সূক্ষ্ম লোকেশন খোঁজার মেথড
  Future<List<dynamic>> searchLocations(String query) async {
    // বাংলা টাইপিং এবং স্পেসের সুরক্ষার জন্য Uri.encodeComponent ব্যবহার করা হয়েছে
    final url = Uri.parse('https://photon.komoot.io/api/?q=${Uri.encodeComponent(query)}&limit=7');
    
    try {
      final response = await client.get(url);
      
      if (response.statusCode == 200) {
        // বাংলা বা অন্যান্য ইউনিকোড ক্যারেক্টার ঠিক রাখতে utf8.decode করা হয়েছে
        final Map<String, dynamic> decodedData = json.decode(utf8.decode(response.bodyBytes));
        final List<dynamic> features = decodedData['features'] ?? [];
        return features;
      } else {
        throw Exception("Failed to fetch location suggestions from Photon");
      }
    } catch (e) {
      throw Exception("Network error: $e");
    }
  }
}
import 'package:equatable/equatable.dart';

class LocationSuggestion extends Equatable {
  final String name;
  final String region;
  final String country;
  final double lat;
  final double lon;

  const LocationSuggestion({
    required this.name,
    required this.region,
    required this.country,
    required this.lat,
    required this.lon,
  });

  // ✅ Photon API এর অনন্য GeoJSON ফরম্যাট পার্স করার ফ্যাক্টরি মেথড
  factory LocationSuggestion.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'] ?? {};
    final geometry = json['geometry'] ?? {};
    final List<dynamic> coordinates = geometry['coordinates'] ?? [0.0, 0.0];

    // ⚠️ মনে রাখবেন: Photon API কোঅর্ডিনেট দেয় [Longitude, Latitude] সিকোয়েন্সে
    double lon = coordinates.isNotEmpty ? (coordinates[0] as num).toDouble() : 0.0;
    double lat = coordinates.length > 1 ? (coordinates[1] as num).toDouble() : 0.0;

    String name = properties['name'] ?? '';
    
    // সিটি, স্টেট বা ডিস্ট্রিক্ট থেকে সুন্দর একটি রিজিয়ন নাম তৈরি করা হচ্ছে
    String region = properties['city'] ?? properties['state'] ?? properties['district'] ?? '';
    String country = properties['country'] ?? '';

    return LocationSuggestion(
      name: name,
      region: region,
      country: country,
      lat: lat,
      lon: lon,
    );
  }

  @override
  List<Object?> get props => [name, region, country, lat, lon];
}
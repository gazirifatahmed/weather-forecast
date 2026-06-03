import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../../core/constants/app_strings.dart';
import '../../business_logic/weather_bloc/weather_bloc.dart';
import '../../business_logic/weather_bloc/weather_event.dart';
import '../../business_logic/weather_bloc/weather_state.dart';
import '../../business_logic/language_cubit.dart';
import '../../data/models/weather_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  WeatherModel? _cachedWeather;
  LinearGradient? _cachedBg;
  List<dynamic> _suggestions = [];

  @override
  void initState() {
    super.initState();
    context.read<WeatherBloc>().add(const FetchWeatherByCity('Dhaka'));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _searchCity() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.read<WeatherBloc>().add(FetchWeatherByCity(query));
      setState(() {
        _suggestions = []; 
      });
    }
  }

  LinearGradient _getDynamicBackground(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('rain') || cond.contains('drizzle') || cond.contains('thunder')) {
      return const LinearGradient(
        colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else if (cond.contains('cloud') || cond.contains('overcast') || cond.contains('mist')) {
      return const LinearGradient(
        colors: [Color(0xFF3E5151), Color(0xFFDECBA4)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF2B5876), Color(0xFF4E4376)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = context.watch<LanguageCubit>().state;

    return Scaffold(
      body: BlocBuilder<WeatherBloc, WeatherState>(
        builder: (context, state) {
          if (state is WeatherLoaded) {
            _cachedWeather = state.weather;
            _cachedBg = _getDynamicBackground(state.weather.condition);
            _suggestions = []; 
          } else if (state is WeatherSuggestionsLoaded) {
            _suggestions = state.suggestions; 
          } else if (state is WeatherLoading) {
            _suggestions = []; 
          }

          LinearGradient currentBg = _cachedBg ?? const LinearGradient(colors: [Color(0xFF2B5876), Color(0xFF4E4376)]);

          return AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(gradient: currentBg),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: Colors.black87),
                            decoration: InputDecoration(
                              hintText: AppStrings.get('search_city', currentLang),
                              hintStyle: const TextStyle(color: Colors.black38),
                              fillColor: Colors.white.withValues(alpha: 0.8),
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(Icons.search, color: Colors.deepPurpleAccent),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.arrow_forward_rounded, color: Colors.deepPurpleAccent),
                                onPressed: _searchCity,
                              ),
                            ),
                            onChanged: (value) {
                              if (value.trim().isNotEmpty) {
                                context.read<WeatherBloc>().add(SearchLocationQueryChanged(value.trim()));
                              } else {
                                setState(() {
                                  _suggestions = [];
                                });
                              }
                            },
                            onSubmitted: (_) => _searchCity(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        CircleAvatar(
                          backgroundColor: Colors.white.withValues(alpha: 0.8),
                          child: IconButton(
                            icon: const Icon(Icons.language, color: Colors.black87),
                            onPressed: () => context.read<LanguageCubit>().toggleLanguage(),
                          ),
                        ),
                      ],
                    ),

                    if (_suggestions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 220),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.955),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              )
                            ],
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: _suggestions.length,
                            itemBuilder: (context, index) {
                              final suggestion = _suggestions[index];
                              
                              final String name = suggestion.name ?? '';
                              final String region = suggestion.region ?? '';
                              final String country = suggestion.country ?? '';

                              return ListTile(
                                leading: const Icon(Icons.location_on, color: Colors.deepPurpleAccent),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                                subtitle: Text(region.isNotEmpty ? "$region, $country" : country, style: const TextStyle(color: Colors.black54)),
                                onTap: () {
                                  _searchController.text = name;
                                  
                                  final String preciseCoordinate = "${suggestion.lat},${suggestion.lon}";
                                  context.read<WeatherBloc>().add(FetchWeatherByCity(preciseCoordinate));
                                  
                                  setState(() {
                                    _suggestions = []; 
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 15),

                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: _buildWeatherContent(state, currentLang),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherContent(WeatherState state, String lang) {
    if (state is WeatherLoading && _cachedWeather == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 150),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    } 
    
    if (_cachedWeather != null) {
      final weather = _cachedWeather!;
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 24),
              const SizedBox(width: 5),
              Text(
                weather.cityName,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${weather.tempC.toStringAsFixed(0)}°',
            style: const TextStyle(fontSize: 84, fontWeight: FontWeight.w100, color: Colors.white),
          ),
          Text(
            weather.condition,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: Colors.white70),
          ),
          const SizedBox(height: 25),

          _buildHourlyForecast(weather.hourlyForecast),
          const SizedBox(height: 15),

          _buildPremiumCard(
            child: Row(
              children: [
                const Icon(Icons.thermostat, color: Colors.orangeAccent, size: 36),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppStrings.get('feels_like', lang)} ${weather.feelsLikeC.toStringAsFixed(0)}°',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        weather.getSmartFeeling(lang),
                        style: const TextStyle(color: Colors.white70, fontSize: 13), 
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),

          _build7DayForecast(weather.dailyForecast, lang),
          const SizedBox(height: 15),

          Row(
            children: [
              Expanded(child: _buildPressureCard(weather.pressureMb, lang)),
              const SizedBox(width: 15),
              Expanded(child: _buildVisibilityCard(weather.visKm, lang)),
            ],
          ),
          const SizedBox(height: 15),

          _buildSunTimelineCard(weather.sunrise, weather.sunset, lang),
          const SizedBox(height: 15),

          _buildMoonCard(weather.moonPhase, weather.moonrise, weather.moonset, lang),
          const SizedBox(height: 15),

          // 🔥 নতুন যুক্ত করা ভূমিকম্প অ্যালার্ট টেস্ট বাটন
          _buildEarthquakeTestButton(context),
          const SizedBox(height: 15),

          _buildOldUniqueFeatures(weather, lang),
        ],
      );
    } else if (state is WeatherError) {
      return Padding(
        padding: const EdgeInsets.only(top: 150),
        child: Center(
          child: Text(state.message, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ),
      );
    }
    return const SizedBox();
  }

  // ভূমিকম্প টেস্ট বাটনের কাস্টম মেথড
  Widget _buildEarthquakeTestButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        context.read<WeatherBloc>().add(SimulateEarthquakeAlert());
      },
      icon: const Icon(Icons.gavel_rounded, color: Colors.white),
      label: const Text(
        "Test Earthquake Alert 🚨",
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52), // ফুল-উইডথ সাইজ
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 2,
      ),
    );
  }

  Widget _buildHourlyForecast(List<HourlyForecast> hours) {
    return _buildPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: hours.length > 24 ? 24 : hours.length,
              itemBuilder: (context, index) {
                final hour = hours[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(hour.time, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      Image.network(hour.iconUrl, width: 32, height: 32, errorBuilder: (_, __, ___) => const Icon(Icons.wb_cloudy, color: Colors.white)),
                      Text('${hour.tempC.toStringAsFixed(0)}°', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      if (hour.chanceOfRain > 0)
                        Text('${hour.chanceOfRain}%', style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 11, fontWeight: FontWeight.bold))
                      else
                        const Text('0%', style: TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _build7DayForecast(List<DailyForecast> days, String lang) {
    return _buildPremiumCard(
      child: Column(
        children: List.generate(days.length, (index) {
          final day = days[index];
          String displayName = day.dayName;
          if (index == 0) displayName = lang == 'bn' ? 'আজ' : 'Today';

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(displayName, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      const Icon(Icons.water_drop, color: Colors.lightBlueAccent, size: 14),
                      const SizedBox(width: 4),
                      Text('${day.chanceOfRain}%', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
                Image.network(day.iconUrl, width: 28, height: 28, errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny, color: Colors.white)),
                const SizedBox(width: 20),
                Text(
                  '${day.maxTempC.toStringAsFixed(0)}°  ${day.minTempC.toStringAsFixed(0)}°',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPressureCard(double pressure, String lang) {
    return _buildPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compress, color: Colors.white70, size: 16),
              const SizedBox(width: 5),
              Text(lang == 'bn' ? 'বায়ুচাপ' : 'Pressure', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: CustomPaint(
              size: const Size(90, 50),
              painter: GaugePainter(value: (pressure - 950) / 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(pressure.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text('mb', style: TextStyle(color: Colors.white60, fontSize: 11)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityCard(double vis, String lang) {
    return _buildPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility, color: Colors.white70, size: 16),
              const SizedBox(width: 5),
              Text(lang == 'bn' ? 'দৃশ্যমানতা' : 'Visibility', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 15),
          Text(lang == 'bn' ? 'এখন পরিষ্কার' : 'Clear right now', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 5),
          Text('${vis.toStringAsFixed(2)} km', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSunTimelineCard(String sunrise, String sunset, String lang) {
    return _buildPremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomPaint(
            size: const Size(double.infinity, 70),
            painter: SunArcPainter(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lang == 'bn' ? 'সূর্যোদয়' : 'Sunrise', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  Text(sunrise, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(lang == 'bn' ? 'সূর্যাস্ত' : 'Sunset', style: const TextStyle(color: Colors.white60, fontSize: 12)),
                  Text(sunset, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoonCard(String phase, String rise, String set, String lang) {
    return _buildPremiumCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.brightness_3, color: Colors.amberAccent, size: 18),
                    const SizedBox(width: 5),
                    Text(lang == 'bn' ? 'চাঁদের দশা' : 'Moon Phase', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 15),
                Text(phase, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${lang == 'bn' ? 'চন্দ্রাছায়া' : 'Moonset'}: $set', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 5),
                  Text('${lang == 'bn' ? 'চন্দ্রোদয়' : 'Moonrise'}: $rise', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOldUniqueFeatures(WeatherModel weather, String lang) {
    return Column(
      children: [
        _buildPremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.amberAccent),
                  const SizedBox(width: 8),
                  Text(AppStrings.get('weather_story', lang), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(color: Colors.white24, height: 20),
              Text(weather.getWeatherStory(lang), style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
            ],
          ),
        ),
        const SizedBox(height: 15),
        _buildPremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mosque, color: Colors.greenAccent),
                  const SizedBox(width: 8),
                  Text(AppStrings.get('prayer_friendly', lang), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(color: Colors.white24, height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPrayerStatus(lang == 'bn' ? 'আসর' : 'Asr', weather.condition, Icons.wb_cloudy),
                  _buildPrayerStatus(lang == 'bn' ? 'মাগরিব' : 'Maghrib', weather.condition, Icons.nights_stay),
                ],
              )
            ],
          ),
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _buildPremiumCard(child: _buildFooterStat(AppStrings.get('humidity', lang), '${weather.humidity}%', Icons.water_drop))),
            const SizedBox(width: 15),
            Expanded(child: _buildPremiumCard(child: _buildFooterStat(AppStrings.get('wind', lang), '${weather.windKph} km/h', Icons.air))),
          ],
        ),
      ],
    );
  }

  Widget _buildPrayerStatus(String prayerName, String condition, IconData icon) {
    return Column(
      children: [
        Text(prayerName, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 5),
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 5),
        Text(condition, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFooterStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 5),
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildPremiumCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16.0),
      child: child,
    );
  }
}

class GaugePainter extends CustomPainter {
  final double value;
  GaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    final basePaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    final progressPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi, math.pi, false, basePaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), math.pi, math.pi * value.clamp(0.0, 1.0), false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class SunArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height);
    path.quadraticBezierTo(size.width / 2, -10, size.width, size.height);
    canvas.drawPath(path, paint);

    final sunPaint = Paint()..color = Colors.orangeAccent;
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.4), 6, sunPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
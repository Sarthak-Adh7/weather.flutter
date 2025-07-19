import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: WeatherPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class WeatherPage extends StatefulWidget {
  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _controller = TextEditingController();
  final String apiKey = 'bbc76d76cf351e4cd76e04e36e1b99eb';
  Map<String, dynamic>? weatherData;
  List<dynamic>? hourlyForecast;
  bool isLoading = false;
  String errorMessage = '';
  String currentTime = '';
  String currentDate = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    setState(() {
      currentTime = DateFormat('HH:mm').format(DateTime.now());
      currentDate = DateFormat('MMMM, d').format(DateTime.now());
    });
    Future.delayed(Duration(seconds: 1), _updateTime);
  }

  Future<void> fetchWeather(String city) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      weatherData = null;
      hourlyForecast = null;
    });

    final weatherUrl =
        'https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric';
    final forecastUrl =
        'https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric';

    try {
      final weatherResponse = await http.get(Uri.parse(weatherUrl));
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (weatherResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
        setState(() {
          weatherData = jsonDecode(weatherResponse.body);
          hourlyForecast = jsonDecode(forecastResponse.body)['list'].take(4).toList();
        });
      } else {
        setState(() {
          errorMessage = 'City not found!';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching weather.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      case 'rain':
        return Icons.water_drop;
      case 'drizzle':
        return Icons.grain;
      case 'thunderstorm':
        return Icons.bolt;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
        return Icons.foggy;
      default:
        return Icons.cloud_queue;
    }
  }

  Widget buildWeatherInfo() {
    if (isLoading) return CircularProgressIndicator(color: Colors.white);
    if (errorMessage.isNotEmpty) return Text(errorMessage, style: TextStyle(color: Colors.red));
    if (weatherData == null) return SizedBox.shrink();

    double temp = weatherData!['main']['temp'];
    double tempMax = weatherData!['main']['temp_max'];
    double tempMin = weatherData!['main']['temp_min'];
    String weatherCondition = weatherData!['weather'][0]['main'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${temp.toStringAsFixed(0)}°',
          style: TextStyle(
            color: Colors.white,
            fontSize: 80,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          weatherCondition,
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        Text(
          'Max: ${tempMax.toStringAsFixed(0)}° Min: ${tempMin.toStringAsFixed(0)}°',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
        SizedBox(height: 20),
        Icon(_getWeatherIcon(weatherCondition), color: Colors.blue, size: 150),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1E4B), Color(0xFF4A90E2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currentTime,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Row(
                      children: [
                        Icon(Icons.signal_cellular_alt, color: Colors.white),
                        SizedBox(width: 8),
                        Icon(Icons.battery_full, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _controller,
                  onSubmitted: (value) => fetchWeather(value.trim()),
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Search city',
                    labelStyle: TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search, color: Colors.white),
                      onPressed: () => fetchWeather(_controller.text.trim()),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: buildWeatherInfo(),
                ),
              ),
              Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Color(0xFF4A90E2),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Today',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Text(
                      currentDate,
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
              Container(
                color: Color(0xFF4A90E2),
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: hourlyForecast != null && hourlyForecast!.isNotEmpty
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: hourlyForecast!.asMap().entries.map((entry) {
                          int idx = entry.key;
                          var forecast = entry.value;
                          String time = DateFormat('HH:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  forecast['dt'] * 1000));
                          String temp = forecast['main']['temp'].toStringAsFixed(0) + '°C';
                          String condition = forecast['weather'][0]['main'];
                          return _buildHourlyForecast(time, temp, condition);
                        }).toList(),
                      )
                    : SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyForecast(String time, String temp, String condition) {
    return Column(
      children: [
        Text(
          time,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        SizedBox(height: 8),
        Icon(_getWeatherIcon(condition), color: Colors.white, size: 30),
        Text(
          temp,
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
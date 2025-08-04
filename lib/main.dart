import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'login_page.dart'; // Your login screen
import 'signup_page.dart'; // Optional, if you navigate manually

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCma38WWkVjMx-oCRZ59XWfu71H5Mpdz9Q",
        authDomain: "weatherapp-ppp.firebaseapp.com",
        projectId: "weatherapp-ppp",
        storageBucket: "weatherapp-ppp.appspot.com",
        messagingSenderId: "1076854260255",
        appId: "1:1076854260255:web:701bdb6af1c2957f95cb2a",
        measurementId: "G-556J0V49RT",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const WeatherPage(); // User is logged in
        } else {
          return const LoginPage(); // User is NOT logged in
        }
      },
    );
  }
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

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
      currentDate = DateFormat('MMMM d').format(DateTime.now());
    });
    Future.delayed(const Duration(seconds: 1), _updateTime);
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

      if (weatherResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        setState(() {
          weatherData = jsonDecode(weatherResponse.body);
          hourlyForecast = jsonDecode(forecastResponse.body)['list']
              .take(4)
              .toList();
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
    if (isLoading) return const CircularProgressIndicator(color: Colors.white);
    if (errorMessage.isNotEmpty) {
      return Text(errorMessage, style: const TextStyle(color: Colors.red));
    }
    if (weatherData == null) return const SizedBox.shrink();

    double temp = weatherData!['main']['temp'];
    double tempMax = weatherData!['main']['temp_max'];
    double tempMin = weatherData!['main']['temp_min'];
    String weatherCondition = weatherData!['weather'][0]['main'];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${temp.toStringAsFixed(0)}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 80,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          weatherCondition,
          style: const TextStyle(color: Colors.white, fontSize: 24),
        ),
        Text(
          'Max: ${tempMax.toStringAsFixed(0)}° Min: ${tempMin.toStringAsFixed(0)}°',
          style: const TextStyle(color: Colors.white70, fontSize: 18),
        ),
        const SizedBox(height: 20),
        Icon(_getWeatherIcon(weatherCondition),
            color: Colors.blue, size: 150),
      ],
    );
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Logged out")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather App"),
        backgroundColor: const Color(0xFF1E1E4B),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E4B), Color(0xFF4A90E2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(currentTime,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18)),
                    const Row(
                      children: [
                        Icon(Icons.signal_cellular_alt, color: Colors.white),
                        SizedBox(width: 8),
                        Icon(Icons.battery_full, color: Colors.white),
                      ],
                    )
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _controller,
                  onSubmitted: (value) => fetchWeather(value.trim()),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Search city',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: () => fetchWeather(_controller.text.trim()),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(child: Center(child: buildWeatherInfo())),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF4A90E2),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Today',
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    Text(currentDate,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18)),
                  ],
                ),
              ),
              Container(
                color: const Color(0xFF4A90E2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: hourlyForecast != null && hourlyForecast!.isNotEmpty
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: hourlyForecast!.asMap().entries.map((entry) {
                          var forecast = entry.value;
                          String time = DateFormat('HH:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  forecast['dt'] * 1000));
                          String temp =
                              '${forecast['main']['temp'].toStringAsFixed(0)}°C';
                          String condition = forecast['weather'][0]['main'];
                          return _buildHourlyForecast(time, temp, condition);
                        }).toList(),
                      )
                    : const SizedBox.shrink(),
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
        Text(time, style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 8),
        Icon(_getWeatherIcon(condition), color: Colors.white, size: 30),
        Text(
          temp,
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
} 
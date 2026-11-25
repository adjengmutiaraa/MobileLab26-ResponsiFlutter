import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'services/local_storage_service.dart';
import 'services/weather_api_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/location_viewmodel.dart';
import 'viewmodels/weather_viewmodel.dart';
import 'views/home_screen.dart';

/// Entry point utama aplikasi cuaca.
/// Menginisialisasi format tanggal bahasa Indonesia (`intl`), Local Storage (`SharedPreferences`),
/// dan menyuntikkan ViewModel ke widget tree melalui `MultiProvider`.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);
  final storageService = await LocalStorageService.create();
  final apiService = WeatherApiService();

  runApp(
    CuacaApp(
      apiService: apiService,
      storageService: storageService,
    ),
  );
}

class CuacaApp extends StatelessWidget {
  final WeatherApiService apiService;
  final LocalStorageService storageService;

  const CuacaApp({
    super.key,
    required this.apiService,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<WeatherViewModel>(
          create: (_) => WeatherViewModel(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
        ChangeNotifierProvider<LocationViewModel>(
          create: (_) => LocationViewModel(
            apiService: apiService,
            storageService: storageService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Aplikasi Cuaca Open-Meteo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}

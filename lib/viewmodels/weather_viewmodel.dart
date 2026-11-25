import 'package:flutter/foundation.dart';

import '../models/location_model.dart';
import '../models/weather_model.dart';
import '../services/local_storage_service.dart';
import '../services/weather_api_service.dart';

/// Status tampilan untuk Home / Weather Screen.
enum WeatherViewState {
  initial,
  loading,
  loaded,
  error,
}

/// ViewModel (MVVM) yang mengelola state dan logika bisnis untuk Home Screen.
/// Menggunakan [ChangeNotifier] dari package `provider` untuk memberi tahu View
/// setiap kali data cuaca, lokasi terpilih, atau status loading/error berubah.
class WeatherViewModel extends ChangeNotifier {
  final WeatherApiService _apiService;
  final LocalStorageService _storageService;

  WeatherViewState _state = WeatherViewState.initial;
  LocationModel _selectedLocation;
  WeatherModel? _weather;
  String? _errorMessage;

  WeatherViewModel({
    required this._apiService,
    required LocalStorageService storageService,
  })  : _storageService = storageService,
        _selectedLocation =
            storageService.getLastLocation() ?? LocationModel.defaultLocation;

  WeatherViewState get state => _state;
  LocationModel get selectedLocation => _selectedLocation;
  WeatherModel? get weather => _weather;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == WeatherViewState.loading;

  /// Dipanggil saat aplikasi mulai untuk memuat cuaca dari lokasi terakhir
  /// yang tersimpan di Local Storage (atau Jakarta jika belum ada).
  Future<void> initialize() async {
    _selectedLocation =
        _storageService.getLastLocation() ?? LocationModel.defaultLocation;
    await loadWeatherForLocation(_selectedLocation, saveToStorage: false);
  }

  /// Mengambil data cuaca terbaru dari Open-Meteo Forecast API untuk [location].
  /// Jika [saveToStorage] bernilai true, lokasi tersebut disimpan sebagai lokasi terakhir.
  Future<void> loadWeatherForLocation(
    LocationModel location, {
    bool saveToStorage = true,
  }) async {
    _selectedLocation = location;
    _state = WeatherViewState.loading;
    _errorMessage = null;
    notifyListeners();

    if (saveToStorage) {
      await _storageService.saveLastLocation(location);
    }

    try {
      final fetchedWeather = await _apiService.fetchWeather(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      _weather = fetchedWeather;
      _state = WeatherViewState.loaded;
    } on WeatherApiException catch (e) {
      _errorMessage = e.message;
      _state = WeatherViewState.error;
    } catch (_) {
      _errorMessage = 'Terjadi kesalahan tidak terduga saat memuat data cuaca.';
      _state = WeatherViewState.error;
    }

    notifyListeners();
  }

  /// Memuat ulang data cuaca untuk kota yang sedang dipilih.
  Future<void> refreshWeather() async {
    await loadWeatherForLocation(_selectedLocation, saveToStorage: false);
  }
}

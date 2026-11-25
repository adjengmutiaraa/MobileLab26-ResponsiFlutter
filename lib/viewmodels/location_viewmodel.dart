import 'package:flutter/foundation.dart';

import '../models/location_model.dart';
import '../services/local_storage_service.dart';
import '../services/weather_api_service.dart';

/// Status tampilan untuk Search / Location Screen.
enum SearchViewState {
  idle,
  loading,
  loaded,
  empty,
  error,
}

/// ViewModel (MVVM) yang mengelola pencarian kota via Geocoding API
/// serta pengelolaan daftar Lokasi Favorit dan Riwayat Pencarian di Local Storage.
class LocationViewModel extends ChangeNotifier {
  static const int _maxHistoryItems = 10;

  final WeatherApiService _apiService;
  final LocalStorageService _storageService;

  SearchViewState _searchState = SearchViewState.idle;
  List<LocationModel> _searchResults = [];
  List<LocationModel> _favorites = [];
  List<LocationModel> _searchHistory = [];
  String _lastQuery = '';
  String? _errorMessage;

  LocationViewModel({
    required this._apiService,
    required this._storageService,
  }) {
    loadSavedLocations();
  }

  SearchViewState get searchState => _searchState;
  List<LocationModel> get searchResults => List.unmodifiable(_searchResults);
  List<LocationModel> get favorites => List.unmodifiable(_favorites);
  List<LocationModel> get searchHistory => List.unmodifiable(_searchHistory);
  String get lastQuery => _lastQuery;
  String? get errorMessage => _errorMessage;

  /// Memuat ulang daftar favorit dan riwayat pencarian dari Local Storage.
  void loadSavedLocations() {
    _favorites = _storageService.getFavorites();
    _searchHistory = _storageService.getSearchHistory();
    notifyListeners();
  }

  /// Mencari daftar kota ke Open-Meteo Geocoding API berdasarkan [query].
  Future<void> searchCities(String query) async {
    final trimmed = query.trim();
    _lastQuery = trimmed;

    if (trimmed.isEmpty) {
      _searchState = SearchViewState.idle;
      _searchResults = [];
      _errorMessage = null;
      notifyListeners();
      return;
    }

    _searchState = SearchViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _apiService.searchLocations(trimmed);
      // Cegah race condition jika pengguna sudah mengetik query baru
      if (_lastQuery != trimmed) return;

      _searchResults = results;
      _searchState =
          results.isEmpty ? SearchViewState.empty : SearchViewState.loaded;
    } on WeatherApiException catch (e) {
      if (_lastQuery != trimmed) return;
      _errorMessage = e.message;
      _searchState = SearchViewState.error;
    } catch (_) {
      if (_lastQuery != trimmed) return;
      _errorMessage = 'Terjadi kesalahan saat mencari lokasi.';
      _searchState = SearchViewState.error;
    }

    notifyListeners();
  }

  /// Mengulang pencarian terakhir (digunakan oleh tombol "Coba Lagi" saat error).
  Future<void> retrySearch() async {
    if (_lastQuery.isNotEmpty) {
      await searchCities(_lastQuery);
    }
  }

  /// Mengosongkan hasil pencarian dan mengembalikan state ke `idle`.
  void clearSearch() {
    _lastQuery = '';
    _searchResults = [];
    _errorMessage = null;
    _searchState = SearchViewState.idle;
    notifyListeners();
  }

  /// Mengecek apakah [location] sudah tersimpan di daftar favorit.
  bool isFavorite(LocationModel location) {
    return _favorites.contains(location);
  }

  /// Menambah atau menghapus [location] dari daftar favorit dan menyimpannya
  /// secara permanen ke `SharedPreferences`.
  Future<void> toggleFavorite(LocationModel location) async {
    final updated = List<LocationModel>.from(_favorites);
    if (updated.contains(location)) {
      updated.remove(location);
    } else {
      updated.insert(0, location);
    }
    _favorites = updated;
    await _storageService.saveFavorites(_favorites);
    notifyListeners();
  }

  /// Menambahkan [location] ke paling atas Riwayat Pencarian (maksimal 10 item).
  Future<void> addToHistory(LocationModel location) async {
    final updated = List<LocationModel>.from(_searchHistory)
      ..remove(location)
      ..insert(0, location);

    if (updated.length > _maxHistoryItems) {
      updated.removeRange(_maxHistoryItems, updated.length);
    }

    _searchHistory = updated;
    await _storageService.saveSearchHistory(_searchHistory);
    notifyListeners();
  }

  /// Menghapus seluruh riwayat pencarian dari memori dan Local Storage.
  Future<void> clearHistory() async {
    _searchHistory = [];
    await _storageService.saveSearchHistory(_searchHistory);
    notifyListeners();
  }
}

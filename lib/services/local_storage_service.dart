import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_model.dart';

/// Service penyimpanan lokal berbasis `SharedPreferences`.
/// Menyimpan:
/// 1. Lokasi terakhir yang dipilih (`last_selected_location`)
/// 2. Daftar lokasi favorit (`favorite_locations`)
/// 3. Riwayat pencarian lokasi (`search_history`)
class LocalStorageService {
  static const String _lastLocationKey = 'last_selected_location';
  static const String _favoritesKey = 'favorite_locations';
  static const String _historyKey = 'search_history';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  /// Factory async untuk menginisialisasi `SharedPreferences` saat aplikasi mulai.
  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  /// Menyimpan lokasi terakhir yang dipilih dalam bentuk JSON string.
  Future<void> saveLastLocation(LocationModel location) async {
    await _prefs.setString(_lastLocationKey, jsonEncode(location.toJson()));
  }

  /// Membaca lokasi terakhir yang dipilih dari `SharedPreferences`.
  LocationModel? getLastLocation() {
    final raw = _prefs.getString(_lastLocationKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return LocationModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Menyimpan daftar lokasi favorit.
  Future<void> saveFavorites(List<LocationModel> favorites) async {
    await _writeLocationList(_favoritesKey, favorites);
  }

  /// Memuat daftar lokasi favorit.
  List<LocationModel> getFavorites() {
    return _readLocationList(_favoritesKey);
  }

  /// Menyimpan daftar riwayat pencarian.
  Future<void> saveSearchHistory(List<LocationModel> history) async {
    await _writeLocationList(_historyKey, history);
  }

  /// Memuat daftar riwayat pencarian.
  List<LocationModel> getSearchHistory() {
    return _readLocationList(_historyKey);
  }

  /// Helper internal untuk serialisasi `List<LocationModel>` -> JSON string.
  Future<void> _writeLocationList(
    String key,
    List<LocationModel> locations,
  ) async {
    final encoded = jsonEncode(locations.map((e) => e.toJson()).toList());
    await _prefs.setString(key, encoded);
  }

  /// Helper internal untuk deserialisasi JSON string -> `List<LocationModel>`.
  List<LocationModel> _readLocationList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(LocationModel.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

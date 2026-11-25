import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/location_model.dart';
import '../models/weather_model.dart';

/// Exception khusus untuk kesalahan komunikasi atau parsing dari Open-Meteo API.
class WeatherApiException implements Exception {
  final String message;

  const WeatherApiException(this.message);

  @override
  String toString() => message;
}

/// Service yang bertanggung jawab melakukan request HTTP GET langsung ke Open-Meteo REST API:
/// 1. Geocoding API untuk pencarian kota.
/// 2. Weather Forecast API untuk data cuaca terkini & prakiraan harian.
class WeatherApiService {
  static const String _geocodingHost = 'geocoding-api.open-meteo.com';
  static const String _forecastHost = 'api.open-meteo.com';
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;

  WeatherApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Mencari kota berdasarkan kata kunci [query] menggunakan Open-Meteo Geocoding API.
  Future<List<LocationModel>> searchLocations(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final uri = Uri.https(_geocodingHost, '/v1/search', {
      'name': trimmed,
      'count': '10',
      'language': 'id',
      'format': 'json',
    });

    final jsonMap = await _getJson(uri);
    final results = jsonMap['results'] as List<dynamic>?;
    if (results == null || results.isEmpty) {
      return [];
    }

    return results
        .whereType<Map<String, dynamic>>()
        .map(LocationModel.fromJson)
        .toList();
  }

  /// Mengambil data cuaca terkini (`current`) dan prakiraan harian (`daily`)
  /// berdasarkan koordinat [latitude] dan [longitude].
  Future<WeatherModel> fetchWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https(_forecastHost, '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'timezone': 'auto',
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
    });

    final jsonMap = await _getJson(uri);
    return WeatherModel.fromJson(jsonMap);
  }

  /// Helper terpusat untuk eksekusi `http.get`, validasi status HTTP, dan decode JSON.
  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode != 200) {
        throw WeatherApiException(
          'Server mengembalikan kode status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const WeatherApiException(
          'Format respons API tidak sesuai (bukan JSON object).',
        );
      }
      return decoded;
    } on SocketException {
      throw const WeatherApiException(
        'Tidak ada koneksi internet. Periksa jaringan Anda lalu coba lagi.',
      );
    } on TimeoutException {
      throw const WeatherApiException(
        'Permintaan ke server melebihi batas waktu. Silakan coba lagi.',
      );
    } on FormatException {
      throw const WeatherApiException(
        'Gagal membaca format data JSON dari server.',
      );
    } on http.ClientException catch (e) {
      throw WeatherApiException('Gagal menghubungi server: ${e.message}');
    }
  }
}

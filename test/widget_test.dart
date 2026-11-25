import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cuaca_app/main.dart';
import 'package:cuaca_app/models/location_model.dart';
import 'package:cuaca_app/models/weather_model.dart';
import 'package:cuaca_app/services/local_storage_service.dart';
import 'package:cuaca_app/services/weather_api_service.dart';
import 'package:cuaca_app/utils/weather_code_helper.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Model & Helper Tests', () {
    test('LocationModel fromJson & toJson bekerja dengan benar', () {
      final json = {
        'id': 1650357,
        'name': 'Bandung',
        'admin1': 'Jawa Barat',
        'country': 'Indonesia',
        'latitude': -6.9175,
        'longitude': 107.6191,
      };

      final location = LocationModel.fromJson(json);
      expect(location.name, 'Bandung');
      expect(location.subtitle, 'Jawa Barat, Indonesia');
      expect(location.toJson()['latitude'], -6.9175);
    });

    test('WeatherModel.fromJson memparsing data current dan daily Open-Meteo',
        () {
      final apiJson = {
        'latitude': -6.2,
        'longitude': 106.8,
        'timezone': 'Asia/Jakarta',
        'current': {
          'time': '2026-11-25T17:00',
          'temperature_2m': 29.4,
          'relative_humidity_2m': 78,
          'apparent_temperature': 33.1,
          'precipitation': 0.5,
          'weather_code': 61,
          'wind_speed_10m': 11.2,
        },
        'daily': {
          'time': ['2026-11-25', '2026-11-26'],
          'weather_code': [61, 2],
          'temperature_2m_max': [31.0, 32.5],
          'temperature_2m_min': [24.0, 23.8],
          'precipitation_probability_max': [80, 30],
        },
      };

      final weather = WeatherModel.fromJson(apiJson);
      expect(weather.current.temperature2m, 29.4);
      expect(weather.current.weatherCode, 61);
      expect(weather.todayPrecipitationProbability, 80);
      expect(weather.daily.length, 2);
      expect(weather.daily[1].temperature2mMax, 32.5);
    });

    test('WeatherCodeHelper mengembalikan deskripsi Indonesia & ikon valid', () {
      expect(WeatherCodeHelper.getDescription(0), 'Cerah');
      expect(WeatherCodeHelper.getDescription(95), 'Badai Petir');
      expect(WeatherCodeHelper.getIcon(0), Icons.wb_sunny_rounded);
    });
  });

  group('Service Tests', () {
    test('WeatherApiService searchLocations & fetchWeather memanggil endpoint dengan benar',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'geocoding-api.open-meteo.com') {
          expect(request.url.queryParameters['name'], 'Bandung');
          expect(request.url.queryParameters['count'], '10');
          expect(request.url.queryParameters['language'], 'id');
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 1650357,
                  'name': 'Bandung',
                  'admin1': 'Jawa Barat',
                  'country': 'Indonesia',
                  'latitude': -6.9175,
                  'longitude': 107.6191,
                },
              ],
            }),
            200,
          );
        }

        if (request.url.host == 'api.open-meteo.com') {
          return http.Response(
            jsonEncode({
              'latitude': -6.9175,
              'longitude': 107.6191,
              'timezone': 'Asia/Jakarta',
              'current': {
                'time': '2026-11-25T17:00',
                'temperature_2m': 24.5,
                'relative_humidity_2m': 82,
                'apparent_temperature': 26.0,
                'precipitation': 0.0,
                'weather_code': 2,
                'wind_speed_10m': 8.4,
              },
              'daily': {
                'time': ['2026-11-25'],
                'weather_code': [2],
                'temperature_2m_max': [28.0],
                'temperature_2m_min': [19.5],
                'precipitation_probability_max': [45],
              },
            }),
            200,
          );
        }

        return http.Response('Not Found', 404);
      });

      final api = WeatherApiService(client: mockClient);
      final locations = await api.searchLocations('Bandung');
      expect(locations.length, 1);
      expect(locations.first.name, 'Bandung');

      final weather = await api.fetchWeather(
        latitude: locations.first.latitude,
        longitude: locations.first.longitude,
      );
      expect(weather.current.temperature2m, 24.5);
      expect(weather.daily.first.precipitationProbabilityMax, 45);
    });

    test('LocalStorageService menyimpan & memuat favorit, riwayat, dan lokasi terakhir',
        () async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorageService.create();
      const yogyakarta = LocationModel(
        id: 1621177,
        name: 'Yogyakarta',
        admin1: 'Daerah Istimewa Yogyakarta',
        country: 'Indonesia',
        latitude: -7.7956,
        longitude: 110.3695,
      );

      await storage.saveLastLocation(yogyakarta);
      await storage.saveFavorites([yogyakarta]);
      await storage.saveSearchHistory([yogyakarta]);

      expect(storage.getLastLocation()?.name, 'Yogyakarta');
      expect(storage.getFavorites().length, 1);
      expect(storage.getSearchHistory().first.name, 'Yogyakarta');
    });
  });

  group('Widget Integration Tests', () {
    testWidgets('HomeScreen menampilkan cuaca dari API dan dapat membuka SearchScreen',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await LocalStorageService.create();

      final mockClient = MockClient((request) async {
        if (request.url.host == 'geocoding-api.open-meteo.com') {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'id': 1650357,
                  'name': 'Bandung',
                  'admin1': 'Jawa Barat',
                  'country': 'Indonesia',
                  'latitude': -6.9175,
                  'longitude': 107.6191,
                },
              ],
            }),
            200,
          );
        }
        if (request.url.host == 'api.open-meteo.com') {
          final isBandung = request.url.queryParameters['latitude'] == '-6.9175';
          return http.Response(
            jsonEncode({
              'latitude': isBandung ? -6.9175 : -6.2088,
              'longitude': isBandung ? 107.6191 : 106.8456,
              'timezone': 'Asia/Jakarta',
              'current': {
                'time': '2026-11-25T17:00',
                'temperature_2m': isBandung ? 23.0 : 30.0,
                'relative_humidity_2m': 75,
                'apparent_temperature': 34.0,
                'precipitation': 0.2,
                'weather_code': 1,
                'wind_speed_10m': 12.0,
              },
              'daily': {
                'time': ['2026-11-25', '2026-11-26'],
                'weather_code': [1, 61],
                'temperature_2m_max': [33.0, 30.0],
                'temperature_2m_min': [25.0, 24.0],
                'precipitation_probability_max': [20, 75],
              },
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'results': []}), 200);
      });

      final api = WeatherApiService(client: mockClient);

      await tester.pumpWidget(
        CuacaApp(apiService: api, storageService: storage),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jakarta'), findsWidgets);
      expect(find.text('30°C'), findsOneWidget);
      expect(find.text('Umumnya Cerah'), findsWidgets);
      expect(find.text('Detail Cuaca'), findsOneWidget);
      expect(find.text('Prakiraan Beberapa Hari ke Depan'), findsOneWidget);

      await tester.tap(find.byTooltip('Cari Kota'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Lokasi'), findsOneWidget);
      expect(find.text('Lokasi Favorit'), findsOneWidget);
      expect(find.text('Belum Ada Lokasi Favorit'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Bandung');
      await tester.tap(find.text('Cari'));
      await tester.pumpAndSettle();

      expect(find.text('Jawa Barat, Indonesia'), findsOneWidget);
      await tester.tap(find.byTooltip('Simpan ke favorit'));
      await tester.pumpAndSettle();

      expect(storage.getFavorites().first.name, 'Bandung');

      await tester.tap(find.text('Jawa Barat, Indonesia'));
      await tester.pumpAndSettle();

      expect(find.text('23°C'), findsOneWidget);
      expect(storage.getLastLocation()?.name, 'Bandung');
    });
  });
}

import 'package:flutter/material.dart';

/// Menyimpan hasil pemetaan WMO `weather_code` berupa deskripsi bahasa Indonesia,
/// ikon Material, dan warna aksen visual.
class WeatherCodeInfo {
  final String description;
  final IconData icon;
  final Color accentColor;

  const WeatherCodeInfo({
    required this.description,
    required this.icon,
    required this.accentColor,
  });
}

/// Helper untuk mengonversi kode cuaca standar WMO (World Meteorological Organization)
/// yang dikembalikan Open-Meteo menjadi teks bahasa Indonesia dan ikon cuaca.
class WeatherCodeHelper {
  WeatherCodeHelper._();

  static const WeatherCodeInfo _fallbackInfo = WeatherCodeInfo(
    description: 'Cuaca Tidak Diketahui',
    icon: Icons.wb_cloudy_outlined,
    accentColor: Color(0xFF64748B),
  );

  // Tabel pemetaan WMO weather_code -> deskripsi Indonesia, ikon, & warna aksen.
  static const Map<int, WeatherCodeInfo> _codeMap = {
    0: WeatherCodeInfo(
      description: 'Cerah',
      icon: Icons.wb_sunny_rounded,
      accentColor: Color(0xFFF59E0B),
    ),
    1: WeatherCodeInfo(
      description: 'Umumnya Cerah',
      icon: Icons.wb_sunny_outlined,
      accentColor: Color(0xFFF59E0B),
    ),
    2: WeatherCodeInfo(
      description: 'Berawan Sebagian',
      icon: Icons.cloud_queue_rounded,
      accentColor: Color(0xFF0EA5E9),
    ),
    3: WeatherCodeInfo(
      description: 'Mendung',
      icon: Icons.cloud_rounded,
      accentColor: Color(0xFF64748B),
    ),
    45: WeatherCodeInfo(
      description: 'Berkabut',
      icon: Icons.foggy,
      accentColor: Color(0xFF94A3B8),
    ),
    48: WeatherCodeInfo(
      description: 'Kabut Tebal Membeku',
      icon: Icons.foggy,
      accentColor: Color(0xFF94A3B8),
    ),
    51: WeatherCodeInfo(
      description: 'Gerimis Ringan',
      icon: Icons.grain_rounded,
      accentColor: Color(0xFF38BDF8),
    ),
    53: WeatherCodeInfo(
      description: 'Gerimis Sedang',
      icon: Icons.grain_rounded,
      accentColor: Color(0xFF0284C7),
    ),
    55: WeatherCodeInfo(
      description: 'Gerimis Lebat',
      icon: Icons.grain_rounded,
      accentColor: Color(0xFF0369A1),
    ),
    56: WeatherCodeInfo(
      description: 'Gerimis Beku Ringan',
      icon: Icons.ac_unit_rounded,
      accentColor: Color(0xFF0EA5E9),
    ),
    57: WeatherCodeInfo(
      description: 'Gerimis Beku Lebat',
      icon: Icons.ac_unit_rounded,
      accentColor: Color(0xFF0284C7),
    ),
    61: WeatherCodeInfo(
      description: 'Hujan Ringan',
      icon: Icons.water_drop_outlined,
      accentColor: Color(0xFF3B82F6),
    ),
    63: WeatherCodeInfo(
      description: 'Hujan Sedang',
      icon: Icons.water_drop_rounded,
      accentColor: Color(0xFF2563EB),
    ),
    65: WeatherCodeInfo(
      description: 'Hujan Lebat',
      icon: Icons.beach_access_rounded,
      accentColor: Color(0xFF1D4ED8),
    ),
    66: WeatherCodeInfo(
      description: 'Hujan Beku Ringan',
      icon: Icons.ac_unit_rounded,
      accentColor: Color(0xFF38BDF8),
    ),
    67: WeatherCodeInfo(
      description: 'Hujan Beku Lebat',
      icon: Icons.ac_unit_rounded,
      accentColor: Color(0xFF0284C7),
    ),
    71: WeatherCodeInfo(
      description: 'Salju Ringan',
      icon: Icons.cloudy_snowing,
      accentColor: Color(0xFF7DD3FC),
    ),
    73: WeatherCodeInfo(
      description: 'Salju Sedang',
      icon: Icons.cloudy_snowing,
      accentColor: Color(0xFF38BDF8),
    ),
    75: WeatherCodeInfo(
      description: 'Salju Lebat',
      icon: Icons.ac_unit_rounded,
      accentColor: Color(0xFF0EA5E9),
    ),
    77: WeatherCodeInfo(
      description: 'Butiran Salju',
      icon: Icons.ac_unit_rounded,
      accentColor: Color(0xFF38BDF8),
    ),
    80: WeatherCodeInfo(
      description: 'Hujan Lokal Ringan',
      icon: Icons.umbrella_rounded,
      accentColor: Color(0xFF3B82F6),
    ),
    81: WeatherCodeInfo(
      description: 'Hujan Lokal Sedang',
      icon: Icons.umbrella_rounded,
      accentColor: Color(0xFF2563EB),
    ),
    82: WeatherCodeInfo(
      description: 'Hujan Lokal Deras',
      icon: Icons.thunderstorm_outlined,
      accentColor: Color(0xFF1E40AF),
    ),
    85: WeatherCodeInfo(
      description: 'Hujan Salju Ringan',
      icon: Icons.cloudy_snowing,
      accentColor: Color(0xFF38BDF8),
    ),
    86: WeatherCodeInfo(
      description: 'Hujan Salju Lebat',
      icon: Icons.cloudy_snowing,
      accentColor: Color(0xFF0284C7),
    ),
    95: WeatherCodeInfo(
      description: 'Badai Petir',
      icon: Icons.thunderstorm_rounded,
      accentColor: Color(0xFF6366F1),
    ),
    96: WeatherCodeInfo(
      description: 'Badai Petir & Hujan Es Ringan',
      icon: Icons.thunderstorm_rounded,
      accentColor: Color(0xFF4F46E5),
    ),
    99: WeatherCodeInfo(
      description: 'Badai Petir & Hujan Es Lebat',
      icon: Icons.thunderstorm_rounded,
      accentColor: Color(0xFF4338CA),
    ),
  };

  /// Mengambil informasi lengkap berdasarkan WMO `weather_code`.
  static WeatherCodeInfo getInfo(int weatherCode) {
    return _codeMap[weatherCode] ?? _fallbackInfo;
  }

  /// Mengambil deskripsi singkat cuaca berbahasa Indonesia.
  static String getDescription(int weatherCode) {
    return getInfo(weatherCode).description;
  }

  /// Mengambil ikon cuaca Material berdasarkan WMO `weather_code`.
  static IconData getIcon(int weatherCode) {
    return getInfo(weatherCode).icon;
  }
}

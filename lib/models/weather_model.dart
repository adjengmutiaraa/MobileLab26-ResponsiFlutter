/// Model data cuaca saat ini (`current`) dari Open-Meteo Forecast API.
class CurrentWeather {
  final String time;
  final double temperature2m;
  final int relativeHumidity2m;
  final double apparentTemperature;
  final double precipitation;
  final int weatherCode;
  final double windSpeed10m;

  const CurrentWeather({
    required this.time,
    required this.temperature2m,
    required this.relativeHumidity2m,
    required this.apparentTemperature,
    required this.precipitation,
    required this.weatherCode,
    required this.windSpeed10m,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      time: json['time'] as String? ?? '',
      temperature2m: (json['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      relativeHumidity2m: (json['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      apparentTemperature:
          (json['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      precipitation: (json['precipitation'] as num?)?.toDouble() ?? 0.0,
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
      windSpeed10m: (json['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'temperature_2m': temperature2m,
      'relative_humidity_2m': relativeHumidity2m,
      'apparent_temperature': apparentTemperature,
      'precipitation': precipitation,
      'weather_code': weatherCode,
      'wind_speed_10m': windSpeed10m,
    };
  }
}

/// Model satu baris prakiraan cuaca harian (`daily`) dari Open-Meteo Forecast API.
class DailyForecast {
  final String date;
  final int weatherCode;
  final double temperature2mMax;
  final double temperature2mMin;
  final int precipitationProbabilityMax;

  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.temperature2mMax,
    required this.temperature2mMin,
    required this.precipitationProbabilityMax,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> json) {
    return DailyForecast(
      date: json['date'] as String? ?? '',
      weatherCode: (json['weather_code'] as num?)?.toInt() ?? 0,
      temperature2mMax:
          (json['temperature_2m_max'] as num?)?.toDouble() ?? 0.0,
      temperature2mMin:
          (json['temperature_2m_min'] as num?)?.toDouble() ?? 0.0,
      precipitationProbabilityMax:
          (json['precipitation_probability_max'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'weather_code': weatherCode,
      'temperature_2m_max': temperature2mMax,
      'temperature_2m_min': temperature2mMin,
      'precipitation_probability_max': precipitationProbabilityMax,
    };
  }
}

/// Model utama gabungan cuaca terkini dan daftar prakiraan harian.
class WeatherModel {
  final double latitude;
  final double longitude;
  final String timezone;
  final CurrentWeather current;
  final List<DailyForecast> daily;
  final DateTime fetchedAt;

  const WeatherModel({
    required this.latitude,
    required this.longitude,
    required this.timezone,
    required this.current,
    required this.daily,
    required this.fetchedAt,
  });

  /// Peluang hujan maksimum hari ini (diambil dari item pertama prakiraan harian).
  int get todayPrecipitationProbability =>
      daily.isNotEmpty ? daily.first.precipitationProbabilityMax : 0;

  /// Parsing JSON Open-Meteo Forecast API.
  /// Open-Meteo mengembalikan data `daily` dalam bentuk array paralel per atribut,
  /// sehingga kita menggabungkannya menjadi `List<DailyForecast>`.
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    final currentMap = json['current'] as Map<String, dynamic>? ?? {};
    final dailyMap = json['daily'] as Map<String, dynamic>? ?? {};

    final dates = (dailyMap['time'] as List<dynamic>? ?? []).cast<String>();
    final codes = (dailyMap['weather_code'] as List<dynamic>? ?? []);
    final maxTemps = (dailyMap['temperature_2m_max'] as List<dynamic>? ?? []);
    final minTemps = (dailyMap['temperature_2m_min'] as List<dynamic>? ?? []);
    final precipProbs =
        (dailyMap['precipitation_probability_max'] as List<dynamic>? ?? []);

    final dailyList = List<DailyForecast>.generate(dates.length, (i) {
      return DailyForecast(
        date: dates[i],
        weatherCode: i < codes.length ? (codes[i] as num?)?.toInt() ?? 0 : 0,
        temperature2mMax:
            i < maxTemps.length ? (maxTemps[i] as num?)?.toDouble() ?? 0.0 : 0.0,
        temperature2mMin:
            i < minTemps.length ? (minTemps[i] as num?)?.toDouble() ?? 0.0 : 0.0,
        precipitationProbabilityMax: i < precipProbs.length
            ? (precipProbs[i] as num?)?.toInt() ?? 0
            : 0,
      );
    });

    return WeatherModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      timezone: json['timezone'] as String? ?? 'auto',
      current: CurrentWeather.fromJson(currentMap),
      daily: dailyList,
      fetchedAt: json['fetched_at'] != null
          ? DateTime.tryParse(json['fetched_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Konversi model lengkap kembali ke JSON.
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'current': current.toJson(),
      'daily': {
        'time': daily.map((e) => e.date).toList(),
        'weather_code': daily.map((e) => e.weatherCode).toList(),
        'temperature_2m_max': daily.map((e) => e.temperature2mMax).toList(),
        'temperature_2m_min': daily.map((e) => e.temperature2mMin).toList(),
        'precipitation_probability_max':
            daily.map((e) => e.precipitationProbabilityMax).toList(),
      },
      'fetched_at': fetchedAt.toIso8601String(),
    };
  }
}

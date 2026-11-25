/// Model data lokasi/kota yang diperoleh dari Open-Meteo Geocoding API
/// dan disimpan ke Local Storage (`SharedPreferences`).
class LocationModel {
  final int? id;
  final String name;
  final String? admin1;
  final String? country;
  final double latitude;
  final double longitude;

  const LocationModel({
    this.id,
    required this.name,
    this.admin1,
    this.country,
    required this.latitude,
    required this.longitude,
  });

  /// Lokasi awal default saat aplikasi pertama kali dibuka
  /// dan belum ada lokasi tersimpan di Local Storage.
  static const LocationModel defaultLocation = LocationModel(
    id: 1642911,
    name: 'Jakarta',
    admin1: 'Daerah Khusus Ibukota Jakarta',
    country: 'Indonesia',
    latitude: -6.2088,
    longitude: 106.8456,
  );

  /// Parsing JSON dari respons Open-Meteo Geocoding API atau Local Storage.
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String? ?? 'Tidak Diketahui',
      admin1: json['admin1'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  /// Konversi objek Dart ke Map JSON untuk disimpan ke Local Storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'admin1': admin1,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  /// Menggabungkan nama wilayah (`admin1`) dan negara (`country`) untuk tampilan UI.
  String get subtitle {
    final parts = <String>[
      if (admin1 != null && admin1!.trim().isNotEmpty) admin1!.trim(),
      if (country != null && country!.trim().isNotEmpty) country!.trim(),
    ];
    return parts.join(', ');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LocationModel) return false;
    if (id != null && other.id != null) {
      return id == other.id;
    }
    return name == other.name &&
        latitude.toStringAsFixed(4) == other.latitude.toStringAsFixed(4) &&
        longitude.toStringAsFixed(4) == other.longitude.toStringAsFixed(4);
  }

  @override
  int get hashCode {
    if (id != null) return id.hashCode;
    return Object.hash(
      name,
      latitude.toStringAsFixed(4),
      longitude.toStringAsFixed(4),
    );
  }
}

# Aplikasi Cuaca Flutter (Open-Meteo + MVVM)

Aplikasi cuaca berbasis **Flutter (Dart)** dengan desain **Material Design 3** dan arsitektur **Model-View-ViewModel (MVVM)**. Seluruh data cuaca dan pencarian kota diambil menggunakan **Open-Meteo REST API** dan mendukung penyimpanan **Lokasi Favorit**, **Riwayat Pencarian**, dan **Lokasi Terakhir** menggunakan `SharedPreferences`.

---

## Screenshot Aplikasi

| Home Screen (Cuaca Terkini & Prakiraan) | Search Screen (Cari Kota, Favorit & Riwayat) |
| :---: | :---: |
| ![Home Screen](screenshots/home.png) | ![Search Screen](screenshots/search.png) |

---

## Fitur Utama

- **Informasi Cuaca Terkini (Home Screen):** Menampilkan nama kota, tanggal, jam pembaruan, suhu saat ini, ikon & deskripsi cuaca berbahasa Indonesia (berdasarkan WMO `weather_code`), serta suhu minimum/maksimum hari ini.
- **Kartu Detail Cuaca Responsif:** Menampilkan suhu terasa (`apparent_temperature`), kelembapan (`relative_humidity_2m`), kecepatan angin (`wind_speed_10m`), curah hujan (`precipitation`), dan peluang hujan hari ini (`precipitation_probability_max`) menggunakan layout responsif.
- **Prakiraan Harian:** Daftar prakiraan beberapa hari ke depan lengkap dengan ikon cuaca, deskripsi, peluang hujan maksimum, serta suhu min/maks.
- **Pencarian Kota Real-Time (Search Screen):** Pencarian kota menggunakan Open-Meteo Geocoding API dengan mekanisme *debounce* (500 ms) maupun tombol **Cari**.
- **Favorit & Riwayat Pencarian Persisten:** Pengguna dapat menandai kota sebagai favorit dan melihat riwayat pencarian (maksimal 10 item terakhir). Lokasi terakhir yang dipilih otomatis dimuat kembali saat aplikasi dibuka ulang.
- **Penanganan State Lengkap:** Mendukung tampilan **Loading** (animasi skeleton + indikator), **Empty** (hasil pencarian kosong / belum ada favorit), dan **Error** (pesan kesalahan jaringan/API disertai tombol **Coba Lagi**).

---

## Struktur Folder Proyek

```text
lib/
├── main.dart                         # Entry point aplikasi, inisialisasi intl, LocalStorageService, & MultiProvider
├── models/                           # Struktur data Dart beserta parsing JSON (fromJson & toJson)
│   ├── location_model.dart           # Model kota/lokasi (nama, wilayah, negara, latitude, longitude)
│   └── weather_model.dart            # Model cuaca saat ini (CurrentWeather) & prakiraan harian (DailyForecast)
├── services/                         # Komunikasi eksternal (REST API) & penyimpanan lokal
│   ├── weather_api_service.dart      # HTTP GET ke Open-Meteo Geocoding & Forecast API
│   └── local_storage_service.dart    # Baca/tulis JSON ke SharedPreferences (favorit, riwayat, lokasi terakhir)
├── viewmodels/                       # Pengelola state & logika bisnis (ChangeNotifier)
│   ├── weather_viewmodel.dart        # State cuaca Home Screen (initial, loading, loaded, error)
│   └── location_viewmodel.dart       # State pencarian kota, daftar favorit, & riwayat pencarian
├── views/                            # Halaman utama (Screen) aplikasi
│   ├── home_screen.dart              # Screen 1: Tampilan cuaca kota terpilih & tombol navigasi/refresh
│   └── search_screen.dart            # Screen 2: Pencarian kota, daftar favorit, & riwayat pencarian
├── widgets/                          # Komponen UI modular yang dapat digunakan ulang
│   ├── current_weather_card.dart     # Kartu ringkasan cuaca utama
│   ├── weather_detail_grid.dart      # Grid responsif 5 metrik detail cuaca
│   ├── daily_forecast_list.dart      # Daftar prakiraan harian
│   ├── location_list_tile.dart       # Item baris kota untuk hasil pencarian, favorit, & riwayat
│   └── state_feedback_widget.dart    # Widget Loading shimmer, Empty state, & Error state ("Coba Lagi")
├── theme/                            # Konfigurasi tampilan global Material Design 3
│   └── app_theme.dart                # ColorScheme, CardThemeData, InputDecorationTheme, & TextTheme
└── utils/                            # Fungsi pembantu (helper)
    ├── weather_code_helper.dart      # Konversi WMO weather_code ke deskripsi Indonesia, ikon, & warna aksen
    └── date_formatter.dart           # Pemformatan tanggal & waktu berbahasa Indonesia (intl)
```

---

## Penerapan Arsitektur MVVM

Aplikasi memisahkan tanggung jawab antara tampilan (**View**), pengelola state (**ViewModel**), sumber data (**Service**), dan struktur data (**Model**) menggunakan package `provider` (`ChangeNotifier` + `Consumer`):

```text
┌───────────────────┐     memanggil aksi      ┌────────────────────────┐
│       View        │ ──────────────────────► │       ViewModel        │
│ (Home/Search)     │                         │   (ChangeNotifier)     │
│                   │ ◄────────────────────── │                        │
└───────────────────┘   notifyListeners()     └───────────┬────────────┘
                                                          │ request data / simpan
                                                          ▼
┌───────────────────┐     parsing JSON        ┌────────────────────────┐
│       Model       │ ◄────────────────────── │        Service         │
│ (Weather/Location)│                         │ (HTTP GET / SharedPref)│
└───────────────────┘                         └────────────────────────┘
```

1. **View (`HomeScreen` / `SearchScreen`):** Hanya merender UI berdasarkan state terkini dan memicu method pada ViewModel (misalnya `initialize()`, `refreshWeather()`, `searchCities()`, `loadWeatherForLocation()`).
2. **ViewModel (`WeatherViewModel` / `LocationViewModel`):** Mengatur state (`loading`, `loaded`, `empty`, `error`), memanggil `WeatherApiService` atau `LocalStorageService`, lalu memanggil `notifyListeners()` agar UI otomatis diperbarui.
3. **Service (`WeatherApiService` / `LocalStorageService`):** Mengisolasi detail HTTP request (`http.get`) dan penyimpanan lokal (`SharedPreferences`).
4. **Model (`WeatherModel` / `LocationModel`):** Mengubah respons JSON mentah menjadi objek Dart yang *type-safe* melalui `fromJson()` dan `toJson()`.

---

## Dokumentasi Open-Meteo REST API

Aplikasi menggunakan `http.get` secara langsung melalui `WeatherApiService` (`lib/services/weather_api_service.dart`).

### 1. Geocoding API (Pencarian Kota)

- **Endpoint:** `https://geocoding-api.open-meteo.com/v1/search`
- **Parameter Query:**
  - `name`: Kata kunci nama kota yang diketik pengguna
  - `count`: `10` (maksimal 10 hasil)
  - `language`: `id`
  - `format`: `json`
- **Pemetaan Field JSON (`results[]`) -> `LocationModel` -> UI:**

| Field JSON | Properti Model | Penggunaan di UI |
| :--- | :--- | :--- |
| `id` | `LocationModel.id` | Identitas unik kota untuk pencocokan favorit/riwayat |
| `name` | `LocationModel.name` | Judul kota di `HomeScreen` AppBar, `CurrentWeatherCard`, & `LocationListTile` |
| `admin1` | `LocationModel.admin1` | Subjudul wilayah/provinsi pada `LocationModel.subtitle` |
| `country` | `LocationModel.country` | Subjudul negara pada `LocationModel.subtitle` |
| `latitude` | `LocationModel.latitude` | Parameter koordinat untuk Forecast API |
| `longitude` | `LocationModel.longitude` | Parameter koordinat untuk Forecast API |

### 2. Weather Forecast API (Data Cuaca & Prakiraan)

- **Endpoint:** `https://api.open-meteo.com/v1/forecast`
- **Parameter Query:**
  - `latitude` & `longitude`: Koordinat kota terpilih
  - `timezone`: `auto`
  - `current`: `temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m`
  - `daily`: `weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max`
- **Pemetaan Field JSON -> `WeatherModel` -> UI:**

| Bagian & Field JSON | Properti Model | Penggunaan di UI |
| :--- | :--- | :--- |
| `current.temperature_2m` | `CurrentWeather.temperature2m` | Suhu utama di `CurrentWeatherCard` (`°C`) |
| `current.weather_code` | `CurrentWeather.weatherCode` | Dikonversi `WeatherCodeHelper` menjadi ikon & teks cuaca Indonesia |
| `current.apparent_temperature` | `CurrentWeather.apparentTemperature` | Kartu metrik **Suhu Terasa** di `WeatherDetailGrid` |
| `current.relative_humidity_2m` | `CurrentWeather.relativeHumidity2m` | Kartu metrik **Kelembapan** (`%`) |
| `current.wind_speed_10m` | `CurrentWeather.windSpeed10m` | Kartu metrik **Kecepatan Angin** (`km/jam`) |
| `current.precipitation` | `CurrentWeather.precipitation` | Kartu metrik **Curah Hujan** (`mm`) |
| `daily.time[]` | `DailyForecast.date` | Label hari/tanggal via `DateFormatter.formatDailyLabel` di `DailyForecastList` |
| `daily.weather_code[]` | `DailyForecast.weatherCode` | Ikon & deskripsi cuaca harian |
| `daily.temperature_2m_min[]` | `DailyForecast.temperature2mMin` | Suhu minimum harian (`°`) |
| `daily.temperature_2m_max[]` | `DailyForecast.temperature2mMax` | Suhu maksimum harian (`°`) |
| `daily.precipitation_probability_max[]` | `DailyForecast.precipitationProbabilityMax` | Peluang hujan hari ini di `WeatherDetailGrid` & badge persentase harian di `DailyForecastList` |

---

## Penyimpanan Lokal (`SharedPreferences`)

Penyimpanan lokal ditangani oleh `LocalStorageService` (`lib/services/local_storage_service.dart`) dengan mengubah objek `LocationModel` menjadi JSON string melalui `toJson()` + `jsonEncode`, dan membacanya kembali dengan `jsonDecode` + `LocationModel.fromJson()`:

- **`last_selected_location`:** Menyimpan objek kota terakhir yang dipilih pengguna. Saat aplikasi dibuka ulang, `WeatherViewModel` membaca key ini (jika belum ada, menggunakan `LocationModel.defaultLocation` Jakarta) dan langsung mengambil data cuaca terbarunya dari API.
- **`favorite_locations`:** Menyimpan daftar kota favorit dalam bentuk JSON array. Diubah lewat `LocationViewModel.toggleFavorite()` saat ikon bintang ditekan.
- **`search_history`:** Menyimpan riwayat kota yang pernah dipilih (maksimal 10 lokasi terbaru) lewat `LocationViewModel.addToHistory()`, dan dapat dihapus seluruhnya melalui `clearHistory()`.

---

## Cara Menjalankan Proyek Secara Lokal

### Prasyarat
- Flutter SDK terinstal dan sudah masuk ke `PATH`
- Koneksi internet aktif (untuk mengunduh package dan mengakses Open-Meteo API)
- Emulator Android / iOS Simulator / Perangkat fisik / Browser Chrome

### Langkah-langkah

1. **Clone repository dan masuk ke direktori proyek:**
   ```bash
   git clone <url-repository-anda>
   cd responsi
   ```

2. **Unduh seluruh dependensi:**
   ```bash
   flutter pub get
   ```

3. **Jalankan analisis kode & unit/widget test (opsional, untuk verifikasi):**
   ```bash
   flutter analyze
   flutter test
   ```

4. **Jalankan aplikasi:**
   ```bash
   flutter run
   ```

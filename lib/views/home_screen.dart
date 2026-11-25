import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/location_viewmodel.dart';
import '../viewmodels/weather_viewmodel.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/daily_forecast_list.dart';
import '../widgets/state_feedback_widget.dart';
import '../widgets/weather_detail_grid.dart';
import 'search_screen.dart';

/// Screen 1: Home / Weather Screen.
/// Menggunakan `StatefulWidget` agar dapat memicu inisialisasi data cuaca sekali
/// pada `initState` saat halaman pertama kali dibuka.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Memuat cuaca untuk lokasi terakhir yang tersimpan setelah frame pertama selesai dibangun.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<WeatherViewModel>().initialize();
    });
  }

  Future<void> _openSearchScreen() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SearchScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<WeatherViewModel, LocationViewModel>(
      builder: (context, weatherVm, locationVm, _) {
        final currentLocation = weatherVm.selectedLocation;
        final isFav = locationVm.isFavorite(currentLocation);

        return Scaffold(
          appBar: AppBar(
            title: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: _openSearchScreen,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        currentLocation.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                tooltip: isFav ? 'Hapus dari Favorit' : 'Simpan ke Favorit',
                onPressed: () => locationVm.toggleFavorite(currentLocation),
                icon: Icon(
                  isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isFav ? const Color(0xFFF59E0B) : null,
                ),
              ),
              IconButton(
                tooltip: 'Cari Kota',
                onPressed: _openSearchScreen,
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                tooltip: 'Muat Ulang Cuaca',
                onPressed: weatherVm.isLoading
                    ? null
                    : () => weatherVm.refreshWeather(),
                icon: const Icon(Icons.refresh_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: _buildBody(context, weatherVm),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, WeatherViewModel weatherVm) {
    switch (weatherVm.state) {
      case WeatherViewState.initial:
      case WeatherViewState.loading:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: const WeatherLoadingWidget(),
            ),
          ),
        );

      case WeatherViewState.error:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ErrorStateWidget(
                message: weatherVm.errorMessage ??
                    'Gagal memuat data cuaca dari Open-Meteo.',
                onRetry: () => weatherVm.refreshWeather(),
              ),
            ),
          ),
        );

      case WeatherViewState.loaded:
        final weather = weatherVm.weather;
        if (weather == null) {
          return ErrorStateWidget(
            message: 'Data cuaca tidak tersedia.',
            onRetry: () => weatherVm.refreshWeather(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => weatherVm.refreshWeather(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CurrentWeatherCard(
                      location: weatherVm.selectedLocation,
                      weather: weather,
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Detail Cuaca',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    WeatherDetailGrid(weather: weather),
                    const SizedBox(height: 22),
                    Text(
                      'Prakiraan Beberapa Hari ke Depan',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    DailyForecastList(dailyForecasts: weather.daily),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }
}

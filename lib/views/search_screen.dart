import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/location_model.dart';
import '../viewmodels/location_viewmodel.dart';
import '../viewmodels/weather_viewmodel.dart';
import '../widgets/location_list_tile.dart';
import '../widgets/state_feedback_widget.dart';

/// Screen 2: Search / Location Screen.
/// Menggunakan `StatefulWidget` untuk mengelola `TextEditingController`
/// dan `Timer` debounce saat mengetik nama kota.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.read<LocationViewModel>().searchCities(value);
    });
  }

  void _submitSearch() {
    _debounce?.cancel();
    context.read<LocationViewModel>().searchCities(_searchController.text);
  }

  void _clearInput() {
    _debounce?.cancel();
    _searchController.clear();
    context.read<LocationViewModel>().clearSearch();
    setState(() {});
  }

  /// Memilih kota: menyimpan ke riwayat pencarian, memperbarui cuaca di Home Screen,
  /// dan kembali ke halaman utama.
  Future<void> _selectLocation(LocationModel location) async {
    final locationVm = context.read<LocationViewModel>();
    final weatherVm = context.read<WeatherViewModel>();

    await locationVm.addToHistory(location);
    locationVm.clearSearch();
    // Jalankan pembaruan cuaca dan segera kembali ke HomeScreen
    unawaited(weatherVm.loadWeatherForLocation(location));

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onChanged: _onSearchChanged,
                          onSubmitted: (_) => _submitSearch(),
                          decoration: InputDecoration(
                            hintText: 'Cari nama kota (mis. Bandung, Tokyo)...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    tooltip: 'Hapus teks',
                                    onPressed: _clearInput,
                                    icon: const Icon(Icons.close_rounded),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _submitSearch,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Cari'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer2<LocationViewModel, WeatherViewModel>(
                    builder: (context, locationVm, weatherVm, _) {
                      if (locationVm.searchState != SearchViewState.idle) {
                        return _buildSearchResults(
                          context,
                          locationVm,
                          weatherVm.selectedLocation,
                        );
                      }
                      return _buildSavedLists(
                        context,
                        locationVm,
                        weatherVm.selectedLocation,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    BuildContext context,
    LocationViewModel locationVm,
    LocationModel selectedLocation,
  ) {
    switch (locationVm.searchState) {
      case SearchViewState.idle:
        return const SizedBox.shrink();

      case SearchViewState.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Mencari lokasi...'),
            ],
          ),
        );

      case SearchViewState.error:
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorStateWidget(
            message: locationVm.errorMessage ??
                'Gagal mencari lokasi dari Open-Meteo.',
            onRetry: () => locationVm.retrySearch(),
          ),
        );

      case SearchViewState.empty:
        return EmptyStateWidget(
          icon: Icons.location_off_rounded,
          title: 'Kota Tidak Ditemukan',
          subtitle:
              'Tidak ada hasil untuk "${locationVm.lastQuery}". Coba periksa ejaan atau gunakan nama kota lain.',
        );

      case SearchViewState.loaded:
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: locationVm.searchResults.length,
          itemBuilder: (context, index) {
            final location = locationVm.searchResults[index];
            return LocationListTile(
              location: location,
              isFavorite: locationVm.isFavorite(location),
              isSelected: location == selectedLocation,
              onTap: () => _selectLocation(location),
              onToggleFavorite: () => locationVm.toggleFavorite(location),
            );
          },
        );
    }
  }

  Widget _buildSavedLists(
    BuildContext context,
    LocationViewModel locationVm,
    LocationModel selectedLocation,
  ) {
    final theme = Theme.of(context);
    final favorites = locationVm.favorites;
    final history = locationVm.searchHistory;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lokasi Favorit',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (favorites.isEmpty)
            const Card(
              child: EmptyStateWidget(
                icon: Icons.star_outline_rounded,
                title: 'Belum Ada Lokasi Favorit',
                subtitle:
                    'Cari nama kota lalu ketuk ikon bintang untuk menyimpannya di sini.',
              ),
            )
          else
            ...favorites.map(
              (location) => LocationListTile(
                location: location,
                isFavorite: true,
                isSelected: location == selectedLocation,
                leadingIcon: Icons.star_rounded,
                onTap: () => _selectLocation(location),
                onToggleFavorite: () => locationVm.toggleFavorite(location),
              ),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Pencarian',
                style: theme.textTheme.titleMedium,
              ),
              if (history.isNotEmpty)
                TextButton(
                  onPressed: () => locationVm.clearHistory(),
                  child: const Text('Hapus Riwayat'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const Card(
              child: EmptyStateWidget(
                icon: Icons.history_rounded,
                title: 'Belum Ada Riwayat Pencarian',
                subtitle:
                    'Kota yang baru Anda pilih dari hasil pencarian akan muncul di sini.',
              ),
            )
          else
            ...history.map(
              (location) => LocationListTile(
                location: location,
                isFavorite: locationVm.isFavorite(location),
                isSelected: location == selectedLocation,
                leadingIcon: Icons.history_rounded,
                onTap: () => _selectLocation(location),
                onToggleFavorite: () => locationVm.toggleFavorite(location),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../models/weather_model.dart';

/// Item data internal untuk membentuk kartu metrik detail cuaca secara seragam.
class _WeatherMetricItem {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _WeatherMetricItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });
}

/// Grid responsif untuk menampilkan detail informasi cuaca tambahan:
/// suhu terasa, kelembapan, kecepatan angin, curah hujan, dan peluang hujan hari ini.
class WeatherDetailGrid extends StatelessWidget {
  final WeatherModel weather;

  const WeatherDetailGrid({
    super.key,
    required this.weather,
  });

  @override
  Widget build(BuildContext context) {
    final current = weather.current;
    final metrics = <_WeatherMetricItem>[
      _WeatherMetricItem(
        label: 'Suhu Terasa',
        value: '${current.apparentTemperature.toStringAsFixed(1)} °C',
        icon: Icons.thermostat_rounded,
        iconColor: const Color(0xFFEA580C),
      ),
      _WeatherMetricItem(
        label: 'Kelembapan',
        value: '${current.relativeHumidity2m}%',
        icon: Icons.water_drop_outlined,
        iconColor: const Color(0xFF0284C7),
      ),
      _WeatherMetricItem(
        label: 'Kecepatan Angin',
        value: '${current.windSpeed10m.toStringAsFixed(1)} km/jam',
        icon: Icons.air_rounded,
        iconColor: const Color(0xFF0D9488),
      ),
      _WeatherMetricItem(
        label: 'Curah Hujan',
        value: '${current.precipitation.toStringAsFixed(1)} mm',
        icon: Icons.grain_rounded,
        iconColor: const Color(0xFF2563EB),
      ),
      _WeatherMetricItem(
        label: 'Peluang Hujan Hari Ini',
        value: '${weather.todayPrecipitationProbability}%',
        icon: Icons.umbrella_rounded,
        iconColor: const Color(0xFF4F46E5),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final width = constraints.maxWidth;
        // Menyesuaikan jumlah kolom berdasarkan lebar layar agar bebas overflow
        final columns = width >= 820
            ? 5
            : width >= 540
                ? 3
                : 2;
        final itemWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics.map((metric) {
            return SizedBox(
              width: itemWidth,
              child: _MetricCard(metric: metric),
            );
          }).toList(),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _WeatherMetricItem metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: metric.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    metric.icon,
                    size: 18,
                    color: metric.iconColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    metric.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              metric.value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

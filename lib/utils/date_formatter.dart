import 'package:intl/intl.dart';

/// Helper pemformatan tanggal dan waktu menggunakan package `intl`
/// dengan format lokal Indonesia (`id_ID`).
class DateFormatter {
  DateFormatter._();

  /// Mengubah string tanggal ISO (misal `2026-11-25`) menjadi label ringkas
  /// seperti `"Hari Ini"`, `"Besok"`, atau `"Kam, 26 Nov"`.
  static String formatDailyLabel(String isoDate, {DateTime? referenceNow}) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;

    final now = referenceNow ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(parsed.year, parsed.month, parsed.day);
    final diffDays = target.difference(today).inDays;

    if (diffDays == 0) return 'Hari Ini';
    if (diffDays == 1) return 'Besok';

    return DateFormat('EEE, d MMM', 'id_ID').format(target);
  }

  /// Format tanggal lengkap pada bagian header Home Screen.
  static String formatFullDate(DateTime dateTime) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dateTime);
  }

  /// Format jam pembaruan data (misal `14:30`).
  static String formatUpdatedTime(DateTime dateTime) {
    return DateFormat('HH:mm', 'id_ID').format(dateTime);
  }
}

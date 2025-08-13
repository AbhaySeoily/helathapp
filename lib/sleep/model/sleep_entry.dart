// SleepController
class SleepEntry {
  DateTime date;
  Duration duration;
  int quality; // 1–5
  bool isNap;

  SleepEntry({
    required this.date,
    required this.duration,
    required this.quality,
    this.isNap = false,
  });

  String get durationString => '${duration.inHours}h ${duration.inMinutes % 60}m';
}

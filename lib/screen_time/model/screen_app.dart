class ScreenApp {
  String name;
  int minutes;
  String? packageName; // optional metadata

  ScreenApp({
    required this.name,
    required this.minutes,
    this.packageName,
  });
}

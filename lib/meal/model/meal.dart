class Meal {
  String name;
  String? slot;       // Breakfast, Lunch, Dinner, Snacks (optional)
  int? calories;      // calories (optional)
  DateTime date;      // meal date
  String? imagePath;  // image path if selected
  bool isPlanned;     // true = planned, false = eaten

  Meal({
    required this.name,
    required this.date,
    this.slot,
    this.calories,
    this.imagePath,
    this.isPlanned = false,
  });
}

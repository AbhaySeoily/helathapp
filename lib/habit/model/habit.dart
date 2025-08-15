class Habit {
  String name;
  String? notes;
  bool done;
  int targetCount; // Aaj ka target (kitne sub-tasks)
  int completedCount; // Kitne complete ho gaye

  Habit({
    required this.name,
    this.notes,
    required this.done,
    this.targetCount = 1,
    this.completedCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'notes': notes,
      'done': done,
      'targetCount': targetCount,
      'completedCount': completedCount,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      name: map['name'],
      notes: map['notes'],
      done: map['done'],
      targetCount: map['targetCount'] ?? 1,
      completedCount: map['completedCount'] ?? 0,
    );
  }
}

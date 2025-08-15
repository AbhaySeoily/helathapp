class Habit {
  String name;
  String? notes;

  /// Is habit completed today? (auto-true when completedCount == targetCount)
  bool done;

  /// Daily target (subtasks) e.g. 4 cigarettes / 5 chapters
  int targetCount;

  /// Completed count for today
  int completedCount;

  Habit({
    required this.name,
    this.notes,
    this.done = false,
    this.targetCount = 1,
    this.completedCount = 0,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'notes': notes,
    'done': done,
    'targetCount': targetCount,
    'completedCount': completedCount,
  };

  factory Habit.fromMap(Map<String, dynamic> map) => Habit(
    name: map['name'] ?? '',
    notes: map['notes'],
    done: (map['done'] ?? false) as bool,
    targetCount: (map['targetCount'] ?? 1) as int,
    completedCount: (map['completedCount'] ?? 0) as int,
  );
}

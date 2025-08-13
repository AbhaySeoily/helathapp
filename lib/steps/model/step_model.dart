// lib/steps/model/step_model.dart
class StepsModel {
  int today;
  int goal;
  List<int> last7;

  StepsModel({required this.today, required this.goal, required this.last7});

  Map<String, dynamic> toJson() => {
    'today': today,
    'goal': goal,
    'last7': last7,
  };

  factory StepsModel.fromJson(Map j) => StepsModel(
    today: j['today'] ?? 0,
    goal: j['goal'] ?? 8000,
    last7: List<int>.from(j['last7'] ?? const []),
  );
}

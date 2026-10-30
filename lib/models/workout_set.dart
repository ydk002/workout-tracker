class WorkoutSet {
  final String id;
  final int setNumber;
  final double weight; // kg
  final int reps;
  final bool isCompleted;
  final double? rpe; // 1-10 rate of perceived exertion

  const WorkoutSet({
    required this.id,
    required this.setNumber,
    required this.weight,
    required this.reps,
    this.isCompleted = false,
    this.rpe,
  });

  double get volume => isCompleted ? weight * reps : 0.0;

  /// Becsült 1RM (Epley-képlet alapján: súly * (1 + ismétlés / 30))
  double get estimated1RM {
    if (!isCompleted || weight <= 0 || reps <= 0) return 0.0;
    if (reps == 1) return weight;
    return weight * (1.0 + reps / 30.0);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'setNumber': setNumber,
    'weight': weight,
    'reps': reps,
    'isCompleted': isCompleted,
    'rpe': rpe,
  };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) => WorkoutSet(
    id: json['id'] as String,
    setNumber: json['setNumber'] as int? ?? 1,
    weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
    reps: json['reps'] as int? ?? 0,
    isCompleted: json['isCompleted'] as bool? ?? false,
    rpe: (json['rpe'] as num?)?.toDouble(),
  );

  WorkoutSet copyWith({
    String? id,
    int? setNumber,
    double? weight,
    int? reps,
    bool? isCompleted,
    double? rpe,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      setNumber: setNumber ?? this.setNumber,
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
      rpe: rpe ?? this.rpe,
    );
  }
}

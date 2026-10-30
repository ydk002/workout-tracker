import 'workout_set.dart';

class WorkoutExercise {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final String category;
  final List<WorkoutSet> sets;
  final int restTimeSeconds;
  final String? notes;

  const WorkoutExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    required this.sets,
    this.restTimeSeconds = 90,
    this.notes,
  });

  double get totalVolume => sets.fold(0.0, (sum, set) => sum + set.volume);

  int get completedSetsCount => sets.where((s) => s.isCompleted).length;

  double get maxWeight {
    final completed = sets.where((s) => s.isCompleted);
    if (completed.isEmpty) return 0.0;
    return completed.map((s) => s.weight).reduce((a, b) => a > b ? a : b);
  }

  double get maxEstimated1RM {
    final completed = sets.where((s) => s.isCompleted);
    if (completed.isEmpty) return 0.0;
    return completed.map((s) => s.estimated1RM).reduce((a, b) => a > b ? a : b);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'category': category,
    'sets': sets.map((s) => s.toJson()).toList(),
    'restTimeSeconds': restTimeSeconds,
    'notes': notes,
  };

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) => WorkoutExercise(
    id: json['id'] as String,
    exerciseId: json['exerciseId'] as String,
    exerciseName: json['exerciseName'] as String,
    category: json['category'] as String? ?? 'other',
    sets: (json['sets'] as List<dynamic>?)
            ?.map((s) => WorkoutSet.fromJson(Map<String, dynamic>.from(s as Map)))
            .toList() ??
        [],
    restTimeSeconds: json['restTimeSeconds'] as int? ?? 90,
    notes: json['notes'] as String?,
  );

  WorkoutExercise copyWith({
    String? id,
    String? exerciseId,
    String? exerciseName,
    String? category,
    List<WorkoutSet>? sets,
    int? restTimeSeconds,
    String? notes,
  }) {
    return WorkoutExercise(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      category: category ?? this.category,
      sets: sets ?? this.sets,
      restTimeSeconds: restTimeSeconds ?? this.restTimeSeconds,
      notes: notes ?? this.notes,
    );
  }
}

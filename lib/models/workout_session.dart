import 'workout_exercise.dart';

class WorkoutSession {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime? endTime;
  final List<WorkoutExercise> exercises;
  final String? notes;
  final bool isCompleted;

  const WorkoutSession({
    required this.id,
    required this.title,
    required this.startTime,
    this.endTime,
    required this.exercises,
    this.notes,
    this.isCompleted = false,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  double get totalVolume =>
      exercises.fold(0.0, (sum, ex) => sum + ex.totalVolume);

  int get totalCompletedSets =>
      exercises.fold(0, (sum, ex) => sum + ex.completedSetsCount);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'exercises': exercises.map((e) => e.toJson()).toList(),
    'notes': notes,
    'isCompleted': isCompleted,
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => WorkoutSession(
    id: json['id'] as String,
    title: json['title'] as String,
    startTime: DateTime.parse(json['startTime'] as String),
    endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
    exercises: (json['exercises'] as List<dynamic>?)
            ?.map((e) => WorkoutExercise.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [],
    notes: json['notes'] as String?,
    isCompleted: json['isCompleted'] as bool? ?? false,
  );

  WorkoutSession copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    List<WorkoutExercise>? exercises,
    String? notes,
    bool? isCompleted,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

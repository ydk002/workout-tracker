class TemplateExercise {
  final String exerciseId;
  final String exerciseName;
  final String category;
  final int targetSets;
  final int defaultRestSeconds;

  const TemplateExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.category,
    this.targetSets = 3,
    this.defaultRestSeconds = 90,
  });

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'category': category,
    'targetSets': targetSets,
    'defaultRestSeconds': defaultRestSeconds,
  };

  factory TemplateExercise.fromJson(Map<String, dynamic> json) => TemplateExercise(
    exerciseId: json['exerciseId'] as String,
    exerciseName: json['exerciseName'] as String,
    category: json['category'] as String? ?? 'other',
    targetSets: json['targetSets'] as int? ?? 3,
    defaultRestSeconds: json['defaultRestSeconds'] as int? ?? 90,
  );
}

class WorkoutTemplate {
  final String id;
  final String name;
  final String? description;
  final List<TemplateExercise> exercises;

  const WorkoutTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory WorkoutTemplate.fromJson(Map<String, dynamic> json) => WorkoutTemplate(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    exercises: (json['exercises'] as List<dynamic>?)
            ?.map((e) => TemplateExercise.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [],
  );

  WorkoutTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<TemplateExercise>? exercises,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      exercises: exercises ?? this.exercises,
    );
  }
}

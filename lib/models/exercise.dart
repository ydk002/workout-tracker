enum MuscleGroup {
  chest('Mell'),
  back('Hát'),
  legs('Láb'),
  shoulders('Váll'),
  biceps('Bicepsz'),
  triceps('Tricepsz'),
  core('Has / Törzs'),
  other('Egyéb');

  final String label;
  const MuscleGroup(this.label);

  static MuscleGroup fromString(String val) {
    return MuscleGroup.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase() || e.label.toLowerCase() == val.toLowerCase(),
      orElse: () => MuscleGroup.other,
    );
  }
}

class Exercise {
  final String id;
  final String name;
  final MuscleGroup category;
  final String? notes;
  final bool isCustom;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    this.notes,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'notes': notes,
    'isCustom': isCustom,
  };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id: json['id'] as String,
    name: json['name'] as String,
    category: MuscleGroup.fromString(json['category'] as String? ?? 'other'),
    notes: json['notes'] as String?,
    isCustom: json['isCustom'] as bool? ?? false,
  );

  Exercise copyWith({
    String? id,
    String? name,
    MuscleGroup? category,
    String? notes,
    bool? isCustom,
  }) {
    return Exercise(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

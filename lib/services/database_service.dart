import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/workout_session.dart';
import '../models/workout_template.dart';

class DatabaseService {
  static const String exercisesBoxName = 'fitlog_exercises';
  static const String sessionsBoxName = 'fitlog_sessions';
  static const String templatesBoxName = 'fitlog_templates';
  static const String settingsBoxName = 'fitlog_settings';
  static const String activeWorkoutKey = 'active_workout_json';

  static const _uuid = Uuid();

  late Box<String> _exercisesBox;
  late Box<String> _sessionsBox;
  late Box<String> _templatesBox;
  late Box<dynamic> _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _exercisesBox = await Hive.openBox<String>(exercisesBoxName);
    _sessionsBox = await Hive.openBox<String>(sessionsBoxName);
    _templatesBox = await Hive.openBox<String>(templatesBoxName);
    _settingsBox = await Hive.openBox<dynamic>(settingsBoxName);

    // Seed default exercises if empty
    if (_exercisesBox.isEmpty) {
      await _seedDefaultExercises();
    }
    // Seed default templates if empty
    if (_templatesBox.isEmpty) {
      await _seedDefaultTemplates();
    }
  }

  // ACTIVE WORKOUT AUTO-PERSISTENCE
  WorkoutSession? getActiveWorkout() {
    final raw = _settingsBox.get(activeWorkoutKey) as String?;
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return WorkoutSession.fromJson(map);
    } catch (e) {
      debugPrint('Failed to restore active workout: $e');
      return null;
    }
  }

  Future<void> saveActiveWorkout(WorkoutSession? session) async {
    if (session == null) {
      await _settingsBox.delete(activeWorkoutKey);
    } else {
      await _settingsBox.put(activeWorkoutKey, jsonEncode(session.toJson()));
    }
  }

  // EXERCISES
  List<Exercise> getExercises() {
    return _exercisesBox.values.map((raw) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return Exercise.fromJson(map);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> saveExercise(Exercise exercise) async {
    await _exercisesBox.put(exercise.id, jsonEncode(exercise.toJson()));
  }

  Future<void> deleteExercise(String id) async {
    await _exercisesBox.delete(id);
  }

  // SESSIONS
  List<WorkoutSession> getSessions() {
    final list = _sessionsBox.values.map((raw) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return WorkoutSession.fromJson(map);
    }).toList();
    list.sort((a, b) => b.startTime.compareTo(a.startTime)); // newest first
    return list;
  }

  Future<void> saveSession(WorkoutSession session) async {
    await _sessionsBox.put(session.id, jsonEncode(session.toJson()));
  }

  Future<void> deleteSession(String id) async {
    await _sessionsBox.delete(id);
  }

  // TEMPLATES
  List<WorkoutTemplate> getTemplates() {
    return _templatesBox.values.map((raw) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return WorkoutTemplate.fromJson(map);
    }).toList();
  }

  Future<void> saveTemplate(WorkoutTemplate template) async {
    await _templatesBox.put(template.id, jsonEncode(template.toJson()));
  }

  Future<void> deleteTemplate(String id) async {
    await _templatesBox.delete(id);
  }

  // EXPORT / IMPORT
  String exportBackupJson() {
    final data = {
      'app': 'FitLog',
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'exercises': _exercisesBox.values.map((v) => jsonDecode(v)).toList(),
      'sessions': _sessionsBox.values.map((v) => jsonDecode(v)).toList(),
      'templates': _templatesBox.values.map((v) => jsonDecode(v)).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<bool> importBackupJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      if (decoded['app'] != 'FitLog') return false;

      if (decoded['exercises'] is List) {
        await _exercisesBox.clear();
        for (final item in decoded['exercises'] as List) {
          final map = Map<String, dynamic>.from(item as Map);
          await _exercisesBox.put(map['id'], jsonEncode(map));
        }
      }

      if (decoded['sessions'] is List) {
        await _sessionsBox.clear();
        for (final item in decoded['sessions'] as List) {
          final map = Map<String, dynamic>.from(item as Map);
          await _sessionsBox.put(map['id'], jsonEncode(map));
        }
      }

      if (decoded['templates'] is List) {
        await _templatesBox.clear();
        for (final item in decoded['templates'] as List) {
          final map = Map<String, dynamic>.from(item as Map);
          await _templatesBox.put(map['id'], jsonEncode(map));
        }
      }

      return true;
    } catch (e) {
      debugPrint('Import error: $e');
      return false;
    }
  }

  // SEED DATA
  Future<void> _seedDefaultExercises() async {
    final defaultExercises = [
      // Mell
      Exercise(
        id: _uuid.v4(),
        name: 'Fekvenyomás rúddal',
        category: MuscleGroup.chest,
        notes: 'Lapockák összezárva, kontrollált leengedés mellkasig.',
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Kézisúlyzós nyomás ferdepadon',
        category: MuscleGroup.chest,
        notes: '30-45 fokos padállás, felső mellizom fókusz.',
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Tárogatás csigán',
        category: MuscleGroup.chest,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Tolódzkodás',
        category: MuscleGroup.chest,
      ),

      // Hát
      Exercise(
        id: _uuid.v4(),
        name: 'Húzódzkodás',
        category: MuscleGroup.back,
        notes: 'Teljes mozgástartomány, mellkas a rúdhoz közelítsen.',
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Evezés rúddal döntött törzzsel',
        category: MuscleGroup.back,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Lehúzás széles fogással csigán',
        category: MuscleGroup.back,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Felhúzás (Deadlift)',
        category: MuscleGroup.back,
        notes: 'Egyenes hát, rúd a sípcsont mentén haladjon.',
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Mellhez húzás csigán szűk fogással',
        category: MuscleGroup.back,
      ),

      // Láb
      Exercise(
        id: _uuid.v4(),
        name: 'Guggolás rúddal',
        category: MuscleGroup.legs,
        notes: 'Térdek a lábfej irányába, legalább vízszintesig.',
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Lábtoló gép',
        category: MuscleGroup.legs,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Combnyújtás gépen',
        category: MuscleGroup.legs,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Combhajlítás fekve gépen',
        category: MuscleGroup.legs,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Vádli állva gépen',
        category: MuscleGroup.legs,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Román felhúzás kézisúllyal',
        category: MuscleGroup.legs,
      ),

      // Váll
      Exercise(
        id: _uuid.v4(),
        name: 'Vállból nyomás kézisúlyzóval',
        category: MuscleGroup.shoulders,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Katonai nyomás rúddal (OHP)',
        category: MuscleGroup.shoulders,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Oldalemelés kézisúlyzóval',
        category: MuscleGroup.shoulders,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Döntött törzsű oldalemelés',
        category: MuscleGroup.shoulders,
      ),

      // Bicepsz
      Exercise(
        id: _uuid.v4(),
        name: 'Bicepszhajlítás állva rúddal',
        category: MuscleGroup.biceps,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Bicepszhajlítás Scott padon',
        category: MuscleGroup.biceps,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Kalapács hajlítás kézisúllyal',
        category: MuscleGroup.biceps,
      ),

      // Tricepsz
      Exercise(
        id: _uuid.v4(),
        name: 'Tricepsznyújtás csigán kötéllel',
        category: MuscleGroup.triceps,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Koponyatörő (Francia nyomás)',
        category: MuscleGroup.triceps,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Letolás egyenes rúddal',
        category: MuscleGroup.triceps,
      ),

      // Has / Törzs
      Exercise(
        id: _uuid.v4(),
        name: 'Lebegőülés / Hasprés padon',
        category: MuscleGroup.core,
      ),
      Exercise(
        id: _uuid.v4(),
        name: 'Lábemelés függeszkedve',
        category: MuscleGroup.core,
      ),
    ];

    for (final ex in defaultExercises) {
      await saveExercise(ex);
    }
  }

  Future<void> _seedDefaultTemplates() async {
    final exercises = getExercises();
    Exercise? findEx(String name) {
      try {
        return exercises.firstWhere(
          (e) => e.name.toLowerCase().contains(name.toLowerCase()),
        );
      } catch (_) {
        return null;
      }
    }

    final bench = findEx('Fekvenyomás rúddal');
    final incline = findEx('Kézisúlyzós nyomás');
    final military = findEx('Katonai nyomás');
    final lateral = findEx('Oldalemelés');
    final tricep = findEx('Tricepsznyújtás csigán');
    final pullup = findEx('Húzódzkodás');
    final row = findEx('Evezés rúddal');
    final bicep = findEx('Bicepszhajlítás állva');
    final squat = findEx('Guggolás');
    final legpress = findEx('Lábtoló');
    final curl = findEx('Combhajlítás');
    final rdl = findEx('Román felhúzás');
    final calf = findEx('Vádli');

    if (bench != null && incline != null && military != null) {
      final pushTemplate = WorkoutTemplate(
        id: _uuid.v4(),
        name: 'Push (Mell - Váll - Tricepsz)',
        description: 'Klasszikus nyomó nap: mellkasi és vállizmok, tricepsz',
        exercises: [
          TemplateExercise(exerciseId: bench.id, exerciseName: bench.name, category: bench.category.label, targetSets: 4),
          TemplateExercise(exerciseId: incline.id, exerciseName: incline.name, category: incline.category.label, targetSets: 3),
          TemplateExercise(exerciseId: military.id, exerciseName: military.name, category: military.category.label, targetSets: 3),
          if (lateral != null)
            TemplateExercise(exerciseId: lateral.id, exerciseName: lateral.name, category: lateral.category.label, targetSets: 4),
          if (tricep != null)
            TemplateExercise(exerciseId: tricep.id, exerciseName: tricep.name, category: tricep.category.label, targetSets: 3),
        ],
      );
      await saveTemplate(pushTemplate);
    }

    if (pullup != null && row != null && bicep != null) {
      final pullTemplate = WorkoutTemplate(
        id: _uuid.v4(),
        name: 'Pull (Hát - Bicepsz)',
        description: 'Húzó nap: széles hátizom, trapéz és bicepsz',
        exercises: [
          TemplateExercise(exerciseId: pullup.id, exerciseName: pullup.name, category: pullup.category.label, targetSets: 4),
          TemplateExercise(exerciseId: row.id, exerciseName: row.name, category: row.category.label, targetSets: 4),
          TemplateExercise(exerciseId: bicep.id, exerciseName: bicep.name, category: bicep.category.label, targetSets: 3),
        ],
      );
      await saveTemplate(pullTemplate);
    }

    if (squat != null && legpress != null) {
      final legTemplate = WorkoutTemplate(
        id: _uuid.v4(),
        name: 'Legs (Lábnap)',
        description: 'Alsótest fókusz: combok, vádli',
        exercises: [
          TemplateExercise(exerciseId: squat.id, exerciseName: squat.name, category: squat.category.label, targetSets: 4),
          TemplateExercise(exerciseId: legpress.id, exerciseName: legpress.name, category: legpress.category.label, targetSets: 3),
          if (rdl != null)
            TemplateExercise(exerciseId: rdl.id, exerciseName: rdl.name, category: rdl.category.label, targetSets: 3),
          if (curl != null)
            TemplateExercise(exerciseId: curl.id, exerciseName: curl.name, category: curl.category.label, targetSets: 3),
          if (calf != null)
            TemplateExercise(exerciseId: calf.id, exerciseName: calf.name, category: calf.category.label, targetSets: 4),
        ],
      );
      await saveTemplate(legTemplate);
    }

    if (bench != null && row != null && military != null && pullup != null) {
      final upperTemplate = WorkoutTemplate(
        id: _uuid.v4(),
        name: 'Upper (Felsőtest)',
        description: 'Teljes felsőtest edzés Upper/Lower felosztáshoz',
        exercises: [
          TemplateExercise(exerciseId: bench.id, exerciseName: bench.name, category: bench.category.label, targetSets: 4),
          TemplateExercise(exerciseId: row.id, exerciseName: row.name, category: row.category.label, targetSets: 4),
          TemplateExercise(exerciseId: military.id, exerciseName: military.name, category: military.category.label, targetSets: 3),
          TemplateExercise(exerciseId: pullup.id, exerciseName: pullup.name, category: pullup.category.label, targetSets: 3),
          if (bicep != null)
            TemplateExercise(exerciseId: bicep.id, exerciseName: bicep.name, category: bicep.category.label, targetSets: 3),
          if (tricep != null)
            TemplateExercise(exerciseId: tricep.id, exerciseName: tricep.name, category: tricep.category.label, targetSets: 3),
        ],
      );
      await saveTemplate(upperTemplate);
    }

    if (squat != null && bench != null && row != null && military != null) {
      final fullBodyTemplate = WorkoutTemplate(
        id: _uuid.v4(),
        name: 'Full Body (Teljes test)',
        description: 'Alapgyakorlatokra épülő teljes testes edzésterv',
        exercises: [
          TemplateExercise(exerciseId: squat.id, exerciseName: squat.name, category: squat.category.label, targetSets: 4),
          TemplateExercise(exerciseId: bench.id, exerciseName: bench.name, category: bench.category.label, targetSets: 4),
          TemplateExercise(exerciseId: row.id, exerciseName: row.name, category: row.category.label, targetSets: 4),
          TemplateExercise(exerciseId: military.id, exerciseName: military.name, category: military.category.label, targetSets: 3),
        ],
      );
      await saveTemplate(fullBodyTemplate);
    }
  }
}

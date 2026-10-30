import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/workout_exercise.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import '../models/workout_template.dart';
import '../services/database_service.dart';
import '../services/sound_service.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  throw UnimplementedError('DatabaseService must be initialized in main');
});

// EXERCISES PROVIDER
class ExercisesNotifier extends StateNotifier<List<Exercise>> {
  final DatabaseService _db;
  ExercisesNotifier(this._db) : super([]) {
    load();
  }

  void load() {
    state = _db.getExercises();
  }

  Future<void> addExercise(Exercise exercise) async {
    await _db.saveExercise(exercise);
    load();
  }

  Future<void> updateExercise(Exercise exercise) async {
    await _db.saveExercise(exercise);
    load();
  }

  Future<void> deleteExercise(String id) async {
    await _db.deleteExercise(id);
    load();
  }
}

final exercisesProvider =
    StateNotifierProvider<ExercisesNotifier, List<Exercise>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return ExercisesNotifier(db);
});

// TEMPLATES PROVIDER
class TemplatesNotifier extends StateNotifier<List<WorkoutTemplate>> {
  final DatabaseService _db;
  TemplatesNotifier(this._db) : super([]) {
    load();
  }

  void load() {
    state = _db.getTemplates();
  }

  Future<void> saveTemplate(WorkoutTemplate template) async {
    await _db.saveTemplate(template);
    load();
  }

  Future<void> deleteTemplate(String id) async {
    await _db.deleteTemplate(id);
    load();
  }
}

final templatesProvider =
    StateNotifierProvider<TemplatesNotifier, List<WorkoutTemplate>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return TemplatesNotifier(db);
});

// SESSIONS PROVIDER
class SessionsNotifier extends StateNotifier<List<WorkoutSession>> {
  final DatabaseService _db;
  SessionsNotifier(this._db) : super([]) {
    load();
  }

  void load() {
    state = _db.getSessions();
  }

  Future<void> saveSession(WorkoutSession session) async {
    await _db.saveSession(session);
    load();
  }

  Future<void> deleteSession(String id) async {
    await _db.deleteSession(id);
    load();
  }
}

final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, List<WorkoutSession>>((ref) {
  final db = ref.watch(databaseServiceProvider);
  return SessionsNotifier(db);
});

// REST TIMER STATE & PROVIDER
class RestTimerState {
  final int totalSeconds;
  final int remainingSeconds;
  final bool isRunning;

  const RestTimerState({
    this.totalSeconds = 90,
    this.remainingSeconds = 0,
    this.isRunning = false,
  });

  RestTimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    bool? isRunning,
  }) {
    return RestTimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      isRunning: isRunning ?? this.isRunning,
    );
  }
}

class RestTimerNotifier extends StateNotifier<RestTimerState> {
  Timer? _timer;

  RestTimerNotifier() : super(const RestTimerState());

  void startTimer(int seconds) {
    _timer?.cancel();
    state = RestTimerState(
      totalSeconds: seconds,
      remainingSeconds: seconds,
      isRunning: true,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        _timer?.cancel();
        state = state.copyWith(remainingSeconds: 0, isRunning: false);
        SoundService.playTimerBeep();
      }
    });
  }

  void addSeconds(int seconds) {
    if (state.isRunning) {
      state = state.copyWith(
        remainingSeconds: state.remainingSeconds + seconds,
        totalSeconds: state.totalSeconds + seconds,
      );
    } else {
      startTimer(seconds);
    }
  }

  void stop() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, remainingSeconds: 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier();
});

// ACTIVE WORKOUT PROVIDER (with auto-persistence to Hive)
class ActiveWorkoutNotifier extends StateNotifier<WorkoutSession?> {
  final Ref _ref;
  static const _uuid = Uuid();

  ActiveWorkoutNotifier(this._ref)
      : super(_ref.read(databaseServiceProvider).getActiveWorkout());

  void _setStateAndPersist(WorkoutSession? newState) {
    state = newState;
    _ref.read(databaseServiceProvider).saveActiveWorkout(newState);
  }

  void startEmptyWorkout({String title = 'Szabad edzés'}) {
    _setStateAndPersist(
      WorkoutSession(
        id: _uuid.v4(),
        title: title,
        startTime: DateTime.now(),
        exercises: [],
      ),
    );
  }

  void startFromTemplate(WorkoutTemplate template) {
    final exercises = template.exercises.map((tEx) {
      final sets = List.generate(
        tEx.targetSets,
        (idx) => WorkoutSet(
          id: _uuid.v4(),
          setNumber: idx + 1,
          weight: 0,
          reps: 0,
          isCompleted: false,
        ),
      );

      return WorkoutExercise(
        id: _uuid.v4(),
        exerciseId: tEx.exerciseId,
        exerciseName: tEx.exerciseName,
        category: tEx.category,
        sets: sets,
        restTimeSeconds: tEx.defaultRestSeconds,
      );
    }).toList();

    _setStateAndPersist(
      WorkoutSession(
        id: _uuid.v4(),
        title: template.name,
        startTime: DateTime.now(),
        exercises: exercises,
      ),
    );
  }

  void updateTitle(String newTitle) {
    if (state == null) return;
    _setStateAndPersist(state!.copyWith(title: newTitle));
  }

  void updateNotes(String? notes) {
    if (state == null) return;
    _setStateAndPersist(state!.copyWith(notes: notes));
  }

  void addExerciseToWorkout(Exercise exercise) {
    if (state == null) return;
    final newEx = WorkoutExercise(
      id: _uuid.v4(),
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      category: exercise.category.label,
      sets: [
        WorkoutSet(
          id: _uuid.v4(),
          setNumber: 1,
          weight: 0,
          reps: 0,
          isCompleted: false,
        ),
      ],
      restTimeSeconds: 90,
    );

    _setStateAndPersist(
      state!.copyWith(
        exercises: [...state!.exercises, newEx],
      ),
    );
  }

  void removeExercise(String workoutExerciseId) {
    if (state == null) return;
    _setStateAndPersist(
      state!.copyWith(
        exercises:
            state!.exercises.where((e) => e.id != workoutExerciseId).toList(),
      ),
    );
  }

  void updateExerciseRestTime(String workoutExerciseId, int restSeconds) {
    if (state == null) return;
    final exercises = state!.exercises.map((e) {
      if (e.id == workoutExerciseId) {
        return e.copyWith(restTimeSeconds: restSeconds);
      }
      return e;
    }).toList();
    _setStateAndPersist(state!.copyWith(exercises: exercises));
  }

  void addSet(String workoutExerciseId) {
    if (state == null) return;
    final updated = state!.exercises.map((ex) {
      if (ex.id == workoutExerciseId) {
        final lastSet = ex.sets.isNotEmpty ? ex.sets.last : null;
        final newSet = WorkoutSet(
          id: _uuid.v4(),
          setNumber: ex.sets.length + 1,
          weight: lastSet?.weight ?? 0,
          reps: lastSet?.reps ?? 0,
          isCompleted: false,
        );
        return ex.copyWith(sets: [...ex.sets, newSet]);
      }
      return ex;
    }).toList();

    _setStateAndPersist(state!.copyWith(exercises: updated));
  }

  void removeSet(String workoutExerciseId, String setId) {
    if (state == null) return;
    final updated = state!.exercises.map((ex) {
      if (ex.id == workoutExerciseId) {
        final filtered = ex.sets.where((s) => s.id != setId).toList();
        final renumbered = [
          for (int i = 0; i < filtered.length; i++)
            filtered[i].copyWith(setNumber: i + 1)
        ];
        return ex.copyWith(sets: renumbered);
      }
      return ex;
    }).toList();

    _setStateAndPersist(state!.copyWith(exercises: updated));
  }

  void updateSet(String workoutExerciseId, WorkoutSet updatedSet) {
    if (state == null) return;
    final updated = state!.exercises.map((ex) {
      if (ex.id == workoutExerciseId) {
        final sets =
            ex.sets.map((s) => s.id == updatedSet.id ? updatedSet : s).toList();
        return ex.copyWith(sets: sets);
      }
      return ex;
    }).toList();

    _setStateAndPersist(state!.copyWith(exercises: updated));
  }

  void toggleSetCompleted(String workoutExerciseId, String setId) {
    if (state == null) return;
    int restTime = 90;
    bool wasCompleted = false;

    final updated = state!.exercises.map((ex) {
      if (ex.id == workoutExerciseId) {
        restTime = ex.restTimeSeconds;
        final sets = ex.sets.map((s) {
          if (s.id == setId) {
            wasCompleted = !s.isCompleted;
            return s.copyWith(isCompleted: wasCompleted);
          }
          return s;
        }).toList();
        return ex.copyWith(sets: sets);
      }
      return ex;
    }).toList();

    _setStateAndPersist(state!.copyWith(exercises: updated));

    if (wasCompleted) {
      _ref.read(restTimerProvider.notifier).startTimer(restTime);
    }
  }

  Future<WorkoutSession?> finishWorkout() async {
    if (state == null) return null;
    final finishedSession = state!.copyWith(
      endTime: DateTime.now(),
      isCompleted: true,
    );

    await _ref.read(sessionsProvider.notifier).saveSession(finishedSession);
    _ref.read(restTimerProvider.notifier).stop();
    _setStateAndPersist(null);
    return finishedSession;
  }

  void cancelWorkout() {
    _ref.read(restTimerProvider.notifier).stop();
    _setStateAndPersist(null);
  }
}

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, WorkoutSession?>((ref) {
  return ActiveWorkoutNotifier(ref);
});

// HISTORICAL PREVIOUS SET HELPER
final previousPerformanceProvider =
    Provider.family<List<WorkoutSet>?, String>((ref, exerciseId) {
  final sessions = ref.watch(sessionsProvider);
  for (final session in sessions) {
    for (final ex in session.exercises) {
      if (ex.exerciseId == exerciseId && ex.sets.any((s) => s.isCompleted)) {
        return ex.sets.where((s) => s.isCompleted).toList();
      }
    }
  }
  return null;
});

// PERSONAL RECORD (PR) HELPER (Exercise Name -> Max Weight)
final personalRecordsProvider = Provider<Map<String, double>>((ref) {
  final sessions = ref.watch(sessionsProvider);
  final Map<String, double> prs = {};

  for (final session in sessions) {
    for (final ex in session.exercises) {
      final maxW = ex.maxWeight;
      if (maxW > 0) {
        if (!prs.containsKey(ex.exerciseName) || maxW > prs[ex.exerciseName]!) {
          prs[ex.exerciseName] = maxW;
        }
      }
    }
  }
  return prs;
});

// EXERCISE PROGRESSION DATA FOR CHARTS
class ExerciseProgressionPoint {
  final DateTime date;
  final String sessionTitle;
  final double maxWeight;
  final double estimated1RM;
  final double volume;

  const ExerciseProgressionPoint({
    required this.date,
    required this.sessionTitle,
    required this.maxWeight,
    required this.estimated1RM,
    required this.volume,
  });
}

final exerciseProgressionProvider =
    Provider.family<List<ExerciseProgressionPoint>, String>((ref, exerciseName) {
  final sessions = ref.watch(sessionsProvider);
  final List<ExerciseProgressionPoint> points = [];

  // Process chronologically (oldest first)
  for (final session in sessions.reversed) {
    for (final ex in session.exercises) {
      if (ex.exerciseName == exerciseName && ex.maxWeight > 0) {
        points.add(
          ExerciseProgressionPoint(
            date: session.startTime,
            sessionTitle: session.title,
            maxWeight: ex.maxWeight,
            estimated1RM: ex.maxEstimated1RM,
            volume: ex.totalVolume,
          ),
        );
      }
    }
  }
  return points;
});

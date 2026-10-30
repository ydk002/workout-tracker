import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/models/exercise.dart';
import 'package:workout_tracker/models/workout_set.dart';
import 'package:workout_tracker/models/workout_exercise.dart';
import 'package:workout_tracker/models/workout_session.dart';
import 'package:workout_tracker/models/workout_template.dart';

void main() {
  test('Workout calculations and 1RM test', () {
    const set1 = WorkoutSet(
      id: '1',
      setNumber: 1,
      weight: 100,
      reps: 5,
      isCompleted: true,
      rpe: 8,
    );
    const set2 = WorkoutSet(
      id: '2',
      setNumber: 2,
      weight: 100,
      reps: 5,
      isCompleted: true,
    );
    const set3 = WorkoutSet(
      id: '3',
      setNumber: 3,
      weight: 100,
      reps: 5,
      isCompleted: false,
    );

    expect(set1.volume, 500);
    expect(set3.volume, 0); // not completed
    expect(set1.estimated1RM, closeTo(116.66, 0.1));

    const exercise = WorkoutExercise(
      id: 'ex1',
      exerciseId: 'bench',
      exerciseName: 'Fekvenyomás',
      category: 'Mell',
      sets: [set1, set2, set3],
    );

    expect(exercise.totalVolume, 1000);
    expect(exercise.completedSetsCount, 2);
    expect(exercise.maxWeight, 100);
    expect(exercise.maxEstimated1RM, closeTo(116.66, 0.1));

    final session = WorkoutSession(
      id: 's1',
      title: 'Mellnap',
      startTime: DateTime.now().subtract(const Duration(minutes: 45)),
      endTime: DateTime.now(),
      exercises: [exercise],
      notes: 'Szuper edzés',
      isCompleted: true,
    );

    expect(session.totalVolume, 1000);
    expect(session.totalCompletedSets, 2);

    // Test JSON round-trip
    final sessionJson = session.toJson();
    final restoredSession = WorkoutSession.fromJson(sessionJson);
    expect(restoredSession.title, 'Mellnap');
    expect(restoredSession.notes, 'Szuper edzés');
    expect(restoredSession.totalVolume, 1000);
    expect(restoredSession.exercises.first.sets.first.rpe, 8);
  });

  test('Exercise and Template JSON serialization test', () {
    const ex = Exercise(
      id: 'e1',
      name: 'Guggolás',
      category: MuscleGroup.legs,
      notes: 'Mélyre',
      isCustom: true,
    );
    final exRestored = Exercise.fromJson(ex.toJson());
    expect(exRestored.name, 'Guggolás');
    expect(exRestored.category, MuscleGroup.legs);
    expect(exRestored.notes, 'Mélyre');
    expect(exRestored.isCustom, true);

    const tpl = WorkoutTemplate(
      id: 't1',
      name: 'Push A',
      description: 'Mell fókusz',
      exercises: [
        TemplateExercise(
          exerciseId: 'e1',
          exerciseName: 'Fekvenyomás',
          category: 'Mell',
          targetSets: 4,
        ),
      ],
    );
    final tplRestored = WorkoutTemplate.fromJson(tpl.toJson());
    expect(tplRestored.name, 'Push A');
    expect(tplRestored.exercises.first.targetSets, 4);
  });
}

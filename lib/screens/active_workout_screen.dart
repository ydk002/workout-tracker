import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/exercise.dart';
import '../models/workout_exercise.dart';
import '../models/workout_session.dart';
import '../models/workout_set.dart';
import '../providers/workout_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/rest_timer_banner.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _durationTimer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _startDurationTicker();
  }

  void _updateElapsed() {
    final activeWorkout = ref.read(activeWorkoutProvider);
    if (activeWorkout != null) {
      _elapsed = DateTime.now().difference(activeWorkout.startTime);
    }
  }

  void _startDurationTicker() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final activeWorkout = ref.read(activeWorkoutProvider);
      if (activeWorkout != null && mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(activeWorkout.startTime);
        });
      }
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours ó ${minutes.toString().padLeft(2, '0')} p ${seconds.toString().padLeft(2, '0')} mp';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showEditTitleAndNotesDialog(
      BuildContext context, WorkoutSession workout) {
    final titleCtrl = TextEditingController(text: workout.title);
    final notesCtrl = TextEditingController(text: workout.notes ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceBg,
        title: const Text('Edzés adatainak szerkesztése'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Edzés megnevezése',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Edzés jegyzet (opcionális)',
                hintText: 'Pl. Jó energiaszint, új terem...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mégse'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = titleCtrl.text.trim();
              if (newTitle.isNotEmpty) {
                ref.read(activeWorkoutProvider.notifier).updateTitle(newTitle);
              }
              final newNotes = notesCtrl.text.trim();
              ref
                  .read(activeWorkoutProvider.notifier)
                  .updateNotes(newNotes.isEmpty ? null : newNotes);
              Navigator.pop(ctx);
            },
            child: const Text('Mentés'),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _AddExerciseModal(),
    );
  }

  Future<void> _finishWorkout(
      BuildContext context, WorkoutSession workout) async {
    final hasCompletedSets =
        workout.exercises.any((e) => e.sets.any((s) => s.isCompleted));

    if (!hasCompletedSets) {
      final shouldFinish = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceBg,
          title: const Text('Nincs befejezett sorozat'),
          content:
              const Text('Biztosan befejezed az edzést sorozatok nélkül?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Mégse'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Befejezés'),
            ),
          ],
        ),
      );
      if (shouldFinish != true) return;
    }

    // Calculate new PRs achieved in this session compared to historical PRs
    final previousPRs = ref.read(personalRecordsProvider);
    final achievedPRs = <String, double>{};
    for (final ex in workout.exercises) {
      final sessionMax = ex.maxWeight;
      if (sessionMax > 0) {
        final prevMax = previousPRs[ex.exerciseName] ?? 0.0;
        if (sessionMax > prevMax) {
          achievedPRs[ex.exerciseName] = sessionMax;
        }
      }
    }

    final finished =
        await ref.read(activeWorkoutProvider.notifier).finishWorkout();
    if (!mounted || finished == null) return;

    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => _WorkoutSummaryDialog(
          session: finished,
          newPRs: achievedPRs,
        ),
      );
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  void _confirmCancelWorkout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceBg,
        title: const Text('Edzés megszakítása'),
        content: const Text(
          'Biztosan megszakítod az edzést? A nem mentett adatok elvesznek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Folytatás'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(activeWorkoutProvider.notifier).cancelWorkout();
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            child: const Text('Megszakítás'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workout = ref.watch(activeWorkoutProvider);

    if (workout == null) {
      return const Scaffold(
        body: Center(child: Text('Nincs aktív edzés')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => _showEditTitleAndNotesDialog(context, workout),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      workout.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_outlined,
                      size: 14, color: AppTheme.textSecondary),
                ],
              ),
              Text(
                'Idő: ${_formatDuration(_elapsed)} • Volumen: ${NumberFormat('#,##0').format(workout.totalVolume)} kg',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edzés megszakítása',
            icon: const Icon(Icons.close, color: Colors.redAccent),
            onPressed: () => _confirmCancelWorkout(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              onPressed: () => _finishWorkout(context, workout),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Kész',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const RestTimerBanner(),
          Expanded(
            child: workout.exercises.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center_rounded,
                            size: 64,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Még nincs gyakorlat hozzáadva',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Kattints az alábbi gombra az első gyakorlat felvételéhez!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _showAddExerciseModal(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Gyakorlat hozzáadása'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: workout.exercises.length,
                    itemBuilder: (context, index) {
                      final exercise = workout.exercises[index];
                      return _WorkoutExerciseCard(
                        key: ValueKey(exercise.id),
                        exercise: exercise,
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: workout.exercises.isNotEmpty
          ? Container(
              color: AppTheme.scaffoldBg,
              padding: const EdgeInsets.all(12),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddExerciseModal(context),
                    icon: const Icon(Icons.add),
                    label: const Text('További gyakorlat hozzáadása'),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _WorkoutExerciseCard extends ConsumerWidget {
  final WorkoutExercise exercise;

  const _WorkoutExerciseCard({super.key, required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prevSets =
        ref.watch(previousPerformanceProvider(exercise.exerciseId));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.exerciseName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${exercise.category} • Pihenő: ${exercise.restTimeSeconds} mp',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<int>(
                  icon: const Icon(Icons.timer_outlined, size: 20),
                  tooltip: 'Pihenőidő beállítása',
                  initialValue: exercise.restTimeSeconds,
                  onSelected: (val) {
                    ref
                        .read(activeWorkoutProvider.notifier)
                        .updateExerciseRestTime(exercise.id, val);
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 60, child: Text('60 mp')),
                    const PopupMenuItem(value: 90, child: Text('90 mp')),
                    const PopupMenuItem(value: 120, child: Text('120 mp')),
                    const PopupMenuItem(value: 180, child: Text('180 mp')),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.grey, size: 20),
                  onPressed: () {
                    ref
                        .read(activeWorkoutProvider.notifier)
                        .removeExercise(exercise.id);
                  },
                ),
              ],
            ),
            const Divider(color: AppTheme.dividerColor, height: 24),

            // Table Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      'SZETT',
                      style:
                          TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'ELŐZŐ (böki=másol)',
                      style:
                          TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        'KG',
                        style: TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: Text(
                        'REPS',
                        style: TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 36,
                    child: Center(
                      child: Text(
                        'RPE',
                        style: TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Center(
                      child: Icon(Icons.check,
                          size: 16, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // Sets rows
            ...exercise.sets.map((set) {
              final prevSet =
                  (prevSets != null && prevSets.length >= set.setNumber)
                      ? prevSets[set.setNumber - 1]
                      : null;

              return _SetRow(
                key: ValueKey(set.id),
                workoutExerciseId: exercise.id,
                set: set,
                previousSet: prevSet,
              );
            }),

            const SizedBox(height: 12),
            // Add Set button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  ref.read(activeWorkoutProvider.notifier).addSet(exercise.id);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Sorozat hozzáadása'),
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.surfaceElevated,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetRow extends ConsumerStatefulWidget {
  final String workoutExerciseId;
  final WorkoutSet set;
  final WorkoutSet? previousSet;

  const _SetRow({
    super.key,
    required this.workoutExerciseId,
    required this.set,
    required this.previousSet,
  });

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.set.weight > 0
          ? widget.set.weight.toStringAsFixed(
              widget.set.weight.truncateToDouble() == widget.set.weight ? 0 : 1)
          : '',
    );
    _repsController = TextEditingController(
      text: widget.set.reps > 0 ? widget.set.reps.toString() : '',
    );
  }

  @override
  void didUpdateWidget(covariant _SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.set.weight != widget.set.weight) {
      final text = widget.set.weight > 0
          ? widget.set.weight.toStringAsFixed(
              widget.set.weight.truncateToDouble() == widget.set.weight ? 0 : 1)
          : '';
      if (_weightController.text != text) {
        _weightController.text = text;
      }
    }
    if (oldWidget.set.reps != widget.set.reps) {
      final text = widget.set.reps > 0 ? widget.set.reps.toString() : '';
      if (_repsController.text != text) {
        _repsController.text = text;
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _saveInputs({double? customRpe, bool clearRpe = false}) {
    final weight =
        double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0.0;
    final reps = int.tryParse(_repsController.text) ?? 0;
    final updated = WorkoutSet(
      id: widget.set.id,
      setNumber: widget.set.setNumber,
      weight: weight,
      reps: reps,
      isCompleted: widget.set.isCompleted,
      rpe: clearRpe ? null : (customRpe ?? widget.set.rpe),
    );
    ref
        .read(activeWorkoutProvider.notifier)
        .updateSet(widget.workoutExerciseId, updated);
  }

  void _applyPreviousSet() {
    final prev = widget.previousSet;
    if (prev == null) return;
    _weightController.text = prev.weight.toStringAsFixed(
      prev.weight.truncateToDouble() == prev.weight ? 0 : 1,
    );
    _repsController.text = prev.reps.toString();
    _saveInputs();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.set.isCompleted;
    final prev = widget.previousSet;
    final prevText = prev != null
        ? '${prev.weight.toStringAsFixed(prev.weight.truncateToDouble() == prev.weight ? 0 : 1)}kg × ${prev.reps}'
        : '-';

    return Dismissible(
      key: ValueKey(widget.set.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red.shade900,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        ref
            .read(activeWorkoutProvider.notifier)
            .removeSet(widget.workoutExerciseId, widget.set.id);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color:
              isDone ? Colors.green.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Set number badge
            SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  '${widget.set.setNumber}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        isDone ? AppTheme.secondaryColor : AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
            // Previous (tappable to copy!)
            Expanded(
              flex: 3,
              child: InkWell(
                onTap: prev != null ? _applyPreviousSet : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Text(
                    prevText,
                    style: TextStyle(
                      fontSize: 12,
                      color: prev != null
                          ? AppTheme.primaryColor.withValues(alpha: 0.9)
                          : AppTheme.textSecondary,
                      decoration:
                          prev != null ? TextDecoration.underline : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            // Weight field
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: TextField(
                  controller: _weightController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '0',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    fillColor:
                        isDone ? Colors.black26 : AppTheme.surfaceElevated,
                  ),
                  onChanged: (_) => _saveInputs(),
                ),
              ),
            ),
            // Reps field
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: TextField(
                  controller: _repsController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '0',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    fillColor:
                        isDone ? Colors.black26 : AppTheme.surfaceElevated,
                  ),
                  onChanged: (_) => _saveInputs(),
                ),
              ),
            ),
            // Optional RPE selector
            SizedBox(
              width: 36,
              child: PopupMenuButton<double>(
                tooltip: 'RPE (nehézség 6-10)',
                padding: EdgeInsets.zero,
                onSelected: (val) {
                  if (val == 0) {
                    _saveInputs(clearRpe: true);
                  } else {
                    _saveInputs(customRpe: val);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 0, child: Text('Nincs RPE')),
                  const PopupMenuItem(value: 7, child: Text('RPE 7 (3 tartalék)')),
                  const PopupMenuItem(value: 8, child: Text('RPE 8 (2 tartalék)')),
                  const PopupMenuItem(value: 9, child: Text('RPE 9 (1 tartalék)')),
                  const PopupMenuItem(value: 10, child: Text('RPE 10 (bukásig)')),
                ],
                child: Container(
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.set.rpe != null
                        ? widget.set.rpe!.toStringAsFixed(0)
                        : '-',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: widget.set.rpe != null
                          ? Colors.amber
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            // Checkmark button
            SizedBox(
              width: 40,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: isDone
                        ? AppTheme.secondaryColor
                        : AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.check,
                    size: 18,
                    color: isDone ? Colors.black : Colors.white60,
                  ),
                ),
                onPressed: () {
                  _saveInputs();
                  ref
                      .read(activeWorkoutProvider.notifier)
                      .toggleSetCompleted(
                          widget.workoutExerciseId, widget.set.id);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExerciseModal extends ConsumerStatefulWidget {
  const _AddExerciseModal();

  @override
  ConsumerState<_AddExerciseModal> createState() => _AddExerciseModalState();
}

class _AddExerciseModalState extends ConsumerState<_AddExerciseModal> {
  String _search = '';
  MuscleGroup? _selectedGroup;

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exercisesProvider);

    final filtered = exercises.where((e) {
      final matchesSearch =
          e.name.toLowerCase().contains(_search.toLowerCase());
      final matchesGroup =
          _selectedGroup == null || e.category == _selectedGroup;
      return matchesSearch && matchesGroup;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Gyakorlat hozzáadása',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              // Search input
              TextField(
                decoration: InputDecoration(
                  hintText: 'Keresés gyakorlat neve alapján...',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  fillColor: AppTheme.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _search = val),
              ),
              const SizedBox(height: 10),
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Mind'),
                      selected: _selectedGroup == null,
                      onSelected: (_) => setState(() => _selectedGroup = null),
                    ),
                    const SizedBox(width: 6),
                    ...MuscleGroup.values.map((mg) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: FilterChip(
                          label: Text(mg.label),
                          selected: _selectedGroup == mg,
                          onSelected: (_) =>
                              setState(() => _selectedGroup = mg),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              // List
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'Nincs találat',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) {
                          final ex = filtered[idx];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            title: Text(
                              ex.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              ex.category.label,
                              style: const TextStyle(
                                  fontSize: 12, color: AppTheme.primaryColor),
                            ),
                            trailing: const Icon(Icons.add_circle_outline,
                                color: AppTheme.primaryColor),
                            onTap: () {
                              ref
                                  .read(activeWorkoutProvider.notifier)
                                  .addExerciseToWorkout(ex);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkoutSummaryDialog extends StatelessWidget {
  final WorkoutSession session;
  final Map<String, double> newPRs;

  const _WorkoutSummaryDialog({
    required this.session,
    required this.newPRs,
  });

  @override
  Widget build(BuildContext context) {
    final duration = session.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final durationStr = hours > 0 ? '$hours ó $minutes p' : '$minutes perc';

    return Dialog(
      backgroundColor: AppTheme.surfaceBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppTheme.secondaryColor,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Szép munka! Edzés befejezve! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              session.title,
              style: const TextStyle(
                  color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryStat(
                  label: 'Időtartam',
                  value: durationStr,
                  icon: Icons.timer_outlined,
                ),
                _SummaryStat(
                  label: 'Összvolumen',
                  value:
                      '${NumberFormat('#,##0').format(session.totalVolume)} kg',
                  icon: Icons.fitness_center_rounded,
                ),
                _SummaryStat(
                  label: 'Sorozatok',
                  value: '${session.totalCompletedSets} db',
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
            if (newPRs.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.military_tech, color: Colors.amber, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Új Egyéni Rekordok (PR)!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...newPRs.entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          '${e.key}: ${e.value.toStringAsFixed(e.value.truncateToDouble() == e.value ? 0 : 1)} kg',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Rendben'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: AppTheme.textSecondary),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../models/workout_template.dart';
import '../providers/workout_providers.dart';
import '../theme/app_theme.dart';
import 'active_workout_screen.dart';

class WorkoutHubScreen extends ConsumerWidget {
  const WorkoutHubScreen({super.key});

  void _openActiveWorkout(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
    );
  }

  void _showTemplateEditorModal(
    BuildContext context, {
    WorkoutTemplate? existingTemplate,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _TemplateEditorSheet(existingTemplate: existingTemplate),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWorkout = ref.watch(activeWorkoutProvider);
    final templates = ref.watch(templatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.fitness_center, color: AppTheme.primaryColor),
            SizedBox(width: 10),
            Text('FitLog Edzés'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ACTIVE WORKOUT RESUME BANNER
          if (activeWorkout != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_fill, size: 40, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Folyamatban lévő edzés!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          activeWorkout.title,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _openActiveWorkout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Megnyitás'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // QUICK START CARD
          Card(
            color: AppTheme.surfaceElevated,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gyors Indítás',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Kezdj egy üres edzést és add hozzá a gyakorlatokat tetszőlegesen menet közben.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (activeWorkout != null) {
                          _openActiveWorkout(context);
                        } else {
                          ref
                              .read(activeWorkoutProvider.notifier)
                              .startEmptyWorkout(title: 'Szabad edzés');
                          _openActiveWorkout(context);
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: Text(
                        activeWorkout != null
                            ? 'Aktív edzés folytatása'
                            : 'Új üres edzés indítása',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // TEMPLATES HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edzéssablonok & Tervek',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _showTemplateEditorModal(context),
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Új sablon'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // TEMPLATES LIST
          if (templates.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Nincs mentett edzéssablon',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ...templates.map((tpl) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tpl.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Sablon szerkesztése',
                            icon: const Icon(Icons.edit_outlined,
                                size: 18, color: AppTheme.textSecondary),
                            onPressed: () => _showTemplateEditorModal(
                              context,
                              existingTemplate: tpl,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Sablon törlése',
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.grey),
                            onPressed: () {
                              ref
                                  .read(templatesProvider.notifier)
                                  .deleteTemplate(tpl.id);
                            },
                          ),
                        ],
                      ),
                      if (tpl.description != null && tpl.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          tpl.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      if (tpl.exercises.isEmpty)
                        const Text(
                          'Nincs gyakorlat rendelve a sablonhoz (kattints a szerkesztésre!)',
                          style: TextStyle(fontSize: 12, color: Colors.orangeAccent),
                        )
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: tpl.exercises.map((e) {
                            return Chip(
                              label: Text(
                                '${e.exerciseName} (${e.targetSets}×)',
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: AppTheme.surfaceElevated,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              visualDensity: VisualDensity.compact,
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ref
                                .read(activeWorkoutProvider.notifier)
                                .startFromTemplate(tpl);
                            _openActiveWorkout(context);
                          },
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Edzés indítása ezzel a sablonnal'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _TemplateEditorSheet extends ConsumerStatefulWidget {
  final WorkoutTemplate? existingTemplate;

  const _TemplateEditorSheet({this.existingTemplate});

  @override
  ConsumerState<_TemplateEditorSheet> createState() => _TemplateEditorSheetState();
}

class _TemplateEditorSheetState extends ConsumerState<_TemplateEditorSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late List<TemplateExercise> _selectedExercises;
  MuscleGroup? _filterGroup;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingTemplate?.name ?? '');
    _descController =
        TextEditingController(text: widget.existingTemplate?.description ?? '');
    _selectedExercises = List<TemplateExercise>.from(
      widget.existingTemplate?.exercises ?? [],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addExercise(Exercise ex) {
    setState(() {
      _selectedExercises.add(
        TemplateExercise(
          exerciseId: ex.id,
          exerciseName: ex.name,
          category: ex.category.label,
          targetSets: 3,
          defaultRestSeconds: 90,
        ),
      );
    });
  }

  void _updateTargetSets(int index, int delta) {
    setState(() {
      final current = _selectedExercises[index];
      final newSets = (current.targetSets + delta).clamp(1, 15);
      _selectedExercises[index] = TemplateExercise(
        exerciseId: current.exerciseId,
        exerciseName: current.exerciseName,
        category: current.category,
        targetSets: newSets,
        defaultRestSeconds: current.defaultRestSeconds,
      );
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kérlek adj meg egy sablon nevet!')),
      );
      return;
    }

    final template = WorkoutTemplate(
      id: widget.existingTemplate?.id ?? const Uuid().v4(),
      name: name,
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      exercises: _selectedExercises,
    );

    ref.read(templatesProvider.notifier).saveTemplate(template);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final allExercises = ref.watch(exercisesProvider);
    final filteredCatalog = allExercises.where((e) {
      final matchesSearch =
          e.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGroup = _filterGroup == null || e.category == _filterGroup;
      return matchesSearch && matchesGroup;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingTemplate == null
                        ? 'Új edzéssablon összeállítása'
                        : 'Sablon szerkesztése',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Mentés'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Sablon neve (pl. A nap - Mell & Kar)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: 'Rövid leírás (opcionális)',
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Selected exercises in template
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Kiválasztott gyakorlatok (${_selectedExercises.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_selectedExercises.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Válassz gyakorlatokat az alábbi listából a sablonhoz!',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      )
                    else
                      ...List.generate(_selectedExercises.length, (idx) {
                        final item = _selectedExercises[idx];
                        return Card(
                          color: AppTheme.surfaceElevated,
                          margin: const EdgeInsets.only(bottom: 6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${idx + 1}. ${item.exerciseName}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        item.category,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline,
                                      size: 20),
                                  onPressed: () => _updateTargetSets(idx, -1),
                                ),
                                Text(
                                  '${item.targetSets} szett',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline,
                                      size: 20),
                                  onPressed: () => _updateTargetSets(idx, 1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close,
                                      size: 18, color: Colors.redAccent),
                                  onPressed: () {
                                    setState(() {
                                      _selectedExercises.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),

                    const Divider(height: 28, color: AppTheme.dividerColor),

                    const Text(
                      'Gyakorlat hozzáadása a könyvtárból:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Gyakorlat keresése...',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          FilterChip(
                            label: const Text('Mind'),
                            selected: _filterGroup == null,
                            onSelected: (_) =>
                                setState(() => _filterGroup = null),
                          ),
                          const SizedBox(width: 6),
                          ...MuscleGroup.values.map((mg) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: FilterChip(
                                label: Text(mg.label),
                                selected: _filterGroup == mg,
                                onSelected: (_) =>
                                    setState(() => _filterGroup = mg),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...filteredCatalog.map((ex) {
                      return ListTile(
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 4),
                        title: Text(ex.name),
                        subtitle: Text(
                          ex.category.label,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.primaryColor),
                        ),
                        trailing: OutlinedButton.icon(
                          onPressed: () => _addExercise(ex),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Hozzáad'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

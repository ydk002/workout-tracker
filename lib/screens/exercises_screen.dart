import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise.dart';
import '../providers/workout_providers.dart';
import '../theme/app_theme.dart';

class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  String _searchQuery = '';
  MuscleGroup? _selectedGroup;

  void _showExerciseEditorDialog(BuildContext context, {Exercise? existing}) {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    MuscleGroup selectedCategory = existing?.category ?? MuscleGroup.chest;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppTheme.surfaceBg,
          title: Text(
            existing == null
                ? 'Új gyakorlat létrehozása'
                : 'Gyakorlat szerkesztése',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Gyakorlat neve',
                    hintText: 'Pl. Bolgár guggolás',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Izomcsoport:',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<MuscleGroup>(
                  initialValue: selectedCategory,
                  dropdownColor: AppTheme.surfaceElevated,
                  items: MuscleGroup.values.map((mg) {
                    return DropdownMenuItem(
                      value: mg,
                      child: Text(mg.label),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setModalState(() => selectedCategory = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Megjegyzés / Technikai tipp (opcionális)',
                    hintText: 'Pl. Padállás 30 fok, könyök 45 fokban...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mégse'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final notes = notesController.text.trim();
                final updatedOrNew = Exercise(
                  id: existing?.id ?? const Uuid().v4(),
                  name: name,
                  category: selectedCategory,
                  notes: notes.isEmpty ? null : notes,
                  isCustom: existing?.isCustom ?? true,
                );

                if (existing == null) {
                  ref.read(exercisesProvider.notifier).addExercise(updatedOrNew);
                } else {
                  ref
                      .read(exercisesProvider.notifier)
                      .updateExercise(updatedOrNew);
                }
                Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Hozzáadás' : 'Mentés'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(exercisesProvider);
    final prs = ref.watch(personalRecordsProvider);

    final filtered = exercises.where((e) {
      final matchesSearch =
          e.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesGroup =
          _selectedGroup == null || e.category == _selectedGroup;
      return matchesSearch && matchesGroup;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gyakorlattár'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            tooltip: 'Új gyakorlat',
            onPressed: () => _showExerciseEditorDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Keresés gyakorlat neve szerint...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Categories horizontal scroll
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: const Text('Mind'),
                    selected: _selectedGroup == null,
                    onSelected: (_) => setState(() => _selectedGroup = null),
                  ),
                ),
                ...MuscleGroup.values.map((mg) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(mg.label),
                      selected: _selectedGroup == mg,
                      onSelected: (_) => setState(() => _selectedGroup = mg),
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'Nincs a keresésnek megfelelő gyakorlat',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final ex = filtered[index];
                      final prWeight = prs[ex.name];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.surfaceElevated,
                            child: const Icon(
                              Icons.fitness_center,
                              color: AppTheme.primaryColor,
                              size: 18,
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  ex.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (prWeight != null && prWeight > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'PR: ${prWeight.toStringAsFixed(prWeight.truncateToDouble() == prWeight ? 0 : 1)} kg',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ex.category.label,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              if (ex.notes != null && ex.notes!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    ex.notes!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Szerkesztés',
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18, color: AppTheme.textSecondary),
                                onPressed: () => _showExerciseEditorDialog(
                                    context,
                                    existing: ex),
                              ),
                              if (ex.isCustom)
                                IconButton(
                                  tooltip: 'Törlés',
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18, color: Colors.grey),
                                  onPressed: () {
                                    ref
                                        .read(exercisesProvider.notifier)
                                        .deleteExercise(ex.id);
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        tooltip: 'Új gyakorlat',
        onPressed: () => _showExerciseEditorDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

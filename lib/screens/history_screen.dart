import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/workout_session.dart';
import '../providers/workout_providers.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  late DateTime _displayedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
        1,
      );
      _selectedDay = null;
    });
  }

  void _showDeleteConfirm(BuildContext context, WorkoutSession session) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceBg,
        title: const Text('Edzés törlése'),
        content: Text(
          'Biztosan törölni szeretnéd a(z) "${session.title}" edzést az előzményekből?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mégse'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade800),
            onPressed: () {
              ref.read(sessionsProvider.notifier).deleteSession(session.id);
              Navigator.pop(ctx);
            },
            child: const Text('Törlés'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider);
    final prs = ref.watch(personalRecordsProvider);

    final filteredSessions = _selectedDay == null
        ? sessions
        : sessions
            .where((s) => _isSameDay(s.startTime, _selectedDay!))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edzésnapló és Előzmények'),
        actions: [
          if (_selectedDay != null)
            TextButton.icon(
              onPressed: () => setState(() => _selectedDay = null),
              icon: const Icon(Icons.filter_alt_off, size: 16),
              label: const Text('Összes'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // MONTHLY CALENDAR OVERVIEW CARD
          _MonthCalendarCard(
            displayedMonth: _displayedMonth,
            selectedDay: _selectedDay,
            sessions: sessions,
            onPrevMonth: () => _changeMonth(-1),
            onNextMonth: () => _changeMonth(1),
            onSelectDay: (day) {
              setState(() {
                if (_selectedDay != null && _isSameDay(_selectedDay!, day)) {
                  _selectedDay = null;
                } else {
                  _selectedDay = day;
                }
              });
            },
          ),

          const SizedBox(height: 16),

          // LIST HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedDay == null
                    ? 'Korábbi edzések (${sessions.length})'
                    : 'Edzések ekkor: ${DateFormat('yyyy. MMM d.', 'hu').format(_selectedDay!)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (filteredSessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 52,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedDay == null
                          ? 'Még nincsenek korábbi edzések'
                          : 'Ezen a napon nem volt rögzített edzés',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filteredSessions.map((session) {
              return _HistorySessionCard(
                session: session,
                personalRecords: prs,
                onDelete: () => _showDeleteConfirm(context, session),
              );
            }),
        ],
      ),
    );
  }
}

class _MonthCalendarCard extends StatelessWidget {
  final DateTime displayedMonth;
  final DateTime? selectedDay;
  final List<WorkoutSession> sessions;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDay;

  const _MonthCalendarCard({
    required this.displayedMonth,
    required this.selectedDay,
    required this.sessions,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final year = displayedMonth.year;
    final month = displayedMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Monday = 1 ... Sunday = 7
    final leadingEmptyDays = firstDayOfMonth.weekday - 1;

    final workoutDays = <int>{};
    for (final s in sessions) {
      if (s.startTime.year == year && s.startTime.month == month) {
        workoutDays.add(s.startTime.day);
      }
    }

    const weekDays = ['H', 'K', 'Sze', 'Cs', 'P', 'Szo', 'V'];
    final today = DateTime.now();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            // Month navigation header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: onPrevMonth,
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  DateFormat('yyyy. MMMM', 'hu')
                      .format(displayedMonth)
                      .toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.8,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: onNextMonth,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Weekday labels
            Row(
              children: weekDays.map((label) {
                return Expanded(
                  child: Center(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            // Days Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: leadingEmptyDays + daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 1.15,
              ),
              itemBuilder: (context, index) {
                if (index < leadingEmptyDays) {
                  return const SizedBox.shrink();
                }
                final dayNum = index - leadingEmptyDays + 1;
                final dayDate = DateTime(year, month, dayNum);
                final hasWorkout = workoutDays.contains(dayNum);
                final isSelected = selectedDay != null &&
                    selectedDay!.year == year &&
                    selectedDay!.month == month &&
                    selectedDay!.day == dayNum;
                final isToday = today.year == year &&
                    today.month == month &&
                    today.day == dayNum;

                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onSelectDay(dayDate),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : hasWorkout
                              ? AppTheme.secondaryColor.withValues(alpha: 0.16)
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isToday
                          ? Border.all(color: AppTheme.primaryColor, width: 1.5)
                          : hasWorkout
                              ? Border.all(
                                  color: AppTheme.secondaryColor
                                      .withValues(alpha: 0.5))
                              : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$dayNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: hasWorkout || isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? Colors.white
                                : hasWorkout
                                    ? AppTheme.secondaryColor
                                    : AppTheme.textPrimary,
                          ),
                        ),
                        if (hasWorkout)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.secondaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HistorySessionCard extends StatefulWidget {
  final WorkoutSession session;
  final Map<String, double> personalRecords;
  final VoidCallback onDelete;

  const _HistorySessionCard({
    required this.session,
    required this.personalRecords,
    required this.onDelete,
  });

  @override
  State<_HistorySessionCard> createState() => _HistorySessionCardState();
}

class _HistorySessionCardState extends State<_HistorySessionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final dateStr =
        DateFormat('yyyy. MMMM d., EEEE', 'hu').format(session.startTime);
    final timeStr = DateFormat('HH:mm').format(session.startTime);
    final duration = session.duration;
    final minutes = duration.inMinutes;

    // Check if any exercise in this session hit an all-time PR
    final hasAnyPR = session.exercises.any((ex) {
      final pr = widget.personalRecords[ex.exerciseName];
      return pr != null && pr > 0 && ex.maxWeight >= pr;
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                session.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (hasAnyPR) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.emoji_events,
                                        size: 12, color: Colors.amber),
                                    SizedBox(width: 3),
                                    Text(
                                      'PR',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$dateStr • $timeStr',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Colors.grey),
                    onPressed: widget.onDelete,
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Badges
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Badge(
                    icon: Icons.timer_outlined,
                    label: minutes > 0 ? '$minutes perc' : '< 1 perc',
                  ),
                  _Badge(
                    icon: Icons.fitness_center_rounded,
                    label:
                        '${NumberFormat('#,##0').format(session.totalVolume)} kg',
                  ),
                  _Badge(
                    icon: Icons.repeat_rounded,
                    label: '${session.totalCompletedSets} szett',
                  ),
                ],
              ),

              if (session.notes != null && session.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '📝 ${session.notes!}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],

              // Expanded Details
              if (_expanded) ...[
                const Divider(color: AppTheme.dividerColor, height: 24),
                ...session.exercises.map((ex) {
                  final prWeight = widget.personalRecords[ex.exerciseName];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex.exerciseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children:
                              ex.sets.where((s) => s.isCompleted).map((s) {
                            final isPRSet = prWeight != null &&
                                prWeight > 0 &&
                                s.weight >= prWeight;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPRSet
                                    ? Colors.amber.withValues(alpha: 0.15)
                                    : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                                border: isPRSet
                                    ? Border.all(
                                        color:
                                            Colors.amber.withValues(alpha: 0.6))
                                    : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isPRSet) ...[
                                    const Icon(Icons.emoji_events,
                                        size: 12, color: Colors.amber),
                                    const SizedBox(width: 4),
                                  ],
                                  Text(
                                    '${s.weight > 0 ? '${s.weight.toStringAsFixed(s.weight.truncateToDouble() == s.weight ? 0 : 1)}kg × ' : ''}${s.reps}${s.rpe != null ? ' (RPE ${s.rpe!.toStringAsFixed(0)})' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isPRSet
                                          ? Colors.amber
                                          : AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/workout_providers.dart';
import '../theme/app_theme.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  String? _selectedExerciseName;
  bool _showEstimated1RM = false; // false = Max Weight, true = Est. 1RM

  @override
  Widget build(BuildContext context) {
    final sessions = ref.watch(sessionsProvider);
    final prs = ref.watch(personalRecordsProvider);

    if (sessions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Statisztikák')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.insights_rounded,
                  size: 64,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nincs elegendő adat a statisztikákhoz',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Rögzíts legalább 1 befejezett edzést a grafikonok megjelenítéséhez!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalWorkouts = sessions.length;
    final totalAllTimeVolume =
        sessions.fold(0.0, (sum, s) => sum + s.totalVolume);
    final avgDurationMinutes = totalWorkouts > 0
        ? (sessions.fold(0, (sum, s) => sum + s.duration.inMinutes) /
                totalWorkouts)
            .round()
        : 0;

    // Last 7 sessions for volume chart in chronological order
    final recentSessions = sessions.take(7).toList().reversed.toList();

    // Available exercises that have recorded sets
    final availableExercises = prs.keys.toList()..sort();
    final activeExercise =
        (_selectedExerciseName != null &&
                availableExercises.contains(_selectedExerciseName))
            ? _selectedExerciseName!
            : (availableExercises.isNotEmpty ? availableExercises.first : null);

    final progressionPoints = activeExercise != null
        ? ref.watch(exerciseProgressionProvider(activeExercise))
        : <ExerciseProgressionPoint>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Fejlődés és Statisztikák')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SUMMARY CARDS ROW
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Összes edzés',
                  value: '$totalWorkouts db',
                  icon: Icons.fitness_center_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  title: 'Összvolumen',
                  value: totalAllTimeVolume >= 1000
                      ? '${(totalAllTimeVolume / 1000).toStringAsFixed(1)} t'
                      : '${totalAllTimeVolume.round()} kg',
                  icon: Icons.trending_up_rounded,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  title: 'Átlagos idő',
                  value: '$avgDurationMinutes perc',
                  icon: Icons.timer_outlined,
                  color: Colors.cyanAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // VOLUME PROGRESSION CHART (BarChart)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edzésvolumen alakulása (utolsó 7 edzés)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Össz. megmozgatott súly (kg)',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: recentSessions.isNotEmpty
                            ? (recentSessions
                                    .map((s) => s.totalVolume)
                                    .reduce((a, b) => a > b ? a : b) *
                                1.25)
                            : 1000,
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final session = recentSessions[group.x.toInt()];
                              return BarTooltipItem(
                                '${session.title}\n${NumberFormat('#,##0').format(rod.toY)} kg',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                final index = val.toInt();
                                if (index >= 0 && index < recentSessions.length) {
                                  final s = recentSessions[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      DateFormat('MM.dd').format(s.startTime),
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              getTitlesWidget: (val, meta) {
                                if (val == 0) return const SizedBox.shrink();
                                return Text(
                                  val >= 1000
                                      ? '${(val / 1000).toStringAsFixed(0)}k'
                                      : '${val.toInt()}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (val) => const FlLine(
                            color: AppTheme.dividerColor,
                            strokeWidth: 1,
                          ),
                        ),
                        barGroups: [
                          for (int i = 0; i < recentSessions.length; i++)
                            BarChartGroupData(
                              x: i,
                              barRods: [
                                BarChartRodData(
                                  toY: recentSessions[i].totalVolume,
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor,
                                      Color(0xFFFF9800),
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  width: 22,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // EXERCISE-SPECIFIC PROGRESSION CURVE (LineChart)
          if (availableExercises.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gyakorlat-specifikus fejlődési görbe',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: activeExercise,
                      dropdownColor: AppTheme.surfaceElevated,
                      decoration: const InputDecoration(
                        labelText: 'Válassz gyakorlatot',
                        prefixIcon: Icon(Icons.fitness_center, size: 18),
                      ),
                      items: availableExercises.map((exName) {
                        return DropdownMenuItem(
                          value: exName,
                          child: Text(exName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedExerciseName = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Max Súly (kg)'),
                          selected: !_showEstimated1RM,
                          onSelected: (_) =>
                              setState(() => _showEstimated1RM = false),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Becsült 1RM (kg)'),
                          selected: _showEstimated1RM,
                          onSelected: (_) =>
                              setState(() => _showEstimated1RM = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (progressionPoints.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Nincs megjeleníthető adat ehhez a gyakorlathoz.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            minY: 0,
                            maxY: (progressionPoints
                                        .map((p) => _showEstimated1RM
                                            ? p.estimated1RM
                                            : p.maxWeight)
                                        .reduce((a, b) => a > b ? a : b) *
                                    1.2)
                                .clamp(10.0, double.infinity),
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    final idx = spot.x.toInt();
                                    final pt = progressionPoints[idx];
                                    final dateStr =
                                        DateFormat('MM.dd').format(pt.date);
                                    return LineTooltipItem(
                                      '$dateStr\n${spot.y.toStringAsFixed(1)} kg',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (val) => const FlLine(
                                color: AppTheme.dividerColor,
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (val, meta) {
                                    if (val == 0) return const SizedBox.shrink();
                                    return Text(
                                      '${val.toInt()}',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 10,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (val, meta) {
                                    final idx = val.toInt();
                                    if (idx >= 0 &&
                                        idx < progressionPoints.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          DateFormat('MM.dd')
                                              .format(progressionPoints[idx].date),
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  for (int i = 0;
                                      i < progressionPoints.length;
                                      i++)
                                    FlSpot(
                                      i.toDouble(),
                                      _showEstimated1RM
                                          ? progressionPoints[i].estimated1RM
                                          : progressionPoints[i].maxWeight,
                                    ),
                                ],
                                isCurved: true,
                                color: AppTheme.secondaryColor,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: AppTheme.secondaryColor
                                      .withValues(alpha: 0.15),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // PERSONAL RECORDS (PR)
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Colors.amber),
              SizedBox(width: 8),
              Text(
                'Egyéni Rekordok (PR Dicsőségtábla)',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (prs.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Még nem értél el egyéni rekordot.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ...prs.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: Text(
                    '${entry.value.toStringAsFixed(entry.value.truncateToDouble() == entry.value ? 0 : 1)} kg',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/workout_providers.dart';
import '../theme/app_theme.dart';

class RestTimerBanner extends ConsumerWidget {
  const RestTimerBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(restTimerProvider);

    if (!timerState.isRunning && timerState.remainingSeconds <= 0) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_outlined,
                size: 18, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            const Text(
              'Gyors pihenő:',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const Spacer(),
            ...[60, 90, 120].map((sec) {
              return Padding(
                padding: const EdgeInsets.only(left: 6.0),
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () =>
                      ref.read(restTimerProvider.notifier).startTimer(sec),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${sec}s',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    }

    final minutes = timerState.remainingSeconds ~/ 60;
    final seconds = timerState.remainingSeconds % 60;
    final timeStr =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final progress = timerState.totalSeconds > 0
        ? (timerState.remainingSeconds / timerState.totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Pihenőidő:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade300,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ref.read(restTimerProvider.notifier).addSeconds(30);
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.surfaceBg,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '+30s',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  ref.read(restTimerProvider.notifier).stop();
                },
                icon: const Icon(Icons.close, size: 20, color: Colors.white60),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.dividerColor,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

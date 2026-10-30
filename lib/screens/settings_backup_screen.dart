import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/workout_providers.dart';
import '../services/downloader/file_downloader.dart';
import '../theme/app_theme.dart';

class SettingsBackupScreen extends ConsumerStatefulWidget {
  const SettingsBackupScreen({super.key});

  @override
  ConsumerState<SettingsBackupScreen> createState() => _SettingsBackupScreenState();
}

class _SettingsBackupScreenState extends ConsumerState<SettingsBackupScreen> {
  bool _isLoading = false;

  void _exportBackup() {
    final db = ref.read(databaseServiceProvider);
    final jsonStr = db.exportBackupJson();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = 'fitlog_backup_$timestamp.json';

    if (kIsWeb) {
      try {
        downloadWebJson(jsonStr, fileName);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sikeres letöltés: $fileName'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      } catch (e) {
        // fallback to clipboard
        _copyToClipboard(jsonStr);
      }
    } else {
      _copyToClipboard(jsonStr);
    }
  }

  void _copyToClipboard(String jsonStr) {
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('A mentés vágólapra másolva!'),
        backgroundColor: AppTheme.secondaryColor,
      ),
    );
  }

  Future<void> _pickAndImportFile() async {
    setState(() => _isLoading = true);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (files.isNotEmpty) {
        final jsonString = await files.first.xFile.readAsString();
        await _processImport(jsonString);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hiba történt a fájl megnyitásakor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processImport(String jsonString) async {
    final db = ref.read(databaseServiceProvider);
    final success = await db.importBackupJson(jsonString);

    if (mounted) {
      if (success) {
        // Reload all providers
        ref.read(exercisesProvider.notifier).load();
        ref.read(sessionsProvider.notifier).load();
        ref.read(templatesProvider.notifier).load();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Az adatok sikeresen visszaállítva!'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Érvénytelen FitLog mentési formátum!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPasteJsonDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceBg,
        title: const Text('JSON beillesztése'),
        content: SizedBox(
          width: 400,
          child: TextField(
            controller: textController,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Illeszd be a korábban kimásolt JSON szöveget...',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mégse'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = textController.text.trim();
              Navigator.pop(ctx);
              if (text.isNotEmpty) {
                await _processImport(text);
              }
            },
            child: const Text('Betöltés'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Beállítások & Biztonsági Mentés')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // OFFLINE BADGE
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: AppTheme.secondaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '100% Offline & Privát',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Az összes edzésed és adatod kizárólag a böngésződ / eszközöd helyi memóriájában tárolódik.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // EXPORT CARD
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.file_download_outlined, color: AppTheme.primaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Adatok Mentése (Export)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Töltsd le az összes edzést, sablont és gyakorlatot egyetlen .json fájlba, hogy soha ne veszítsd el őket!',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _exportBackup,
                          icon: const Icon(Icons.download),
                          label: const Text('JSON Letöltése'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        tooltip: 'Másolás vágólapra',
                        onPressed: () {
                          final db = ref.read(databaseServiceProvider);
                          _copyToClipboard(db.exportBackupJson());
                        },
                        icon: const Icon(Icons.copy),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // IMPORT CARD
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.file_upload_outlined, color: AppTheme.secondaryColor),
                      SizedBox(width: 8),
                      Text(
                        'Adatok Visszaállítása (Import)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Költöztess át korábban elmentett adatokat egy másik telefonról vagy böngészőből.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _pickAndImportFile,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Fájl Kiválasztása'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _showPasteJsonDialog,
                        icon: const Icon(Icons.paste),
                        label: const Text('Beillesztés'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // PWA INSTALL INFO
          Card(
            color: AppTheme.surfaceElevated,
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📱 PWA Tipp okostelefonra:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Safari / Chrome böngészőben nyomj a "Megosztás" vagy "Menü" gombra, majd válaszd a "Hozzáadás a kezdőképernyőhöz" opciót. Így a FitLog teljes képernyős, natív appként fog futni ikonról!',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

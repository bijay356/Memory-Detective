import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';
import '../data/local_storage.dart';
import '../core/audio_manager.dart';
import '../models/player_stats.dart';
import '../providers/game_session_provider.dart';
import '../providers/game_providers.dart';
import '../ads/ad_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  void _editNameDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppTheme.background,
            title: const Text('Edit Detective Name',
                style: TextStyle(color: AppTheme.gold)),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white38)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.gold)),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL',
                    style: TextStyle(color: AppTheme.textSecondary)),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    ref
                        .read(settingsProvider.notifier)
                        .setDetectiveName(controller.text.trim());
                  }
                  Navigator.pop(context);
                },
                child:
                    const Text('SAVE', style: TextStyle(color: AppTheme.gold)),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS',
            style:
                TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassPanel(
            child: ListTile(
              leading: const Icon(Icons.badge, color: AppTheme.gold, size: 32),
              title: const Text('Detective Name',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              subtitle: Text(settings.detectiveName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              trailing: const Icon(Icons.edit, color: Colors.white54),
              onTap: () {
                _editNameDialog(settings.detectiveName);
              },
            ),
          ),
          const SizedBox(height: 24),
          ValueListenableBuilder<bool>(
            valueListenable: AdService.privacyOptionsRequired,
            builder: (context, isRequired, _) {
              if (!isRequired) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: GlassPanel(
                  child: ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined,
                        color: AppTheme.cyan),
                    title: const Text('Privacy choices'),
                    subtitle: const Text(
                      'Review or change your advertising consent.',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final error = await AdService.showPrivacyOptions();
                      if (error == null || !context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error.message)),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          GlassPanel(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Sound Effects'),
                  activeThumbColor: AppTheme.gold,
                  value: settings.soundEnabled,
                  onChanged: (v) {
                    settingsNotifier.toggleSound();
                    if (v) AudioManager.playClick();
                  },
                ),
                const Divider(color: Colors.white10),
                SwitchListTile(
                  title: const Text('Music'),
                  activeThumbColor: AppTheme.gold,
                  value: settings.musicEnabled,
                  onChanged: (v) {
                    settingsNotifier.toggleMusic();
                    if (!v) {
                      AudioManager.stopBackground();
                    } else {
                      AudioManager.playBackground();
                    }
                  },
                ),
                const Divider(color: Colors.white10),
                SwitchListTile(
                  title: const Text('Vibration'),
                  activeThumbColor: AppTheme.gold,
                  value: settings.vibrationEnabled,
                  onChanged: (v) {
                    settingsNotifier.toggleVibration();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassPanel(
            child: ListTile(
              title: const Text('Reset Progress',
                  style: TextStyle(color: Colors.red)),
              trailing: const Icon(Icons.warning, color: Colors.red),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.background,
                    title: const Text('Wipe All Data?',
                        style: TextStyle(color: Colors.red)),
                    content: const Text(
                        'This will erase all case files, decrypted sounds, and player stats. This cannot be undone.',
                        style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL',
                            style: TextStyle(color: AppTheme.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () async {
                          final freshStats = PlayerStats();
                          await LocalStorage.casesBox.clear();
                          await LocalStorage.achievementsBox.clear();
                          await LocalStorage.statsBox.clear();
                          await LocalStorage.statsBox.put('main', freshStats);

                          ref
                              .read(playerStatsProvider.notifier)
                              .updateStats(freshStats);
                          ref.invalidate(gameSessionProvider);

                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All progress has been wiped.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        },
                        child: const Text('WIPE DATA',
                            style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

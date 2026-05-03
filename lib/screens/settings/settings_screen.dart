import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_theme.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _openPrivacyPolicy() async {
    final url = Uri.parse('https://example.com/privacy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Streak Tracker',
      applicationVersion: '1.0.0',
      children: [
        const Text('A free Days Since tracker for Android.'),
      ],
    );
  }

  void _tellAFriend() {
    SharePlus.instance.share(ShareParams(text: 'Check out Streak Tracker! A free, no-ads habit tracker.'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600, color: context.textPrimary, fontSize: 17),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: kCardRadius,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.brightness_medium, color: kAccentBlue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Appearance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, label: Text('System')),
                      ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (Set<ThemeMode> newSelection) {
                      ref.read(themeModeProvider.notifier).setThemeMode(newSelection.first);
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith<Color>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.selected)) {
                            return kAccentBlue.withValues(alpha: 0.15);
                          }
                          return Colors.transparent;
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: kCardRadius,
            ),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Privacy Policy'),
                  trailing: Icon(Icons.chevron_right, color: context.textSecondary),
                  onTap: _openPrivacyPolicy,
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: context.dividerColor),
                ListTile(
                  title: const Text('About'),
                  trailing: Icon(Icons.chevron_right, color: context.textSecondary),
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: kCardRadius,
            ),
            child: ListTile(
              title: const Text('Tell a Friend'),
              trailing: Icon(Icons.chevron_right, color: context.textSecondary),
              onTap: _tellAFriend,
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: Text(
              'Streak Tracker 1.0.0 (build 1)',
              style: TextStyle(color: context.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

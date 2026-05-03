import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _CenteredTitleAppBar(title: 'Settings'),
      body: Center(child: Text('Settings')),
    );
  }
}

class _CenteredTitleAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;

  const _CenteredTitleAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

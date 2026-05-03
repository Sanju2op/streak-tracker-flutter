import 'package:flutter/material.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _CenteredTitleAppBar(title: 'Calendar'),
      body: Center(child: Text('Calendar')),
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

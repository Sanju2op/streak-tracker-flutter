import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RemindersScreen extends StatelessWidget {
  final String counterId;

  const RemindersScreen({super.key, required this.counterId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('Reminders'),
      ),
      body: Center(child: Text('Reminders: $counterId')),
    );
  }
}

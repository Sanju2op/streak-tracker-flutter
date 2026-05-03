import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GoalsScreen extends StatelessWidget {
  final String counterId;

  const GoalsScreen({super.key, required this.counterId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('Goals'),
      ),
      body: Center(child: Text('Goals: $counterId')),
    );
  }
}

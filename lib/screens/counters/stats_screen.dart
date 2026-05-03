import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StatsScreen extends StatelessWidget {
  final String counterId;

  const StatsScreen({super.key, required this.counterId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('Stats'),
      ),
      body: Center(child: Text('Stats: $counterId')),
    );
  }
}

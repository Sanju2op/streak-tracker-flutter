import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CounterDetailScreen extends StatelessWidget {
  final String id;

  const CounterDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('Counter Detail'),
      ),
      body: Center(child: Text('Counter Detail: $id')),
    );
  }
}

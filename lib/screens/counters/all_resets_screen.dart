import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AllResetsScreen extends StatelessWidget {
  final String counterId;

  const AllResetsScreen({super.key, required this.counterId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('All Resets'),
      ),
      body: Center(child: Text('All Resets: $counterId')),
    );
  }
}

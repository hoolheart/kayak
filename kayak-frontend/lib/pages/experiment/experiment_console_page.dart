import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExperimentConsolePage extends ConsumerWidget {
  const ExperimentConsolePage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Text('Experiment Console: $id'),
      ),
    );
  }
}

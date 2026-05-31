import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MethodEditPage extends ConsumerWidget {
  const MethodEditPage({super.key, this.id});

  final String? id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Text('Method Edit${id != null ? ': $id' : ' (New)'}'),
      ),
    );
  }
}

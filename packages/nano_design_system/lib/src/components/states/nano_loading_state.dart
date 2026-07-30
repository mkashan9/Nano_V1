import 'package:flutter/material.dart';
import '../../tokens/nano_spacing.dart';

class NanoLoadingState extends StatelessWidget {
  const NanoLoadingState({super.key, this.message = 'Loading'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: NanoSpacing.md),
          Text(message, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

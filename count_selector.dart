import 'package:flutter/material.dart';

/// Shows a bottom sheet letting the user pick how many questions they want
/// in the upcoming test session. Returns null if the user cancels.
Future<int?> pickQuestionCount(BuildContext context, {required int available}) {
  final options = <int>[10, 20, 30, 50, available]
      .where((n) => n <= available && n > 0)
      .toSet()
      .toList()
    ..sort();

  return showModalBottomSheet<int>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¿Cuántas preguntas quieres hacer?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Disponibles: $available',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: options.map((n) {
                  final label = n == available ? 'Todas ($n)' : '$n';
                  return ActionChip(
                    label: Text(label),
                    onPressed: () => Navigator.of(context).pop(n),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

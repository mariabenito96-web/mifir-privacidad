import 'package:flutter/material.dart';
import '../data/question_repository.dart';
import '../services/purchase_service.dart';
import '../widgets/count_selector.dart';
import '../widgets/paywall_dialog.dart';
import 'quiz_screen.dart';

class YearSelectScreen extends StatelessWidget {
  const YearSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = QuestionRepository.instance;
    final years = repo.years;
    final isPremium = PurchaseService.instance.isPremium;

    return Scaffold(
      appBar: AppBar(title: const Text('Elige una convocatoria')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: years.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final year = years[index];
          final count = repo.countByYear(year);
          final incomplete = count < 50;
          final locked = !isPremium && !kFreeYears.contains(year);
          return Card(
            child: ListTile(
              title: Row(
                children: [
                  Text('Examen FIR $year',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (locked) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.lock, size: 15, color: Color(0xFFB45309)),
                  ],
                ],
              ),
              subtitle: Text(locked
                  ? 'Función Premium'
                  : incomplete
                      ? '$count preguntas disponibles (convocatoria incompleta)'
                      : '$count preguntas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                if (locked) {
                  await showPaywallDialog(context);
                  return;
                }
                final selected = await pickQuestionCount(context, available: count);
                if (selected == null) return;
                final questions = repo.questionsByYear(year, limit: selected);
                if (!context.mounted) return;
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => QuizScreen(
                    questions: questions,
                    title: 'Examen FIR $year',
                  ),
                ));
              },
            ),
          );
        },
      ),
    );
  }
}

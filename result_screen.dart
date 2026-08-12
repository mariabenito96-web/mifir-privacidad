import 'package:flutter/material.dart';
import '../data/question_repository.dart';
import '../theme.dart';
import 'quiz_screen.dart';

class ResultScreen extends StatelessWidget {
  final int total;
  final int score;
  final List<int> failedIds;
  final int? blanks;
  final bool examMode;

  const ResultScreen({
    super.key,
    required this.total,
    required this.score,
    required this.failedIds,
    this.blanks,
    this.examMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : ((score / total) * 100).round();
    final passed = pct >= 50;
    final blanksCount = blanks ?? 0;
    final incorrectCount = total - score - blanksCount;
    // Fórmula habitual de corrección FIR: aciertos - errores/3 (los
    // blancos no penalizan).
    final estimatedScore = examMode
        ? (score - incorrectCount / 3).clamp(0, total)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Resultados'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                passed ? Icons.emoji_events : Icons.replay_circle_filled,
                size: 72,
                color: passed ? const Color(0xFFF59E0B) : AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text('$score / $total correctas',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('$pct% de acierto',
                  style: Theme.of(context).textTheme.titleMedium),
              if (examMode) ...[
                const SizedBox(height: 20),
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _StatBlock(label: 'Correctas', value: '$score'),
                            _StatBlock(label: 'Incorrectas', value: '$incorrectCount'),
                            _StatBlock(label: 'En blanco', value: '$blanksCount'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nota estimada: ${estimatedScore!.toStringAsFixed(2)} / $total',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Calculada como aciertos − errores/3 (fórmula habitual '
                          'de corrección del FIR); los blancos no penalizan.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              if (failedIds.isNotEmpty)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: Text(examMode
                        ? 'Repasar las ${failedIds.length} falladas o en blanco'
                        : 'Repasar las ${failedIds.length} falladas de este test'),
                    onPressed: () {
                      final questions =
                          QuestionRepository.instance.questionsByIds(failedIds);
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (_) => QuizScreen(
                          questions: questions,
                          title: 'Repaso rápido',
                        ),
                      ));
                    },
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Volver al inicio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

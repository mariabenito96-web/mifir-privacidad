import 'package:flutter/material.dart';
import '../data/question_repository.dart';
import '../services/purchase_service.dart';
import '../services/question_filter_service.dart';
import '../widgets/count_selector.dart';
import '../widgets/origin_selector.dart';
import '../widgets/paywall_dialog.dart';
import 'quiz_screen.dart';

class SubjectSelectScreen extends StatefulWidget {
  const SubjectSelectScreen({super.key});

  @override
  State<SubjectSelectScreen> createState() => _SubjectSelectScreenState();
}

class _SubjectSelectScreenState extends State<SubjectSelectScreen> {
  @override
  void initState() {
    super.initState();
    QuestionFilterService.instance.addListener(_refresh);
    PurchaseService.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    QuestionFilterService.instance.removeListener(_refresh);
    PurchaseService.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final repo = QuestionRepository.instance;
    final subjects = repo.subjects;
    final isPremium = PurchaseService.instance.isPremium;

    return Scaffold(
      appBar: AppBar(title: const Text('Elige una asignatura')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: subjects.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const OriginSelector();
          }
          final subject = subjects[index - 1];
          final locked = !isPremium && !kFreeSubjects.contains(subject);
          final count = repo.countBySubject(subject);
          return Card(
            child: ListTile(
              title: Row(
                children: [
                  Text(subject, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (locked) ...[
                    const SizedBox(width: 6),
                    const Icon(Icons.lock, size: 15, color: Color(0xFFB45309)),
                  ],
                ],
              ),
              subtitle: Text(locked
                  ? 'Función Premium'
                  : count == 0
                      ? 'Sin preguntas con el filtro actual'
                      : '$count preguntas'),
              trailing: const Icon(Icons.chevron_right),
              enabled: locked || count > 0,
              onTap: locked
                  ? () => showPaywallDialog(context)
                  : count == 0
                      ? null
                      : () async {
                          final selected = await pickQuestionCount(context, available: count);
                          if (selected == null) return;
                          final questions = repo.questionsBySubject(subject, limit: selected);
                          if (!context.mounted) return;
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => QuizScreen(questions: questions, title: subject),
                          ));
                        },
            ),
          );
        },
      ),
    );
  }
}

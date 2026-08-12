import 'package:flutter/material.dart';
import '../data/question_repository.dart';
import '../services/progress_service.dart';
import '../services/purchase_service.dart';
import '../services/question_filter_service.dart';
import '../services/ranking_service.dart';
import '../widgets/count_selector.dart';
import '../widgets/origin_selector.dart';
import '../widgets/paywall_dialog.dart';
import 'quiz_screen.dart';
import 'ranking_screen.dart';
import 'subject_select_screen.dart';
import 'year_select_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _refresh() => setState(() {});

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

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Resetear progreso?'),
        content: const Text(
          'Se borrará el porcentaje de acierto, el historial de preguntas '
          'contestadas y la lista de preguntas falladas. Esta acción no se '
          'puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Resetear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ProgressService.instance.resetAll();
      _refresh();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progreso reseteado.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = QuestionRepository.instance;
    final progress = ProgressService.instance;
    final filteredTotal = repo.filteredCount;
    final failedCount = progress.failedIds.length;
    final answered = progress.totalAnswered;
    final correct = progress.totalCorrect;
    final pct = answered == 0 ? 0 : ((correct / answered) * 100).round();
    final isPremium = PurchaseService.instance.isPremium;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MiFIR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.leaderboard_outlined),
            tooltip: 'Ranking',
            onPressed: () async {
              if (!isPremium) {
                await showPaywallDialog(context);
                return;
              }
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const RankingScreen(),
              ));
              _refresh();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tu progreso',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (answered > 0)
                          TextButton.icon(
                            onPressed: () => _confirmReset(context),
                            icon: const Icon(Icons.restart_alt, size: 18),
                            label: const Text('Resetear'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatBlock(label: 'Preguntas contestadas', value: '$answered'),
                        _StatBlock(label: 'Acierto', value: '$pct%'),
                        _StatBlock(label: 'Falladas guardadas', value: '$failedCount'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!isPremium) ...[
              _PremiumCard(onTap: () => showPaywallDialog(context)),
              const SizedBox(height: 16),
            ],
            const OriginSelector(),
            const SizedBox(height: 16),
            _ModeCard(
              icon: Icons.leaderboard_outlined,
              title: 'Ranking online',
              subtitle: !isPremium
                  ? 'Función Premium — compara tu progreso con otros usuarios'
                  : RankingService.instance.isConnected
                      ? 'Conectado como ${RankingService.instance.username}'
                      : 'Conéctate para ver el ranking general y por asignatura',
              locked: !isPremium,
              onTap: () async {
                if (!isPremium) {
                  await showPaywallDialog(context);
                  return;
                }
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const RankingScreen(),
                ));
                _refresh();
              },
            ),
            const SizedBox(height: 12),
            _ModeCard(
              icon: Icons.timer_outlined,
              title: 'Examen simulacro',
              subtitle: isPremium
                  ? '210 preguntas (200 + 10 de reserva) en 4h 30min, como el examen real'
                  : 'Función Premium — 210 preguntas cronometradas como el examen real',
              locked: !isPremium,
              onTap: () async {
                if (!isPremium) {
                  await showPaywallDialog(context);
                  return;
                }
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Examen simulacro'),
                    content: const Text(
                      'Vas a empezar un simulacro de 210 preguntas (200 + 10 de '
                      'reserva) con un límite de 4 horas y 30 minutos, igual que '
                      'el examen FIR real. No verás si aciertas o fallas hasta el '
                      'final. ¿Empezamos?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Empezar'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) return;
                final questions = repo.examSimulation();
                if (!context.mounted) return;
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => QuizScreen(
                    questions: questions,
                    title: 'Examen simulacro',
                    examMode: true,
                    timeLimit: const Duration(hours: 4, minutes: 30),
                  ),
                ));
                _refresh();
              },
            ),
            _ModeCard(
              icon: Icons.shuffle,
              title: 'Test aleatorio general',
              subtitle: isPremium
                  ? 'Preguntas al azar de todos los años y asignaturas'
                  : 'Gratis: preguntas de las convocatorias 2024 y 2025',
              onTap: () async {
                if (filteredTotal == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No hay preguntas con el filtro actual.')),
                  );
                  return;
                }
                final count = await pickQuestionCount(context, available: filteredTotal);
                if (count == null) return;
                final questions = repo.randomGeneral(limit: count);
                if (!context.mounted) return;
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => QuizScreen(questions: questions, title: 'Test aleatorio'),
                ));
                _refresh();
              },
            ),
            _ModeCard(
              icon: Icons.menu_book_outlined,
              title: 'Practicar por asignatura',
              subtitle: 'Elige un tema y practica solo esas preguntas',
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const SubjectSelectScreen(),
                ));
                _refresh();
              },
            ),
            _ModeCard(
              icon: Icons.calendar_month_outlined,
              title: 'Practicar por año',
              subtitle: 'Repite el examen completo de una convocatoria',
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const YearSelectScreen(),
                ));
                _refresh();
              },
            ),
            _ModeCard(
              icon: Icons.replay_circle_filled_outlined,
              title: 'Repasar falladas',
              subtitle: !isPremium
                  ? 'Función Premium — repasa automáticamente lo que vas fallando'
                  : failedCount == 0
                      ? 'Todavía no has fallado ninguna pregunta'
                      : 'Tienes $failedCount preguntas pendientes de repasar',
              enabled: isPremium && failedCount > 0,
              locked: !isPremium,
              onTap: !isPremium
                  ? () => showPaywallDialog(context)
                  : failedCount == 0
                      ? null
                      : () async {
                          final questions =
                              repo.questionsByIds(progress.failedIds);
                          if (!context.mounted) return;
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => QuizScreen(
                              questions: questions,
                              title: 'Repaso de falladas',
                            ),
                          ));
                          _refresh();
                        },
            ),
          ],
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
    return Expanded(
      child: Column(
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
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool locked;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE0F2F1),
                  child: Icon(icon, color: const Color(0xFF0F766E)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          if (locked) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.lock, size: 15, color: Color(0xFFB45309)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFEF3C7),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.workspace_premium, color: Color(0xFFB45309), size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hazte Premium',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF92400E))),
                    const SizedBox(height: 2),
                    const Text(
                      'Suscripción anual: todas las convocatorias, todas las asignaturas, '
                      'no oficiales, examen simulacro, repasar falladas y ranking',
                      style: TextStyle(color: Color(0xFF92400E)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF92400E)),
            ],
          ),
        ),
      ),
    );
  }
}

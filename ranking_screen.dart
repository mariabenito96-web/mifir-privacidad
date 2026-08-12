import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/question_repository.dart';
import '../services/progress_service.dart';
import '../services/ranking_service.dart';
import '../theme.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  @override
  Widget build(BuildContext context) {
    final ranking = RankingService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Ranking')),
      body: SafeArea(
        child: ranking.isConnected ? _buildConnected(context) : _buildConnectPrompt(context),
      ),
    );
  }

  Widget _buildConnectPrompt(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.leaderboard_outlined, size: 64, color: AppColors.primary),
          const SizedBox(height: 20),
          Text(
            'Conéctate para ver el ranking',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Elige un nombre de usuario público para aparecer en el ranking '
            'general y por asignatura junto a otros usuarios. No hace falta '
            'email ni contraseña.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Conectarse'),
              onPressed: () => _showConnectDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showConnectDialog(BuildContext context) async {
    final controller = TextEditingController();
    String? error;
    bool loading = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Elige tu nombre de usuario'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 20,
                decoration: InputDecoration(
                  hintText: 'Ej: MariaFarma',
                  errorText: error,
                ),
              ),
              Text(
                'Será visible para el resto de personas en el ranking.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      setDialogState(() {
                        loading = true;
                        error = null;
                      });
                      final result = await RankingService.instance.connect(controller.text);
                      if (result == null) {
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          setState(() {});
                          final progress = ProgressService.instance;
                          await RankingService.instance.sync(
                            totalAnswered: progress.totalAnswered,
                            totalCorrect: progress.totalCorrect,
                            subjectStats: progress.subjectStats,
                          );
                          if (mounted) setState(() {});
                        }
                      } else {
                        setDialogState(() {
                          loading = false;
                          error = result;
                        });
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Conectar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnected(BuildContext context) {
    final ranking = RankingService.instance;
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Conectado como ${ranking.username}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await ranking.disconnect();
                    if (mounted) setState(() {});
                  },
                  child: const Text('Desconectar'),
                ),
              ],
            ),
          ),
          const TabBar(
            labelColor: AppColors.primary,
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Por asignatura'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _OverallRankingTab(),
                _SubjectRankingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OverallRankingTab extends StatelessWidget {
  const _OverallRankingTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: RankingService.instance.overallRanking(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('No se pudo cargar el ranking.\n${snapshot.error}'));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Todavía no hay nadie en el ranking. ¡Sé el primero!'));
        }
        final myUsername = RankingService.instance.username;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (context, i) {
            final data = docs[i].data();
            final username = (data['username'] as String?) ?? '?';
            final correct = (data['totalCorrect'] as num?)?.toInt() ?? 0;
            final answered = (data['totalAnswered'] as num?)?.toInt() ?? 0;
            final isMe = username == myUsername;
            return _RankingRow(
              position: i + 1,
              username: username,
              primaryValue: '$correct aciertos',
              secondaryValue: '$answered contestadas',
              highlighted: isMe,
            );
          },
        );
      },
    );
  }
}

class _SubjectRankingTab extends StatefulWidget {
  const _SubjectRankingTab();

  @override
  State<_SubjectRankingTab> createState() => _SubjectRankingTabState();
}

class _SubjectRankingTabState extends State<_SubjectRankingTab> {
  String? _subject;

  @override
  Widget build(BuildContext context) {
    final subjects = QuestionRepository.instance.subjects;
    _subject ??= subjects.isNotEmpty ? subjects.first : null;

    if (_subject == null) {
      return const Center(child: Text('No hay asignaturas disponibles.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: DropdownButtonFormField<String>(
            value: _subject,
            decoration: const InputDecoration(
              labelText: 'Asignatura',
              border: OutlineInputBorder(),
            ),
            items: subjects
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _subject = v),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: RankingService.instance.subjectRanking(_subject!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('No se pudo cargar el ranking.\n${snapshot.error}'));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('Todavía no hay nadie en el ranking de esta asignatura.'));
              }
              final myUsername = RankingService.instance.username;
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final data = docs[i].data();
                  final username = (data['username'] as String?) ?? '?';
                  final correct = (data['correct'] as num?)?.toInt() ?? 0;
                  final answered = (data['answered'] as num?)?.toInt() ?? 0;
                  final isMe = username == myUsername;
                  return _RankingRow(
                    position: i + 1,
                    username: username,
                    primaryValue: '$correct aciertos',
                    secondaryValue: '$answered contestadas',
                    highlighted: isMe,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RankingRow extends StatelessWidget {
  final int position;
  final String username;
  final String primaryValue;
  final String secondaryValue;
  final bool highlighted;

  const _RankingRow({
    required this.position,
    required this.username,
    required this.primaryValue,
    required this.secondaryValue,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primary.withOpacity(0.10) : Colors.white,
        border: highlighted ? Border.all(color: AppColors.primary, width: 1.2) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$position',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              username,
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(primaryValue, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(secondaryValue, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

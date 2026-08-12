import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/progress_service.dart';
import '../theme.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final List<Question> questions;
  final String title;

  /// En modo examen no se revela si la respuesta es correcta hasta el
  /// final, se puede dejar una pregunta en blanco, y hay un cronómetro.
  final bool examMode;
  final Duration? timeLimit;

  const QuizScreen({
    super.key,
    required this.questions,
    required this.title,
    this.examMode = false,
    this.timeLimit,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  int? _selected;
  bool _answered = false;
  int _score = 0;
  int _blanks = 0;
  bool _finished = false;
  final List<int> _failedInSession = [];

  Timer? _timer;
  Duration? _remaining;

  Question get _current => widget.questions[_index];
  bool get _isLast => _index == widget.questions.length - 1;

  @override
  void initState() {
    super.initState();
    if (widget.examMode && widget.timeLimit != null) {
      _remaining = widget.timeLimit;
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!mounted || _finished) return;
    final remaining = _remaining! - const Duration(seconds: 1);
    if (remaining <= Duration.zero) {
      setState(() => _remaining = Duration.zero);
      _timer?.cancel();
      _finishExam(timeUp: true);
      return;
    }
    setState(() => _remaining = remaining);
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
  }

  Future<void> _selectOption(int optionIndex) async {
    if (widget.examMode) {
      if (_finished) return;
      setState(() => _selected = optionIndex);
      return;
    }
    if (_answered) return;
    final correct = optionIndex == _current.answerIndex;
    setState(() {
      _selected = optionIndex;
      _answered = true;
      if (correct) {
        _score++;
      } else {
        _failedInSession.add(_current.id);
      }
    });
    await ProgressService.instance.recordAnswer(
      questionId: _current.id,
      subject: _current.subject,
      correct: correct,
    );
  }

  Future<void> _next() async {
    if (widget.examMode) {
      final selected = _selected;
      if (selected != null) {
        final correct = selected == _current.answerIndex;
        if (correct) {
          _score++;
        } else {
          _failedInSession.add(_current.id);
        }
        await ProgressService.instance.recordAnswer(
          questionId: _current.id,
          subject: _current.subject,
          correct: correct,
        );
      } else {
        _blanks++;
        _failedInSession.add(_current.id);
      }
      if (_isLast) {
        await _finishExam();
        return;
      }
      setState(() {
        _index++;
        _selected = null;
      });
      return;
    }

    if (_isLast) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => ResultScreen(
          total: widget.questions.length,
          score: _score,
          failedIds: _failedInSession,
        ),
      ));
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _answered = false;
    });
  }

  Future<void> _finishExam({bool timeUp = false}) async {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    if (!mounted) return;
    if (timeUp && context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¡Se acabó el tiempo!'),
          content: const Text(
            'Se ha agotado el tiempo del simulacro. Vamos a ver tus resultados.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Ver resultados'),
            ),
          ],
        ),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => ResultScreen(
        total: widget.questions.length,
        score: _score,
        failedIds: _failedInSession,
        blanks: widget.examMode ? _blanks : null,
        examMode: widget.examMode,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('No hay preguntas disponibles.')),
      );
    }

    final q = _current;
    final progressValue = (_index) / widget.questions.length;
    final showFeedback = _answered && !widget.examMode;
    final canGoNext = widget.examMode ? true : _answered;

    return PopScope(
      canPop: !widget.examMode,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (_remaining != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _remaining! < const Duration(minutes: 15)
                        ? AppColors.incorrect.withOpacity(0.12)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 18,
                          color: _remaining! < const Duration(minutes: 15)
                              ? AppColors.incorrect
                              : const Color(0xFF0F766E)),
                      const SizedBox(width: 8),
                      Text(
                        'Tiempo restante: ${_formatDuration(_remaining!)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _remaining! < const Duration(minutes: 15)
                              ? AppColors.incorrect
                              : const Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Pregunta ${_index + 1} de ${widget.questions.length}',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text('${q.examLabel} · nº ${q.qnum}${q.official ? '' : ' (no oficial)'}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                q.question,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600, height: 1.3),
              ),
              const SizedBox(height: 20),
              ...List.generate(
                  q.options.length, (i) => _buildOption(context, q, i, showFeedback)),
              if (showFeedback) ...[
                const SizedBox(height: 12),
                _ExplanationCard(question: q),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canGoNext ? _next : null,
                  child: Text(widget.examMode
                      ? (_isLast ? 'Finalizar examen' : 'Siguiente pregunta')
                      : (_isLast ? 'Ver resultados' : 'Siguiente pregunta')),
                ),
              ),
              if (widget.examMode && _selected == null) ...[
                const SizedBox(height: 8),
                Text(
                  'Puedes dejarla en blanco y seguir, como en el examen real.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context, Question q, int i, bool showFeedback) {
    Color? bgColor;
    Color borderColor = Colors.grey.shade300;
    IconData? trailingIcon;
    Color? trailingColor;

    if (showFeedback) {
      if (i == q.answerIndex) {
        bgColor = AppColors.correct.withOpacity(0.12);
        borderColor = AppColors.correct;
        trailingIcon = Icons.check_circle;
        trailingColor = AppColors.correct;
      } else if (i == _selected) {
        bgColor = AppColors.incorrect.withOpacity(0.12);
        borderColor = AppColors.incorrect;
        trailingIcon = Icons.cancel;
        trailingColor = AppColors.incorrect;
      }
    } else if (widget.examMode && i == _selected) {
      bgColor = AppColors.primary.withOpacity(0.10);
      borderColor = AppColors.primary;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _selectOption(i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.white,
            border: Border.all(color: borderColor, width: 1.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey.shade200,
                child: Text(String.fromCharCode(65 + i),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(q.options[i], style: const TextStyle(fontSize: 15))),
              if (trailingIcon != null)
                Icon(trailingIcon, color: trailingColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  final Question question;
  const _ExplanationCard({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFF0F766E)),
              SizedBox(width: 6),
              Text('Explicación', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question.hasExplanation
                ? question.explanation
                : 'Todavía no tenemos una explicación redactada para esta pregunta, '
                    'pero la respuesta correcta está marcada arriba.',
            style: TextStyle(
              fontStyle: question.hasExplanation ? FontStyle.normal : FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

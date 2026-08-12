class Question {
  final int id;
  final int year;
  final int qnum;
  final String subject;
  final String question;
  final List<String> options;
  final int? answerIndex; // 0-based index into options, null if annulled
  final bool annulled;
  final String explanation;
  final bool hasExplanation;
  final String source;
  final bool official; // false = simulacro/practice test, not an official Ministry exam
  final String examLabel; // e.g. "FIR 2021" or "Preguntas no oficiales"

  Question({
    required this.id,
    required this.year,
    required this.qnum,
    required this.subject,
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.annulled,
    required this.explanation,
    required this.hasExplanation,
    required this.source,
    required this.official,
    required this.examLabel,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final year = json['year'] as int;
    final official = (json['official'] as bool?) ?? true;
    return Question(
      id: json['id'] as int,
      year: year,
      qnum: json['qnum'] as int,
      subject: (json['subject'] as String?) ?? 'Miscelánea',
      question: (json['question'] as String?) ?? '',
      options: (json['options'] as List<dynamic>).map((e) => e.toString()).toList(),
      answerIndex: json['answerIndex'] == null ? null : json['answerIndex'] as int,
      annulled: (json['annulled'] as bool?) ?? false,
      explanation: (json['explanation'] as String?) ?? '',
      hasExplanation: (json['hasExplanation'] as bool?) ?? false,
      source: (json['source'] as String?) ?? '',
      official: official,
      examLabel: (json['examLabel'] as String?) ?? (official ? 'FIR $year' : 'Preguntas no oficiales'),
    );
  }
}

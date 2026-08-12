import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import '../models/question.dart';
import '../services/purchase_service.dart';
import '../services/question_filter_service.dart';

class QuestionRepository {
  QuestionRepository._internal();
  static final QuestionRepository instance = QuestionRepository._internal();

  List<Question> _all = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;
  List<Question> get all => _all;

  /// Número de preguntas disponibles respetando el filtro de
  /// oficiales/no oficiales/ambas elegido por el usuario, y (si no hay
  /// compra Premium) restringido a las convocatorias gratuitas.
  int get filteredCount => _applyFreeYearsGate(_applyOrigin(_all)).length;

  Future<void> load() async {
    if (_loaded) return;
    final raw = await rootBundle.loadString('assets/data/fir_questions.json');
    final List<dynamic> data = jsonDecode(raw) as List<dynamic>;
    _all = data
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .where((q) => !q.annulled) // annulled questions are excluded from practice
        .toList();
    _loaded = true;
  }

  /// Aplica el filtro de oficiales/no oficiales/ambas seleccionado por el
  /// usuario (ver [QuestionFilterService]) sobre una lista de preguntas.
  List<Question> _applyOrigin(List<Question> list) {
    final filter = QuestionFilterService.instance;
    return list.where((q) => filter.matches(q.official)).toList();
  }

  /// Para usuarios sin la compra Premium, restringe el test aleatorio
  /// general (y el conteo que se muestra en la pantalla de inicio) a las
  /// convocatorias oficiales gratuitas (ver [kFreeYears]).
  List<Question> _applyFreeYearsGate(List<Question> list) {
    if (PurchaseService.instance.isPremium) return list;
    return list.where((q) => q.official && kFreeYears.contains(q.year)).toList();
  }

  Question? byId(int id) {
    for (final q in _all) {
      if (q.id == id) return q;
    }
    return null;
  }

  List<String> get subjects {
    final set = <String>{};
    for (final q in _all) {
      set.add(q.subject);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  /// Años de convocatorias oficiales (las preguntas no oficiales no tienen
  /// año real y no aparecen en "Practicar por año").
  List<int> get years {
    final set = <int>{};
    for (final q in _all) {
      if (q.official) set.add(q.year);
    }
    final list = set.toList();
    list.sort((a, b) => b.compareTo(a));
    return list;
  }

  int countBySubject(String subject, {bool applyOriginFilter = true}) {
    if (!PurchaseService.instance.isPremium && !kFreeSubjects.contains(subject)) {
      return 0;
    }
    final list = _all.where((q) => q.subject == subject).toList();
    return applyOriginFilter ? _applyOrigin(list).length : list.length;
  }

  int countByYear(int year) => _all.where((q) => q.year == year && q.official).length;

  List<Question> questionsBySubject(String subject, {int? limit}) {
    if (!PurchaseService.instance.isPremium && !kFreeSubjects.contains(subject)) {
      return [];
    }
    final list = _applyOrigin(_all.where((q) => q.subject == subject).toList());
    list.shuffle(Random());
    if (limit != null && limit < list.length) {
      return list.sublist(0, limit);
    }
    return list;
  }

  List<Question> questionsByYear(int year, {int? limit}) {
    final list = _all.where((q) => q.year == year && q.official).toList()
      ..sort((a, b) => a.qnum.compareTo(b.qnum));
    if (limit != null && limit < list.length) {
      final shuffled = List<Question>.from(list)..shuffle(Random());
      return shuffled.sublist(0, limit);
    }
    return list;
  }

  List<Question> randomGeneral({int limit = 20}) {
    final list = _applyFreeYearsGate(_applyOrigin(_all));
    list.shuffle(Random());
    if (limit < list.length) {
      return list.sublist(0, limit);
    }
    return list;
  }

  /// Simulacro de examen real: 210 preguntas (200 + 10 de reserva),
  /// elegidas al azar del banco de preguntas (respetando el filtro de
  /// oficiales/no oficiales elegido por el usuario).
  List<Question> examSimulation({int count = 210}) {
    final list = _applyOrigin(_all);
    list.shuffle(Random());
    if (count < list.length) {
      return list.sublist(0, count);
    }
    return list;
  }

  List<Question> questionsByIds(Iterable<int> ids) {
    final idSet = ids.toSet();
    final list = _all.where((q) => idSet.contains(q.id)).toList();
    list.shuffle(Random());
    return list;
  }
}

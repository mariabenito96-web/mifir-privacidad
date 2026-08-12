import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ranking_service.dart';

/// Keeps track of questions the user has failed (to enable the "repasar
/// falladas" mode) and simple overall statistics. Persisted locally on the
/// device via SharedPreferences so it survives app restarts.
class ProgressService {
  ProgressService._internal();
  static final ProgressService instance = ProgressService._internal();

  static const _kFailedIds = 'failed_ids';
  static const _kTotalAnswered = 'total_answered';
  static const _kTotalCorrect = 'total_correct';
  static const _kSubjectStats = 'subject_stats_v1';

  SharedPreferences? _prefs;
  Set<int> _failedIds = {};
  Map<String, List<int>> _subjectStats = {}; // subject -> [answered, correct]

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final storedFailed = _prefs!.getStringList(_kFailedIds) ?? [];
    _failedIds = storedFailed.map(int.parse).toSet();
    final rawStats = _prefs!.getString(_kSubjectStats);
    if (rawStats != null) {
      final decoded = jsonDecode(rawStats) as Map<String, dynamic>;
      _subjectStats = decoded.map(
        (key, value) => MapEntry(key, List<int>.from(value as List)),
      );
    }
  }

  Set<int> get failedIds => _failedIds;

  int get totalAnswered => _prefs?.getInt(_kTotalAnswered) ?? 0;
  int get totalCorrect => _prefs?.getInt(_kTotalCorrect) ?? 0;

  Map<String, List<int>> get subjectStats => _subjectStats;

  Future<void> recordAnswer({
    required int questionId,
    required String subject,
    required bool correct,
  }) async {
    if (correct) {
      _failedIds.remove(questionId);
    } else {
      _failedIds.add(questionId);
    }
    await _prefs?.setStringList(
      _kFailedIds,
      _failedIds.map((e) => e.toString()).toList(),
    );

    final totalAnswered = (this.totalAnswered) + 1;
    final totalCorrect = this.totalCorrect + (correct ? 1 : 0);
    await _prefs?.setInt(_kTotalAnswered, totalAnswered);
    await _prefs?.setInt(_kTotalCorrect, totalCorrect);

    final stats = _subjectStats[subject] ?? [0, 0];
    stats[0] += 1;
    if (correct) stats[1] += 1;
    _subjectStats[subject] = stats;
    await _prefs?.setString(_kSubjectStats, jsonEncode(_subjectStats));

    // Si el usuario está conectado al ranking online, sube el progreso
    // actualizado. No bloquea ni falla si no hay conexión/Firebase.
    unawaited(RankingService.instance.sync(
      totalAnswered: totalAnswered,
      totalCorrect: totalCorrect,
      subjectStats: _subjectStats,
    ));
  }

  Future<void> resetAll() async {
    _failedIds = {};
    _subjectStats = {};
    await _prefs?.remove(_kFailedIds);
    await _prefs?.remove(_kTotalAnswered);
    await _prefs?.remove(_kTotalCorrect);
    await _prefs?.remove(_kSubjectStats);

    unawaited(RankingService.instance.sync(
      totalAnswered: 0,
      totalCorrect: 0,
      subjectStats: _subjectStats,
    ));
  }
}

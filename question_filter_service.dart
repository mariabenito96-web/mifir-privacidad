import 'package:flutter/foundation.dart';

/// Whether the user wants to practice with official FIR exam questions,
/// unofficial practice-test ("simulacro") questions, or both. This choice
/// is shared across the random mode, subject mode and exam-simulation mode.
enum QuestionOrigin { official, unofficial, both }

class QuestionFilterService extends ChangeNotifier {
  QuestionFilterService._internal();
  static final QuestionFilterService instance = QuestionFilterService._internal();

  QuestionOrigin _origin = QuestionOrigin.both;

  QuestionOrigin get origin => _origin;

  void setOrigin(QuestionOrigin value) {
    if (_origin == value) return;
    _origin = value;
    notifyListeners();
  }

  bool matches(bool questionIsOfficial) {
    switch (_origin) {
      case QuestionOrigin.official:
        return questionIsOfficial;
      case QuestionOrigin.unofficial:
        return !questionIsOfficial;
      case QuestionOrigin.both:
        return true;
    }
  }

  String get label {
    switch (_origin) {
      case QuestionOrigin.official:
        return 'Solo oficiales';
      case QuestionOrigin.unofficial:
        return 'Solo no oficiales';
      case QuestionOrigin.both:
        return 'Oficiales y no oficiales';
    }
  }
}

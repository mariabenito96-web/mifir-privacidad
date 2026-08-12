import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ranking online opcional: si el usuario decide "conectarse", su progreso
/// (aciertos totales y por asignatura) se guarda en Firebase para poder
/// verse en un ranking general y por asignatura junto a otros usuarios.
///
/// Esta función es opcional y no bloquea el resto de la app: si Firebase no
/// está configurado (falta android/app/google-services.json) todo esto
/// falla en silencio y la app funciona igual, solo sin ranking.
class RankingService {
  RankingService._internal();
  static final RankingService instance = RankingService._internal();

  static const _kUsername = 'ranking_username';
  static const _kConnected = 'ranking_connected';

  SharedPreferences? _prefs;
  bool _firebaseReady = false;
  String? _username;

  bool get isConnected => (_prefs?.getBool(_kConnected) ?? false) && _username != null;
  String? get username => _username;
  bool get firebaseAvailable => _firebaseReady;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _username = _prefs?.getString(_kUsername);
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (_) {
      // Firebase no configurado todavía (falta google-services.json) o sin
      // conexión — el ranking simplemente no estará disponible.
      _firebaseReady = false;
    }
  }

  Future<User?> _ensureSignedIn() async {
    if (!_firebaseReady) return null;
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return auth.currentUser;
    final cred = await auth.signInAnonymously();
    return cred.user;
  }

  /// Intenta reservar un nombre de usuario público y conectar este
  /// dispositivo al ranking. Devuelve null si tuvo éxito, o un mensaje de
  /// error legible si no (nombre ya en uso, sin conexión, etc.).
  Future<String?> connect(String desiredUsername) async {
    final name = desiredUsername.trim();
    if (name.length < 3 || name.length > 20) {
      return 'El nombre debe tener entre 3 y 20 caracteres.';
    }
    if (!RegExp(r'^[A-Za-z0-9ÁÉÍÓÚÑáéíóúñ_\-\. ]+$').hasMatch(name)) {
      return 'Usa solo letras, números, espacios, guiones o guiones bajos.';
    }
    if (!_firebaseReady) {
      return 'El ranking online no está disponible todavía en esta app.';
    }
    try {
      final user = await _ensureSignedIn();
      if (user == null) return 'No se pudo conectar. Inténtalo de nuevo.';

      final lower = name.toLowerCase();
      final usernameRef = FirebaseFirestore.instance.collection('usernames').doc(lower);
      final playerRef = FirebaseFirestore.instance.collection('players').doc(user.uid);

      final ok = await FirebaseFirestore.instance.runTransaction<bool>((tx) async {
        final existing = await tx.get(usernameRef);
        if (existing.exists && existing.data()?['uid'] != user.uid) {
          return false; // nombre ya cogido por otro usuario
        }
        tx.set(usernameRef, {'uid': user.uid});
        tx.set(playerRef, {
          'username': name,
          'usernameLower': lower,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return true;
      });

      if (!ok) {
        return 'Ese nombre ya está en uso, prueba con otro.';
      }

      _username = name;
      await _prefs?.setString(_kUsername, name);
      await _prefs?.setBool(_kConnected, true);
      return null;
    } catch (e) {
      return 'No se pudo conectar (¿tienes internet?). Inténtalo más tarde.';
    }
  }

  Future<void> disconnect() async {
    await _prefs?.setBool(_kConnected, false);
  }

  /// Sube las estadísticas actuales (totales y por asignatura) al ranking.
  /// Se llama tras cada respuesta si el usuario está conectado; falla en
  /// silencio si no hay conexión a internet en ese momento.
  Future<void> sync({
    required int totalAnswered,
    required int totalCorrect,
    required Map<String, List<int>> subjectStats,
  }) async {
    if (!isConnected || !_firebaseReady) return;
    try {
      final user = await _ensureSignedIn();
      if (user == null) return;
      final batch = FirebaseFirestore.instance.batch();

      final playerRef = FirebaseFirestore.instance.collection('players').doc(user.uid);
      batch.set(playerRef, {
        'username': _username,
        'usernameLower': _username!.toLowerCase(),
        'totalAnswered': totalAnswered,
        'totalCorrect': totalCorrect,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      for (final entry in subjectStats.entries) {
        final subjectRef = FirebaseFirestore.instance
            .collection('subject_scores')
            .doc(entry.key)
            .collection('players')
            .doc(user.uid);
        batch.set(subjectRef, {
          'username': _username,
          'answered': entry.value[0],
          'correct': entry.value[1],
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (_) {
      // sin conexión u otro fallo transitorio: se reintentará en la
      // siguiente respuesta o sincronización manual.
    }
  }

  /// Ranking general, ordenado por número de aciertos totales.
  Stream<QuerySnapshot<Map<String, dynamic>>> overallRanking({int limit = 50}) {
    return FirebaseFirestore.instance
        .collection('players')
        .orderBy('totalCorrect', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Ranking de una asignatura concreta, ordenado por aciertos en esa
  /// asignatura.
  Stream<QuerySnapshot<Map<String, dynamic>>> subjectRanking(String subject, {int limit = 50}) {
    return FirebaseFirestore.instance
        .collection('subject_scores')
        .doc(subject)
        .collection('players')
        .orderBy('correct', descending: true)
        .limit(limit)
        .snapshots();
  }
}

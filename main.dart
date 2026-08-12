import 'package:flutter/material.dart';
import 'data/question_repository.dart';
import 'services/progress_service.dart';
import 'services/purchase_service.dart';
import 'services/ranking_service.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FirTestApp());
}

class FirTestApp extends StatelessWidget {
  const FirTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiFIR',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const AppBootstrap(),
    );
  }
}

/// Loads the question bank + saved progress before showing the home screen.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _init();
  }

  Future<void> _init() async {
    await Future.wait([
      QuestionRepository.instance.load(),
      ProgressService.instance.init(),
      RankingService.instance.init(),
      PurchaseService.instance.init(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando banco de preguntas...'),
                ],
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No se pudo cargar el banco de preguntas.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return const HomeScreen();
      },
    );
  }
}

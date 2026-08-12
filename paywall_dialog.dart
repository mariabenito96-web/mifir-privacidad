import 'package:flutter/material.dart';
import '../services/purchase_service.dart';
import '../theme.dart';

/// Diálogo para suscribirse a Premium. Se abre desde cualquier punto de la
/// app bloqueado para usuarios gratuitos (no oficiales, convocatorias
/// antiguas, examen simulacro, repasar falladas, ranking...).
Future<void> showPaywallDialog(BuildContext context) async {
  final purchases = PurchaseService.instance;

  await showDialog<void>(
    context: context,
    builder: (dialogCtx) => AnimatedBuilder(
      animation: purchases,
      builder: (ctx, _) {
        final product = purchases.product;
        return AlertDialog(
          title: const Text('Hazte Premium'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Con la suscripción Premium desbloqueas:'),
                const SizedBox(height: 12),
                const _Benefit('Todas las convocatorias FIR (2000-2025)'),
                const _Benefit('Todas las asignaturas en "Practicar por asignatura"'),
                const _Benefit('Test aleatorio con todos los años y asignaturas'),
                const _Benefit('Preguntas de práctica no oficiales'),
                const _Benefit('Examen simulacro cronometrado completo'),
                const _Benefit('Repasar falladas automáticamente'),
                const _Benefit('Ranking online (general y por asignatura)'),
                const SizedBox(height: 12),
                if (!purchases.storeAvailable)
                  const Text(
                    'La tienda de Google Play no está disponible ahora mismo. '
                    'Inténtalo de nuevo más tarde.',
                    style: TextStyle(color: Colors.red),
                  )
                else if (product == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  Text(
                    '${product.price} al año',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'La suscripción se renueva automáticamente cada año hasta '
                    'que la canceles. Puedes cancelarla cuando quieras desde '
                    'Google Play > Pagos y suscripciones > Suscripciones.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Ahora no'),
            ),
            TextButton(
              onPressed: purchases.loading ? null : () => purchases.restore(),
              child: const Text('Restaurar'),
            ),
            FilledButton(
              onPressed: (product == null || purchases.loading)
                  ? null
                  : () => purchases.buy(),
              child: purchases.loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Suscribirme'),
            ),
          ],
        );
      },
    ),
  );
}

class _Benefit extends StatelessWidget {
  final String text;
  const _Benefit(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

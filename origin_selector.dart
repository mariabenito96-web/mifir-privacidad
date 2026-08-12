import 'package:flutter/material.dart';
import '../services/purchase_service.dart';
import '../services/question_filter_service.dart';
import 'paywall_dialog.dart';

/// Selector para elegir si se practica con preguntas oficiales, no
/// oficiales (preguntas de práctica) o ambas. Comparte el mismo estado
/// global (ver [QuestionFilterService]) en todas las pantallas donde
/// aparece. Las opciones "No oficiales" y "Ambas" requieren la compra
/// Premium; los usuarios gratuitos solo pueden practicar con oficiales.
class OriginSelector extends StatefulWidget {
  const OriginSelector({super.key});

  @override
  State<OriginSelector> createState() => _OriginSelectorState();
}

class _OriginSelectorState extends State<OriginSelector> {
  @override
  void initState() {
    super.initState();
    QuestionFilterService.instance.addListener(_onChange);
    PurchaseService.instance.addListener(_onChange);
  }

  @override
  void dispose() {
    QuestionFilterService.instance.removeListener(_onChange);
    PurchaseService.instance.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final filter = QuestionFilterService.instance;
    final isPremium = PurchaseService.instance.isPremium;

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.filter_alt_outlined, size: 18, color: Color(0xFF0F766E)),
                SizedBox(width: 6),
                Text('Preguntas a practicar', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 10),
            SegmentedButton<QuestionOrigin>(
              segments: [
                const ButtonSegment(
                  value: QuestionOrigin.official,
                  label: Text('Oficiales'),
                ),
                ButtonSegment(
                  value: QuestionOrigin.unofficial,
                  label: _SegmentLabel('No oficiales', locked: !isPremium),
                ),
                ButtonSegment(
                  value: QuestionOrigin.both,
                  label: _SegmentLabel('Ambas', locked: !isPremium),
                ),
              ],
              selected: {filter.origin},
              onSelectionChanged: (selection) {
                final value = selection.first;
                if (value != QuestionOrigin.official && !isPremium) {
                  showPaywallDialog(context);
                  return;
                }
                filter.setOrigin(value);
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isPremium
                  ? 'Afecta al test aleatorio, practicar por asignatura y el examen simulacro. '
                      'Las no oficiales son preguntas de práctica, no exámenes reales del Ministerio.'
                  : 'Con la versión gratuita solo puedes practicar con preguntas oficiales. '
                      'Hazte Premium para desbloquear también las no oficiales.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  final String text;
  final bool locked;
  const _SegmentLabel(this.text, {required this.locked});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (locked) ...[
          const SizedBox(width: 4),
          const Icon(Icons.lock, size: 12),
        ],
      ],
    );
  }
}

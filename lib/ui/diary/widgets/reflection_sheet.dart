import 'package:flutter/material.dart';

import '../../core/themes/colors.dart';
import '../../core/themes/dimens.dart';

/// La riflessione aperta a schermo intero, sopra al diario oscurato.
///
/// La card del diario serve a rileggere; qui si scrive, con un'area di testo
/// alta e il bottone "Salva" a tutta larghezza.
class ReflectionSheet extends StatefulWidget {
  const ReflectionSheet({
    required this.initialText,
    required this.onSave,
    required this.onClose,
    super.key,
  });

  final String initialText;

  final ValueChanged<String> onSave;

  final VoidCallback onClose;

  @override
  State<ReflectionSheet> createState() => _ReflectionSheetState();
}

class _ReflectionSheetState extends State<ReflectionSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final testi = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VivoDimens.lg),
        child: Material(
          color: VivoColors.card,
          borderRadius: BorderRadius.circular(VivoDimens.radiusCard),
          child: Padding(
            padding: const EdgeInsets.all(VivoDimens.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'La tua riflessione',
                        style: testi.titleMedium,
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      tooltip: 'Chiudi',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: VivoDimens.sm),
                // L'area di testo si stringe quando lo spazio non basta.
                // Il tastierino delle emoji è più alto della tastiera
                Flexible(
                  child: Container(
                    height: 260,
                    padding: const EdgeInsets.all(VivoDimens.sm),
                    decoration: BoxDecoration(
                      color: VivoColors.field,
                      borderRadius: BorderRadius.circular(
                        VivoDimens.radiusField,
                      ),
                      border: Border.all(color: VivoColors.line),
                    ),
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: testi.bodyMedium,
                      // Il bordo lo disegna il riquadro qui sopra: al campo si
                      // tolgono anche quelli di riposo e di fuoco, altrimenti in
                      // scrittura ne comparirebbero due, uno dentro l'altro.
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'Scrivi qui i tuoi pensieri...',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: VivoDimens.md),
                SizedBox(
                  width: double.infinity,
                  height: VivoDimens.buttonHeight,
                  child: FilledButton(
                    onPressed: () => widget.onSave(_controller.text),
                    child: const Text('Salva'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

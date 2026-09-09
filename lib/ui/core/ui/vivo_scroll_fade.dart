import 'package:flutter/material.dart';

import '../themes/colors.dart';

/// Una sfumatura in fondo a un'area che scorre, per dire "continua sotto".
class VivoScrollFade extends StatefulWidget {
  const VivoScrollFade({
    required this.child,
    this.height = defaultHeight,
    this.color,
    super.key,
  });

  static const double defaultHeight = 48;

  final Widget child;

  final double height;

  /// Il colore in cui il contenuto sfuma; per impostazione predefinita la
  /// crema di fondo delle schermate.
  final Color? color;

  @override
  State<VivoScrollFade> createState() => _VivoScrollFadeState();
}

class _VivoScrollFadeState extends State<VivoScrollFade> {
  /// Quanto contenuto deve restare sotto perché la sfumatura si accenda.
  ///
  /// Qualche pixel di tolleranza evita che compaia per gli arrotondamenti di
  /// un contenuto che in pratica ci sta tutto.
  static const double _tolleranza = 4;

  /// La durata della dissolvenza.
  ///
  /// Senza, la sfumatura lampeggerebbe a ogni piccolo scorrimento vicino al
  /// fondo; più lunga, resterebbe indietro rispetto al dito.
  static const Duration _dissolvenza = Duration(milliseconds: 160);

  bool _altroSotto = false;

  /// Aggiorna la sfumatura secondo quanto contenuto resta da vedere.
  void _aggiorna(ScrollMetrics misure) {
    final sotto = misure.extentAfter > _tolleranza;
    if (sotto == _altroSotto) return;
    setState(() => _altroSotto = sotto);
  }

  @override
  Widget build(BuildContext context) {
    final colore = widget.color ?? VivoColors.background;

    return Stack(
      children: <Widget>[
        // Le misure arrivano in due modi: `ScrollMetricsNotification` quando
        // l'area viene disposta o cambia dimensione - è da lì che si sa com'è
        // messa la schermata appena aperta - e `ScrollNotification` mentre il
        // dito scorre. Le due notifiche non sono l'una sottoclasse
        // dell'altra, quindi servono tutti e due gli ascoltatori.
        NotificationListener<ScrollMetricsNotification>(
          onNotification: (notifica) {
            _aggiorna(notifica.metrics);
            return false;
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (notifica) {
              _aggiorna(notifica.metrics);
              return false;
            },
            child: widget.child,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          // La sfumatura è dipinta sopra al contenuto: senza IgnorePointer si
          // prenderebbe i tocchi delle card che copre.
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _altroSotto ? 1 : 0,
              duration: _dissolvenza,
              child: SizedBox(
                height: widget.height,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    // La crema sale in fretta: con una sfumatura lineare su
                    // trentadue pixel il passaggio era così graduale da non
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        colore.withValues(alpha: 0),
                        colore.withValues(alpha: 0.55),
                        colore,
                      ],
                      stops: const <double>[0, 0.45, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

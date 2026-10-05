import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/rutas.dart';
import '../../servicios/notificaciones_servicio.dart';

/// Abre el detalle de la alerta cuando se toca un aviso (HU-10). Envuelve la
/// barra inferior: solo existe con sesión, así que un aviso tocado al
/// arrancar espera a que el productor llegue a Inicio y luego se abre.
class AperturaAlertas extends StatefulWidget {
  const AperturaAlertas({super.key, required this.child});

  final Widget child;

  @override
  State<AperturaAlertas> createState() => _AperturaAlertasState();
}

class _AperturaAlertasState extends State<AperturaAlertas> {
  late final NotificacionesServicio _notificaciones;

  @override
  void initState() {
    super.initState();
    _notificaciones = context.read<NotificacionesServicio>();
    // Después del primer cuadro, para que el enrutador ya esté listo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final enrutador = GoRouter.of(context);
      _notificaciones.alAbrirAlerta(
        (alertaId) => enrutador.push(Rutas.detalleAlerta(alertaId)),
      );
    });
  }

  @override
  void dispose() {
    _notificaciones.alAbrirAlerta(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

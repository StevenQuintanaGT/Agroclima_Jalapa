import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../modelos/alerta.dart';
import '../../servicios/alertas_servicio.dart';

/// Número del distintivo rojo de "Alertas" en la barra inferior: avisos
/// activos sin abrir, en vivo (HU-11).
class ContadorAvisos extends StatefulWidget {
  const ContadorAvisos({super.key, required this.builder});

  final Widget Function(BuildContext context, int sinLeer) builder;

  @override
  State<ContadorAvisos> createState() => _ContadorAvisosState();
}

class _ContadorAvisosState extends State<ContadorAvisos> {
  late final StreamSubscription<List<Alerta>> _suscripcion;
  int _sinLeer = 0;

  @override
  void initState() {
    super.initState();
    _suscripcion = context.read<AlertasServicio>().misAlertas().listen((
      alertas,
    ) {
      final sinLeer = AlertasServicio.sinLeer(alertas, DateTime.now());
      if (mounted && sinLeer != _sinLeer) setState(() => _sinLeer = sinLeer);
    }, onError: (Object e) => debugPrint('Contador de avisos: $e'));
  }

  @override
  void dispose() {
    _suscripcion.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _sinLeer);
}

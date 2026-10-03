import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../config/tema/colores.dart';
import '../../config/textos.dart';

/// Construye el mapa del paso 3. Se puede reemplazar en las pruebas, donde
/// no hay red para las teselas.
typedef ConstructorMapa = Widget Function({
  required double latitud,
  required double longitud,
  required bool puntoPuesto,
  required void Function(double latitud, double longitud) alMoverPin,
});

/// CO-03 · Mapa satelital con el pin arrastrable (HU-03). Tocar el mapa
/// también mueve el pin. Si el punto cambia desde afuera (búsqueda o "Usar
/// mi ubicación"), la cámara lo sigue.
///
/// Usa `flutter_map` con imágenes satelitales y nombres de lugares de Esri:
/// gratis, sin clave ni facturación (DECISIONES D-37). Se cita la fuente.
class MapaParcela extends StatefulWidget {
  const MapaParcela({
    super.key,
    required this.latitud,
    required this.longitud,
    required this.puntoPuesto,
    required this.alMoverPin,
  });

  final double latitud;
  final double longitud;
  final bool puntoPuesto;
  final void Function(double latitud, double longitud) alMoverPin;

  static const String _satelite =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
  static const String _nombres =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}';
  static const String _paquete = 'gt.umg.agroclima_jalapa';

  /// Para usar como [ConstructorMapa].
  static Widget construir({
    required double latitud,
    required double longitud,
    required bool puntoPuesto,
    required void Function(double latitud, double longitud) alMoverPin,
  }) => MapaParcela(
    latitud: latitud,
    longitud: longitud,
    puntoPuesto: puntoPuesto,
    alMoverPin: alMoverPin,
  );

  @override
  State<MapaParcela> createState() => _MapaParcelaState();
}

class _MapaParcelaState extends State<MapaParcela> {
  final _controlador = MapController();
  static const double _tamanoPin = 52;

  /// Posición mientras el productor arrastra el pin.
  LatLng? _arrastre;

  LatLng get _punto => LatLng(widget.latitud, widget.longitud);

  @override
  void didUpdateWidget(MapaParcela anterior) {
    super.didUpdateWidget(anterior);
    final cambio =
        anterior.latitud != widget.latitud ||
        anterior.longitud != widget.longitud;
    if (cambio && _arrastre == null) {
      // Antes de poner el punto se ve el municipio; después, de cerca.
      final zoom = widget.puntoPuesto
          ? math.max(_controlador.camera.zoom, 15.0)
          : 12.0;
      _controlador.move(_punto, zoom);
    }
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  // Al tocar el pin se congela el mapa: si no, el mapa se queda con el gesto
  // y se mueve todo junto en vez del pin.
  void _tocarPin(PointerDownEvent _) => setState(() => _arrastre = _punto);

  void _arrastrar(PointerMoveEvent evento) {
    if (_arrastre == null) return;
    final camara = _controlador.camera;
    final pantalla = camara.latLngToScreenOffset(_arrastre!) + evento.delta;
    setState(() => _arrastre = camara.screenOffsetToLatLng(pantalla));
  }

  void _soltar(PointerEvent _) {
    final destino = _arrastre;
    setState(() => _arrastre = null);
    if (destino != null) {
      widget.alMoverPin(destino.latitude, destino.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _controlador,
      options: MapOptions(
        initialCenter: _punto,
        initialZoom: widget.puntoPuesto ? 16 : 12,
        minZoom: 8,
        maxZoom: 18,
        onTap: (_, punto) => widget.alMoverPin(punto.latitude, punto.longitude),
        interactionOptions: InteractionOptions(
          flags: _arrastre == null
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: MapaParcela._satelite,
          userAgentPackageName: MapaParcela._paquete,
        ),
        TileLayer(
          urlTemplate: MapaParcela._nombres,
          userAgentPackageName: MapaParcela._paquete,
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _arrastre ?? _punto,
              width: _tamanoPin,
              height: _tamanoPin,
              // La punta del pin queda sobre el punto.
              alignment: Alignment.topCenter,
              child: Semantics(
                label: Textos.arrastrePin,
                child: Listener(
                  onPointerDown: _tocarPin,
                  onPointerMove: _arrastrar,
                  onPointerUp: _soltar,
                  onPointerCancel: _soltar,
                  child: const Icon(
                    Symbols.location_on,
                    fill: 1,
                    size: _tamanoPin,
                    color: Colores.peligroBorde,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
                  ),
                ),
              ),
            ),
          ],
        ),
        // Cita de la fuente (la exige Esri), arriba del botón "Usar mi
        // ubicación" para que no quede tapada.
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 84),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  Textos.fuenteMapa,
                  style: TextStyle(fontSize: 11, color: Colores.texto),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

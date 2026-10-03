import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Construye el mapa del paso 3. Se puede reemplazar en las pruebas, donde
/// Google Maps no está disponible.
typedef ConstructorMapa = Widget Function({
  required double latitud,
  required double longitud,
  required bool puntoPuesto,
  required void Function(double latitud, double longitud) alMoverPin,
});

/// CO-03 · Mapa satelital con el pin arrastrable (HU-03). Tocar el mapa
/// también mueve el pin. Si el punto cambia desde afuera (búsqueda o "Usar
/// mi ubicación"), la cámara lo sigue.
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
  GoogleMapController? _controlador;

  // Antes de poner el punto se ve el municipio; después, de cerca.
  double get _zoom => widget.puntoPuesto ? 16 : 12;

  LatLng get _punto => LatLng(widget.latitud, widget.longitud);

  @override
  void didUpdateWidget(MapaParcela anterior) {
    super.didUpdateWidget(anterior);
    final cambio =
        anterior.latitud != widget.latitud ||
        anterior.longitud != widget.longitud;
    if (cambio) {
      _controlador?.animateCamera(CameraUpdate.newLatLngZoom(_punto, _zoom));
    }
  }

  @override
  void dispose() {
    _controlador?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _punto, zoom: _zoom),
      mapType: MapType.hybrid,
      onMapCreated: (controlador) => _controlador = controlador,
      onTap: (punto) => widget.alMoverPin(punto.latitude, punto.longitude),
      markers: {
        Marker(
          markerId: const MarkerId('parcela'),
          position: _punto,
          draggable: true,
          onDragEnd: (punto) =>
              widget.alMoverPin(punto.latitude, punto.longitude),
        ),
      },
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
    );
  }
}

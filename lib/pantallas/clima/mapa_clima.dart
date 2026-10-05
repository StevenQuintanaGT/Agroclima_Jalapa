import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../config/tema/colores.dart';
import '../../config/tema/colores_semaforo.dart';
import '../../config/tema/tipografia.dart';
import '../../modelos/enums.dart';
import '../../modelos/parcela.dart';

/// Construye el mapa de la pantalla 20. En las pruebas se reemplaza: ahí no
/// hay red para las teselas.
typedef ConstructorMapaClima = Widget Function({
  required List<Parcela> parcelas,
  required Map<String, NivelSeveridad> niveles,
  required String? urlCapa,
  required bool tenirCapa,
  required double opacidad,
  required VoidCallback alFallarCapa,
  required MapController controlador,
  required void Function(Parcela parcela) alTocarParcela,
});

/// Mapa base gris de Esri (sin clave, D-37), la capa del clima de OpenWeather
/// encima con la transparencia elegida, los nombres de lugares arriba de la
/// capa y los pines de sus parcelas.
class MapaClima extends StatelessWidget {
  const MapaClima({
    super.key,
    required this.parcelas,
    required this.niveles,
    required this.urlCapa,
    required this.tenirCapa,
    required this.opacidad,
    required this.alFallarCapa,
    required this.controlador,
    required this.alTocarParcela,
  });

  final List<Parcela> parcelas;
  final Map<String, NivelSeveridad> niveles;
  final String? urlCapa;

  /// Las nubes de OpenWeather son blancas: sobre el mapa claro no se ven.
  /// Se tiñen de gris conservando su transparencia (más nubes, más gris).
  final bool tenirCapa;
  final double opacidad;
  final VoidCallback alFallarCapa;
  final MapController controlador;
  final void Function(Parcela parcela) alTocarParcela;

  /// Centro y acercamiento con que se ve todo el departamento.
  static const LatLng centroJalapa = LatLng(14.62, -89.98);
  static const double zoomDepartamento = 9.6;

  static const String _esri =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas';
  static const String _paquete = 'gt.umg.agroclima_jalapa';

  static Widget construir({
    required List<Parcela> parcelas,
    required Map<String, NivelSeveridad> niveles,
    required String? urlCapa,
    required bool tenirCapa,
    required double opacidad,
    required VoidCallback alFallarCapa,
    required MapController controlador,
    required void Function(Parcela parcela) alTocarParcela,
  }) => MapaClima(
    parcelas: parcelas,
    niveles: niveles,
    urlCapa: urlCapa,
    tenirCapa: tenirCapa,
    opacidad: opacidad,
    alFallarCapa: alFallarCapa,
    controlador: controlador,
    alTocarParcela: alTocarParcela,
  );

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final tono = oscuro ? 'Dark' : 'Light';
    return FlutterMap(
      mapController: controlador,
      options: const MapOptions(
        initialCenter: centroJalapa,
        initialZoom: zoomDepartamento,
        minZoom: 8,
        maxZoom: 14,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              '$_esri/World_${tono}_Gray_Base/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: _paquete,
        ),
        if (urlCapa != null)
          Opacity(
            opacity: opacidad,
            child: ColorFiltered(
              colorFilter: tenirCapa
                  ? const ColorFilter.mode(Color(0xFF37474F), BlendMode.srcIn)
                  : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: TileLayer(
                key: ValueKey(urlCapa),
                urlTemplate: urlCapa,
                userAgentPackageName: _paquete,
                // Más cerca se agranda la última tesela en vez de pedir más:
                // cuida la cuota gratuita y la capa no tiene más detalle.
                maxNativeZoom: 10,
                errorTileCallback: (_, _, _) => alFallarCapa(),
              ),
            ),
          ),
        TileLayer(
          urlTemplate:
              '$_esri/World_${tono}_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: _paquete,
        ),
        MarkerLayer(
          markers: [
            for (final parcela in parcelas)
              Marker(
                point: LatLng(parcela.latitud, parcela.longitud),
                width: 170,
                height: 86,
                // La punta del pin (a media altura del marcador) cae en el punto.
                alignment: Alignment.center,
                child: _Pin(
                  parcela: parcela,
                  nivel: niveles[parcela.parcelaId],
                  alTocar: () => alTocarParcela(parcela),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Pin con el nombre de la parcela: verde sin avisos; del color del semáforo
/// si tiene un aviso de PRECAUCIÓN o PELIGRO.
class _Pin extends StatelessWidget {
  const _Pin({
    required this.parcela,
    required this.nivel,
    required this.alTocar,
  });

  final Parcela parcela;
  final NivelSeveridad? nivel;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final color = switch (nivel) {
      null || NivelSeveridad.informativa => Colores.primario,
      NivelSeveridad.preventiva ||
      NivelSeveridad.critica => ColoresSemaforo.of(context).de(nivel!).borde,
    };
    return GestureDetector(
      onTap: alTocar,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Symbols.location_on,
            fill: 1,
            size: 44,
            color: color,
            shadows: const [Shadow(blurRadius: 4, color: Colors.black38)],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Text(
              parcela.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Tipografia.cuerpo.copyWith(
                fontWeight: FontWeight.w700,
                color: Colores.texto,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../config/rutas.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/capa_clima.dart';
import 'mapa_clima.dart';
import 'mapa_clima_vm.dart';

/// Mapa del clima (pantalla 20, HU-09): capas como botones con ícono y
/// palabra, leyenda "Qué significan los colores" y "Mi parcela".
class MapaClimaPantalla extends StatefulWidget {
  const MapaClimaPantalla({
    super.key,
    this.constructorMapa = MapaClima.construir,
  });

  final ConstructorMapaClima constructorMapa;

  @override
  State<MapaClimaPantalla> createState() => _MapaClimaPantallaState();
}

class _MapaClimaPantallaState extends State<MapaClimaPantalla> {
  final _controlador = MapController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _irAMiParcela(MapaClimaVm vm) {
    final parcela = vm.miParcela;
    _controlador.move(
      parcela == null
          ? MapaClima.centroJalapa
          : LatLng(parcela.latitud, parcela.longitud),
      parcela == null ? MapaClima.zoomDepartamento : 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MapaClimaVm>();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              Textos.mapaClima,
              style: Tipografia.titulo.copyWith(color: Colors.white),
            ),
            Text(
              Textos.departamentoJalapa,
              style: Tipografia.cuerpo.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: widget.constructorMapa(
              parcelas: vm.parcelas,
              niveles: vm.nivelPorParcela,
              urlCapa: vm.urlCapa,
              tenirCapa: vm.capa == CapaClima.nubes,
              opacidad: vm.opacidad,
              alFallarCapa: vm.capaFallo,
              controlador: _controlador,
              alTocarParcela: (p) =>
                  context.push(Rutas.detalleParcela(p.parcelaId)),
            ),
          ),
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Capas(capa: vm.capa, alElegir: vm.elegirCapa),
                if (!vm.hayRed)
                  const _Aviso(
                    icono: Symbols.wifi_off,
                    texto: Textos.sinInternetMapa,
                  )
                else if (vm.errorCapa)
                  const _Aviso(
                    icono: Symbols.cloud_off,
                    texto: Textos.errorCapa,
                  ),
              ],
            ),
          ),
          Positioned(
            left: Medidas.margenPantalla,
            right: Medidas.margenPantalla,
            bottom: Medidas.margenPantalla,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _BotonMiParcela(alTocar: () => _irAMiParcela(vm)),
                const SizedBox(height: Medidas.separacionTarjetas),
                vm.capa == null
                    ? const _Tarjeta(child: _Indicacion())
                    : _Tarjeta(
                        child: _Leyenda(
                          capa: vm.capa!,
                          opacidad: vm.opacidad,
                          alCambiar: vm.cambiarOpacidad,
                        ),
                      ),
                const SizedBox(height: 4),
                Text(
                  Textos.fuenteMapaClima,
                  style: const TextStyle(fontSize: 11, color: Colores.texto),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Botones de capa con ícono y palabra (no un menú). Uno a la vez.
class _Capas extends StatelessWidget {
  const _Capas({required this.capa, required this.alElegir});

  final CapaClima? capa;
  final void Function(CapaClima capa) alElegir;

  static IconData icono(CapaClima capa) => switch (capa) {
    CapaClima.lluvia => Symbols.rainy,
    CapaClima.nubes => Symbols.cloud,
    CapaClima.calor => Symbols.thermostat,
    CapaClima.viento => Symbols.air,
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Medidas.margenPantalla),
        itemCount: CapaClima.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final opcion = CapaClima.values[i];
          final elegida = opcion == capa;
          final color = elegida ? Colors.white : Colores.texto;
          return Semantics(
            button: true,
            selected: elegida,
            label: Textos.nombreCapa(opcion),
            excludeSemantics: true,
            child: Material(
              color: elegida ? Colores.acentoCielo : Colors.white,
              elevation: 2,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => alElegir(opcion),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(icono(opcion), size: 24, color: color),
                      const SizedBox(width: 8),
                      Text(
                        Textos.nombreCapa(opcion),
                        style: Tipografia.cuerpoGrande.copyWith(
                          fontWeight: FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Medidas.margenPantalla,
      10,
      Medidas.margenPantalla,
      0,
    ),
    child: Material(
      color: Colores.bannerSinConexion,
      borderRadius: BorderRadius.circular(Medidas.radioCampo),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icono, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                texto,
                style: Tipografia.cuerpo.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _BotonMiParcela extends StatelessWidget {
  const _BotonMiParcela({required this.alTocar});

  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 3,
    shape: const CircleBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: alTocar,
      child: SizedBox(
        width: 88,
        height: 88,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Symbols.my_location, size: 30, color: Colores.primario),
            Text(
              Textos.miParcela,
              style: Tipografia.etiquetaChica.copyWith(
                color: Colores.primarioOscuro,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    elevation: 3,
    borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
    child: Padding(padding: const EdgeInsets.all(18), child: child),
  );
}

class _Indicacion extends StatelessWidget {
  const _Indicacion();

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Symbols.layers, size: 26, color: esquema.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            Textos.elijaCapa,
            style: Tipografia.cuerpoGrande.copyWith(color: esquema.onSurface),
          ),
        ),
      ],
    );
  }
}

/// "Qué significan los colores": la escala de la capa y "Ver más claro".
class _Leyenda extends StatelessWidget {
  const _Leyenda({
    required this.capa,
    required this.opacidad,
    required this.alCambiar,
  });

  final CapaClima capa;
  final double opacidad;
  final ValueChanged<double> alCambiar;

  /// Colores aproximados de cada capa de OpenWeather, de poco a mucho.
  static List<Color> colores(CapaClima capa) => switch (capa) {
    CapaClima.lluvia => const [
      Color(0xFFCFE8F7),
      Color(0xFF7FBCE6),
      Color(0xFF0277BD),
      Color(0xFF01426A),
    ],
    CapaClima.nubes => const [
      Color(0xFFF2F2F2),
      Color(0xFFD4D4D4),
      Color(0xFFA6A6A6),
      Color(0xFF6B6B6B),
    ],
    CapaClima.calor => const [
      Color(0xFF3F51B5),
      Color(0xFF4FC3F7),
      Color(0xFFFFEB3B),
      Color(0xFFE53935),
    ],
    CapaClima.viento => const [
      Color(0xFFE8EAF6),
      Color(0xFF9FA8DA),
      Color(0xFF5C6BC0),
      Color(0xFF283593),
    ],
  };

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final (poco, mucho) = Textos.extremosCapa(capa);
    final escala = colores(capa);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Textos.queSignificanColores,
          style: Tipografia.subtitulo.copyWith(
            fontWeight: FontWeight.w700,
            color: esquema.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              for (final color in escala)
                Expanded(child: Container(height: 16, color: color)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                poco,
                style: Tipografia.cuerpo.copyWith(
                  color: esquema.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                mucho,
                textAlign: TextAlign.right,
                style: Tipografia.cuerpo.copyWith(
                  color: esquema.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              Textos.verMasClaro,
              style: Tipografia.cuerpoGrande.copyWith(
                fontWeight: FontWeight.w500,
                color: esquema.onSurface,
              ),
            ),
            Expanded(
              child: Slider(
                value: 1.2 - opacidad,
                min: 0.2,
                max: 1.0,
                label: Textos.verMasClaro,
                onChanged: (valor) => alCambiar(1.2 - valor),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

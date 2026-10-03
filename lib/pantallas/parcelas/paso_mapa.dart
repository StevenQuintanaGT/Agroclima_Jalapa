import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/chip_seleccion.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/colores_semaforo.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/enums.dart';
import 'mapa_parcela.dart';
import 'registro_parcela_vm.dart';

/// Paso 3 (pantalla 12): poner el punto de la parcela en el mapa (HU-03) o
/// con la ubicación del teléfono (HU-04), y el tamaño aproximado.
class PasoMapa extends StatefulWidget {
  const PasoMapa({super.key, required this.constructorMapa});

  final ConstructorMapa constructorMapa;

  @override
  State<PasoMapa> createState() => _PasoMapaState();
}

class _PasoMapaState extends State<PasoMapa> {
  final _busqueda = TextEditingController();
  late final TextEditingController _altura;
  late final TextEditingController _area;

  @override
  void initState() {
    super.initState();
    final vm = context.read<RegistroParcelaVm>();
    _altura = TextEditingController(text: vm.altitudTexto);
    _area = TextEditingController(text: vm.areaTexto);
    _vm = vm..addListener(_alCambiarVm);
  }

  late final RegistroParcelaVm _vm;

  void _alCambiarVm() {
    _sincronizar(_altura, _vm.altitudTexto);
    _sincronizar(_area, _vm.areaTexto);
  }

  /// Si el VM cambia el valor (p. ej. la altura del GPS), el campo lo muestra.
  static void _sincronizar(TextEditingController campo, String valor) {
    if (campo.text != valor) campo.text = valor;
  }

  @override
  void dispose() {
    _vm.removeListener(_alCambiarVm);
    _busqueda.dispose();
    _altura.dispose();
    _area.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RegistroParcelaVm>();
    final esquema = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: widget.constructorMapa(
                  latitud: vm.latitud,
                  longitud: vm.longitud,
                  puntoPuesto: vm.puntoPuesto,
                  alMoverPin: vm.moverPin,
                ),
              ),
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: _BarraBusqueda(
                  controlador: _busqueda,
                  buscando: vm.buscando,
                  alBuscar: vm.buscarLugar,
                ),
              ),
              if (!vm.puntoPuesto)
                const Align(
                  alignment: Alignment(0, 0.35),
                  child: _Globo(texto: Textos.arrastrePin),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: _BotonUbicacion(
                  ubicando: vm.ubicando,
                  alTocar: vm.usarMiUbicacion,
                ),
              ),
            ],
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.45,
          ),
          child: Material(
            color: esquema.surface,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: _DatosDelPunto(vm: vm, altura: _altura, area: _area),
            ),
          ),
        ),
      ],
    );
  }
}

class _BarraBusqueda extends StatelessWidget {
  const _BarraBusqueda({
    required this.controlador,
    required this.buscando,
    required this.alBuscar,
  });

  final TextEditingController controlador;
  final bool buscando;
  final ValueChanged<String> alBuscar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Material(
      elevation: 3,
      shadowColor: Colors.black38,
      color: esquema.surface,
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(Symbols.search, size: 26, color: Colores.textoTenue),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controlador,
                textInputAction: TextInputAction.search,
                onSubmitted: alBuscar,
                style: Tipografia.cuerpoGrande.copyWith(
                  color: esquema.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: Textos.buscarLugar,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  constraints: const BoxConstraints(),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (buscando)
              const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              )
            else
              const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class _Globo extends StatelessWidget {
  const _Globo({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colores.texto,
          borderRadius: BorderRadius.circular(Medidas.radioChico),
        ),
        child: Text(
          texto,
          style: Tipografia.cuerpoGrande.copyWith(
            color: Colors.white,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _BotonUbicacion extends StatelessWidget {
  const _BotonUbicacion({required this.ubicando, required this.alTocar});

  final bool ubicando;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final colorTexto = Theme.of(context).brightness == Brightness.light
        ? Colores.primarioOscuro
        : Colores.primarioTemaOscuro;
    return Material(
      elevation: 3,
      shadowColor: Colors.black38,
      color: esquema.surface,
      borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
      child: InkWell(
        onTap: ubicando ? null : alTocar,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: Medidas.alturaBotonSecundario,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (ubicando)
                SizedBox.square(
                  dimension: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colorTexto,
                  ),
                )
              else
                Icon(Symbols.my_location, size: 28, color: colorTexto),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  ubicando ? Textos.buscandoUbicacion : Textos.usarMiUbicacion,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: Tipografia.boton.copyWith(color: colorTexto),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DatosDelPunto extends StatelessWidget {
  const _DatosDelPunto({
    required this.vm,
    required this.altura,
    required this.area,
  });

  final RegistroParcelaVm vm;
  final TextEditingController altura;
  final TextEditingController area;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final semaforo = ColoresSemaforo.of(context);
    final etiqueta = Tipografia.cuerpoGrande.copyWith(
      color: esquema.onSurfaceVariant,
    );
    final aviso = vm.avisoPunto ?? vm.mensajeUbicacion;
    final esError = vm.fueraDeJalapa || vm.faltaPunto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (aviso != null || vm.faltaPunto)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _Aviso(
              texto: aviso ?? Textos.errorMuevaPin,
              tono: esError
                  ? semaforo.de(NivelSeveridad.critica)
                  : semaforo.de(NivelSeveridad.preventiva),
              icono: esError ? Symbols.error : Symbols.info,
            ),
          ),
        Row(
          children: [
            Expanded(child: Text(Textos.coordenadas, style: etiqueta)),
            Text(
              vm.puntoPuesto ? vm.coordenadasTexto : '—',
              style: Tipografia.cuerpoGrande.copyWith(
                fontFamily: 'monospace',
                color: esquema.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: Text(Textos.altura, style: etiqueta)),
            SizedBox(
              width: 150,
              child: TextFormField(
                key: const ValueKey('altura'),
                controller: altura,
                onChanged: vm.cambiarAltitud,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.end,
                style: Tipografia.cuerpoGrande.copyWith(
                  fontWeight: FontWeight.w700,
                  color: esquema.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: '—',
                  suffixText: 'msnm',
                  errorText: vm.errorAltitud,
                ),
              ),
            ),
          ],
        ),
        const Divider(height: 28),
        Text(
          Textos.pregTamano,
          style: Tipografia.cuerpoGrande.copyWith(
            fontWeight: FontWeight.w700,
            color: esquema.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                key: const ValueKey('area'),
                controller: area,
                onChanged: vm.cambiarArea,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: Tipografia.cuerpoGrande.copyWith(
                  color: esquema.onSurface,
                ),
                decoration: InputDecoration(errorText: vm.errorArea),
              ),
            ),
            const SizedBox(width: 10),
            ChipSeleccion(
              texto: Textos.manzanas,
              elegido: vm.unidadArea == 'manzana',
              alTocar: () => vm.elegirUnidad('manzana'),
              radio: Medidas.radioCampo,
            ),
            const SizedBox(width: 8),
            ChipSeleccion(
              texto: Textos.hectareasCorto,
              elegido: vm.unidadArea == 'hectarea',
              alTocar: () => vm.elegirUnidad('hectarea'),
              radio: Medidas.radioCampo,
            ),
          ],
        ),
      ],
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto, required this.tono, required this.icono});

  final String texto;
  final TonoSemaforo tono;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tono.fondo,
          borderRadius: BorderRadius.circular(Medidas.radioCampo),
          border: Border.all(color: tono.borde, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 22, color: tono.icono),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                texto,
                style: Tipografia.cuerpo.copyWith(color: tono.texto),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

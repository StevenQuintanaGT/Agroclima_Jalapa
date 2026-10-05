import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/aviso_apoyo.dart';
import '../../componentes/aviso_no_vigente.dart';
import '../../componentes/boton_principal.dart';
import '../../componentes/boton_secundario.dart';
import '../../componentes/esqueleto_carga.dart';
import '../../componentes/estado_error.dart';
import '../../componentes/estado_vacio.dart';
import '../../componentes/icono_clima.dart';
import '../../componentes/ilustracion_provisional.dart';
import '../../componentes/marca_dato_guardado.dart';
import '../../config/rutas.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/clima_actual.dart';
import '../../modelos/error_clima.dart';
import '../../modelos/parcela.dart';
import '../../utilidades/fechas.dart';
import 'panel_vm.dart';
import 'pronostico_panel.dart';

/// Pantallas 17/18 · Panel principal (HU-07) con los estados 32 (sin
/// conexión), 33 (cargando) y 34 (error). Orden fijo de plans/03 §5; el
/// por horas y los próximos días llegan con HU-08 y el riesgo del día con
/// las alertas (HU-10).
class PanelPantalla extends StatelessWidget {
  const PanelPantalla({super.key});

  void _elegirParcela(BuildContext context, PanelVm vm) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (hoja) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(Textos.elegirParcela, style: Tipografia.subtitulo),
            ),
            for (final parcela in vm.parcelas)
              ListTile(
                minTileHeight: Medidas.alturaFila,
                leading: Icon(
                  parcela.parcelaId == vm.parcela?.parcelaId
                      ? Symbols.radio_button_checked
                      : Symbols.radio_button_unchecked,
                  color: Colores.primario,
                ),
                title: Text(parcela.nombre, style: Tipografia.cuerpoGrande),
                subtitle: Text(Textos.municipio(parcela.municipio)),
                onTap: () {
                  Navigator.of(hoja).pop();
                  vm.elegir(parcela);
                },
              ),
            const Divider(),
            ListTile(
              minTileHeight: Medidas.alturaFila,
              leading: const Icon(Symbols.agriculture),
              title: const Text(Textos.verMisParcelas),
              onTap: () {
                Navigator.of(hoja).pop();
                context.push(Rutas.misParcelas);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PanelVm>();
    final parcela = vm.parcela;
    return _AlVolverALaApp(
      alVolver: vm.alVolverALaApp,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: parcela == null ? null : 72,
          title: parcela == null
              ? const Text(Textos.misParcelas)
              : _Encabezado(
                  parcela: parcela,
                  alTocar: () => _elegirParcela(context, vm),
                ),
        ),
        body: SafeArea(
          child: switch (vm) {
            PanelVm(cargandoParcelas: true) ||
            PanelVm(cargandoClima: true) => const _Cargando(),
            PanelVm(sinParcelas: true) => EstadoVacio(
              icono: Symbols.agriculture,
              titulo: Textos.vacioParcelasTitulo,
              detalle: Textos.vacioParcelasDetalle,
              ilustracion: const IlustracionProvisional(
                icono: Symbols.agriculture,
                colorIcono: Colores.primario,
                colorFondo: Colores.contenedorClaro,
                colorBorde: Colores.bordeIlustracionVerde,
                ancho: 190,
                alto: 170,
              ),
              accion: BotonPrincipal(
                texto: Textos.registrarParcela,
                icono: Symbols.add,
                alPresionar: () => context.push(Rutas.nuevaParcela),
              ),
            ),
            PanelVm(clima: null) => EstadoError(
              titulo: Textos.sinDatosClimaTitulo,
              detalle: Textos.causaErrorClima(
                vm.actual?.error ?? MotivoErrorClima.servicioCaido,
              ),
              alReintentar: vm.actualizar,
            ),
            _ => _Contenido(vm: vm, clima: vm.clima!),
          },
        ),
      ),
    );
  }
}

/// Avisa cuando la app vuelve a primer plano (HU-15: revisar la vigencia).
class _AlVolverALaApp extends StatefulWidget {
  const _AlVolverALaApp({required this.alVolver, required this.child});

  final VoidCallback alVolver;
  final Widget child;

  @override
  State<_AlVolverALaApp> createState() => _AlVolverALaAppState();
}

class _AlVolverALaAppState extends State<_AlVolverALaApp> {
  late final AppLifecycleListener _escucha = AppLifecycleListener(
    onResume: () => widget.alVolver(),
  );

  @override
  void initState() {
    super.initState();
    _escucha;
  }

  @override
  void dispose() {
    _escucha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.parcela, required this.alTocar});

  final Parcela parcela;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final lugar = [
      Textos.municipio(parcela.municipio),
      if (parcela.altitud != null) Textos.msnm(parcela.altitud!),
    ].join(' · ');
    return Semantics(
      button: true,
      label: '${parcela.nombre}, $lugar. ${Textos.elegirParcela}',
      excludeSemantics: true,
      child: InkWell(
        onTap: alTocar,
        child: Row(
          children: [
            const Icon(Symbols.agriculture, size: 28),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          parcela.nombre,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Symbols.arrow_drop_down, size: 28),
                    ],
                  ),
                  Text(
                    lugar,
                    style: Tipografia.cuerpoChico.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.vm, required this.clima});

  final PanelVm vm;
  final ClimaActual clima;

  void _abrirDetalle(BuildContext context, PanelVm vm, {String? dia}) {
    final parcela = vm.parcela;
    if (parcela == null) return;
    context.push(Rutas.detallePronostico(parcela.parcelaId, dia: dia));
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final error = vm.actual?.error;
    final sinInternet = error == MotivoErrorClima.sinConexion;
    final fecha = vm.actual?.fecha;
    return RefreshIndicator(
      onRefresh: vm.actualizar,
      child: ListView(
        padding: const EdgeInsets.only(bottom: Medidas.espacioM),
        children: [
          // Banner de la pantalla 32: sin red en el teléfono, o si la última
          // consulta falló por falta de internet y el dato ya venció.
          if (!vm.enLinea || (sinInternet && !vm.vigente))
            const AvisoNoVigente(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Medidas.margenPantalla,
              Medidas.margenPantalla,
              Medidas.margenPantalla,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!vm.vigente && fecha != null) ...[
                  MarcaDatoGuardado(
                    fechaHora: Textos.fechaYHora(Fechas.aHoraGuatemala(fecha)),
                  ),
                  const SizedBox(height: Medidas.separacionTarjetas),
                ],
                _Apagado(
                  apagado: !vm.vigente,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TarjetaTemperatura(vm: vm, clima: clima),
                      const SizedBox(height: Medidas.separacionTarjetas),
                      _Metricas(vm: vm, clima: clima),
                    ],
                  ),
                ),
                // Con dato vencido, la acción útil va justo debajo (32).
                if (!vm.vigente) ...[
                  const SizedBox(height: Medidas.espacioS),
                  BotonSecundario(
                    texto: Textos.intentarDeNuevo,
                    icono: Symbols.refresh,
                    destacado: true,
                    alPresionar: vm.actualizando ? null : vm.actualizar,
                  ),
                ],
                _Apagado(
                  apagado: !vm.vigente,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (vm.proximasHoras.isNotEmpty)
                        PorHoras(
                          actual: clima,
                          franjas: vm.proximasHoras,
                          alTocar: () => _abrirDetalle(context, vm),
                        ),
                      if (vm.dias.isNotEmpty)
                        ProximosDias(
                          dias: vm.dias,
                          alTocar: (dia) =>
                              _abrirDetalle(context, vm, dia: dia.fecha),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: Medidas.espacioS),
                if (vm.vigente && error != null) ...[
                  Text(
                    '${Textos.noSeActualizoTitulo}. ${Textos.causaErrorClima(error)}',
                    textAlign: TextAlign.center,
                    style: Tipografia.cuerpoChico.copyWith(
                      color: esquema.error,
                    ),
                  ),
                  const SizedBox(height: Medidas.espacioXs),
                ],
                if (vm.antiguedad != null)
                  Text(
                    '${Textos.actualizadoHace(vm.antiguedad!)} · '
                    '${Textos.deslizaParaActualizar.toLowerCase()}',
                    textAlign: TextAlign.center,
                    style: Tipografia.cuerpoChico.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                const SizedBox(height: Medidas.espacioS),
                const AvisoApoyo(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dato guardado con aspecto apagado (pantalla 32): no se confunde con el
/// actual (RNF-08).
class _Apagado extends StatelessWidget {
  const _Apagado({required this.apagado, required this.child});

  final bool apagado;
  final Widget child;

  static const List<double> _grises = [
    0.5, 0.4, 0.1, 0, 0, //
    0.3, 0.6, 0.1, 0, 0, //
    0.3, 0.4, 0.3, 0, 0, //
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) => apagado
      ? ColorFiltered(
          colorFilter: const ColorFilter.matrix(_grises),
          child: Opacity(opacity: 0.85, child: child),
        )
      : child;
}

class _TarjetaTemperatura extends StatelessWidget {
  const _TarjetaTemperatura({required this.vm, required this.clima});

  final PanelVm vm;
  final ClimaActual clima;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final claro = Theme.of(context).brightness == Brightness.light;
    final hoy = vm.hoy;
    final frase = Textos.fraseClima(clima.codigoClima, esDeDia: clima.esDeDia);
    final estiloDato = Tipografia.cuerpo.copyWith(
      color: esquema.onSurfaceVariant,
    );
    final negrita = TextStyle(
      fontWeight: FontWeight.w700,
      color: esquema.onSurface,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: esquema.surface,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        border: Border.all(color: esquema.outlineVariant),
      ),
      child: Column(
        children: [
          Semantics(
            label: '${Textos.grados(clima.temperatura)}, $frase',
            excludeSemantics: true,
            child: Row(
              children: [
                IconoClima(
                  codigo: clima.codigoClima,
                  esDeDia: clima.esDeDia,
                  tamano: 72,
                ),
                const SizedBox(width: Medidas.espacioS),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Textos.grados(clima.temperatura),
                        style: Tipografia.datoDestacado.copyWith(
                          color: esquema.onSurface,
                        ),
                      ),
                      Text(
                        frase,
                        style: Tipografia.titulo.copyWith(
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 28),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: Medidas.espacioS,
            runSpacing: 4,
            children: [
              Text.rich(
                TextSpan(
                  text: '${Textos.seSiente} ',
                  children: [
                    TextSpan(
                      text: Textos.grados(clima.sensacionTermica),
                      style: negrita,
                    ),
                  ],
                ),
                style: estiloDato,
              ),
              if (hoy != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.arrow_upward,
                      size: 20,
                      color: claro
                          ? Colores.peligroBorde
                          : Colores.peligroBordeOscuro,
                    ),
                    Text.rich(
                      TextSpan(
                        text: '${Textos.maxima} ',
                        children: [
                          TextSpan(
                            text: Textos.grados(hoy.temperaturaMaxima),
                            style: negrita,
                          ),
                        ],
                      ),
                      style: estiloDato,
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Symbols.arrow_downward,
                      size: 20,
                      color: claro
                          ? Colores.acentoCielo
                          : Colores.acentoCieloTemaOscuro,
                    ),
                    Text.rich(
                      TextSpan(
                        text: '${Textos.minima} ',
                        children: [
                          TextSpan(
                            text: Textos.grados(hoy.temperaturaMinima),
                            style: negrita,
                          ),
                        ],
                      ),
                      style: estiloDato,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Metricas extends StatelessWidget {
  const _Metricas({required this.vm, required this.clima});

  final PanelVm vm;
  final ClimaActual clima;

  @override
  Widget build(BuildContext context) {
    final claro = Theme.of(context).brightness == Brightness.light;
    final cielo = claro ? Colores.acentoCielo : Colores.acentoCieloTemaOscuro;
    final sol = claro ? Colores.precaucionIcono : Colores.solTemaOscuro;
    final probabilidad = vm.probabilidadLluvia;
    final lluvia = vm.lluviaHoy;
    final viento = clima.direccionViento == null
        ? '${clima.velocidadViento.round()}'
        : '${clima.velocidadViento.round()} ${Textos.rumbo(clima.direccionViento!)}';
    String hora(DateTime? instante) => instante == null
        ? Textos.sinDatoCorto
        : Textos.horaCorta(Fechas.aHoraGuatemala(instante));
    final metricas = [
      _Metrica(
        icono: Symbols.humidity_percentage,
        color: cielo,
        valor: '${clima.humedadRelativa.round()}%',
        etiqueta: Textos.humedad,
      ),
      _Metrica(
        icono: Symbols.air,
        color: cielo,
        valor: viento,
        etiqueta: Textos.vientoKmH,
      ),
      _Metrica(
        icono: Symbols.rainy,
        color: cielo,
        valor: probabilidad == null
            ? Textos.sinDatoCorto
            : Textos.porcentaje(probabilidad),
        etiqueta: Textos.vaALlover,
      ),
      _Metrica(
        icono: Symbols.water_drop,
        color: cielo,
        valor: lluvia == null ? Textos.sinDatoCorto : Textos.milimetros(lluvia),
        etiqueta: Textos.llovioHoy,
      ),
      _Metrica(
        icono: Symbols.wb_twilight,
        color: sol,
        valor: hora(clima.salidaSol),
        etiqueta: Textos.saleElSol,
      ),
      _Metrica(
        icono: Symbols.wb_twilight,
        color: sol,
        valor: hora(clima.puestaSol),
        etiqueta: Textos.seOcultaElSol,
      ),
    ];
    return Column(
      children: [
        for (var fila = 0; fila < metricas.length; fila += 3) ...[
          if (fila > 0) const SizedBox(height: Medidas.separacionTarjetas),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = fila; i < fila + 3; i++) ...[
                  if (i > fila)
                    const SizedBox(width: Medidas.separacionTarjetas),
                  Expanded(child: metricas[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({
    required this.icono,
    required this.color,
    required this.valor,
    required this.etiqueta,
  });

  final IconData icono;
  final Color color;
  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Semantics(
      label: '$etiqueta: $valor',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
        decoration: BoxDecoration(
          color: esquema.surface,
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          border: Border.all(color: esquema.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 28, color: color),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                valor,
                style: Tipografia.subtitulo.copyWith(
                  fontSize: 20,
                  color: esquema.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              textAlign: TextAlign.center,
              style: Tipografia.cuerpoChico.copyWith(
                color: esquema.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Esqueleto con la forma del panel (pantalla 33).
class _Cargando extends StatelessWidget {
  const _Cargando();

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(Medidas.margenPantalla),
      children: [
        const EsqueletoCarga(alto: 190, radio: Medidas.radioTarjeta),
        const SizedBox(height: Medidas.separacionTarjetas),
        const Row(
          children: [
            Expanded(
              child: EsqueletoCarga(alto: 110, radio: Medidas.radioTarjeta),
            ),
            SizedBox(width: Medidas.separacionTarjetas),
            Expanded(
              child: EsqueletoCarga(alto: 110, radio: Medidas.radioTarjeta),
            ),
            SizedBox(width: Medidas.separacionTarjetas),
            Expanded(
              child: EsqueletoCarga(alto: 110, radio: Medidas.radioTarjeta),
            ),
          ],
        ),
        const SizedBox(height: Medidas.espacioM),
        Text(
          Textos.cargandoClima,
          textAlign: TextAlign.center,
          style: Tipografia.cuerpo.copyWith(color: esquema.onSurfaceVariant),
        ),
      ],
    );
  }
}

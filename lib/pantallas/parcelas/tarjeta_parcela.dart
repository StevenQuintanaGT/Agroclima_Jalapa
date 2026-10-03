import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../componentes/chip_semaforo.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/colores_semaforo.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/enums.dart';
import '../../modelos/parcela.dart';

/// Tarjeta de "Mis parcelas" (pantalla 14): nombre, municipio, cultivo y, si
/// hay dato, temperatura y semáforo. Al deslizarla a la izquierda aparecen
/// "Editar" y "Borrar" con ícono y palabra; tocarla abre el detalle, que
/// tiene las mismas acciones, para quien no descubra el gesto.
class TarjetaParcela extends StatefulWidget {
  const TarjetaParcela({
    super.key,
    required this.parcela,
    required this.alTocar,
    required this.alEditar,
    required this.alBorrar,
    this.temperatura,
    this.nivel,
  });

  final Parcela parcela;
  final VoidCallback alTocar;
  final VoidCallback alEditar;
  final VoidCallback alBorrar;

  /// °C, ya convertida a la unidad del productor si hace falta.
  final int? temperatura;

  /// Nivel más alto de las alertas activas de la parcela.
  final NivelSeveridad? nivel;

  /// Ancho de cada botón escondido.
  static const double anchoAccion = 76;

  @override
  State<TarjetaParcela> createState() => _TarjetaParcelaState();
}

class _TarjetaParcelaState extends State<TarjetaParcela>
    with SingleTickerProviderStateMixin {
  static const double _recorrido = TarjetaParcela.anchoAccion * 2;

  late final AnimationController _apertura = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  @override
  void dispose() {
    _apertura.dispose();
    super.dispose();
  }

  void _arrastrar(DragUpdateDetails detalle) {
    _apertura.value -= detalle.primaryDelta! / _recorrido;
  }

  void _soltar(DragEndDetails detalle) {
    final velocidad = detalle.primaryVelocity ?? 0;
    if (velocidad < -300 || (velocidad <= 300 && _apertura.value > 0.5)) {
      _apertura.forward();
    } else {
      _apertura.reverse();
    }
  }

  void _tocar() {
    if (_apertura.value > 0) {
      _apertura.reverse();
    } else {
      widget.alTocar();
    }
  }

  void _accion(VoidCallback accion) {
    _apertura.reverse();
    accion();
  }

  @override
  Widget build(BuildContext context) {
    final parcela = widget.parcela;
    return Semantics(
      button: true,
      label: Textos.accionesDeParcela(parcela.nombre),
      customSemanticsActions: {
        const CustomSemanticsAction(label: Textos.editar): widget.alEditar,
        const CustomSemanticsAction(label: Textos.borrar): widget.alBorrar,
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        child: Stack(
          children: [
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Accion(
                    icono: Symbols.edit,
                    texto: Textos.editar,
                    color: Colores.acentoCielo,
                    alPresionar: () => _accion(widget.alEditar),
                  ),
                  _Accion(
                    icono: Symbols.delete,
                    texto: Textos.borrar,
                    color: Colores.peligroBorde,
                    alPresionar: () => _accion(widget.alBorrar),
                  ),
                ],
              ),
            ),
            // Al abrir, la tarjeta se angosta y esconde la miniatura (como en
            // el diseño): el nombre sigue completo junto a los botones.
            AnimatedBuilder(
              animation: _apertura,
              builder: (context, _) => Padding(
                padding: EdgeInsets.only(right: _recorrido * _apertura.value),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _tocar,
                  onHorizontalDragUpdate: _arrastrar,
                  onHorizontalDragEnd: _soltar,
                  child: _Contenido(
                    parcela: parcela,
                    temperatura: widget.temperatura,
                    nivel: widget.nivel,
                    apertura: _apertura.value,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({
    required this.parcela,
    required this.temperatura,
    required this.nivel,
    required this.apertura,
  });

  final Parcela parcela;
  final int? temperatura;
  final NivelSeveridad? nivel;

  /// 0 cerrada, 1 con los botones a la vista.
  final double apertura;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final esClaro = Theme.of(context).brightness == Brightness.light;
    final cultivo = parcela.cultivo == null
        ? Textos.sinSembrar
        : Textos.cultivo(parcela.cultivo!);
    final colorPin = nivel == null
        ? esquema.primary
        : ColoresSemaforo.of(context).de(nivel!).borde;
    return Container(
      decoration: BoxDecoration(
        color: esquema.surface,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        border: Border.all(color: esquema.outlineVariant),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Miniatura sin teselas: no gasta datos por cada tarjeta.
            Container(
              width: 96 * (1 - apertura),
              color: esClaro
                  ? Colores.fondoMiniMapa
                  : Colores.fondoMiniMapaOscuro,
              alignment: Alignment.center,
              child: apertura > 0.5
                  ? null
                  : Icon(Symbols.location_on, size: 30, color: colorPin),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      parcela.nombre,
                      style: Tipografia.subtitulo.copyWith(
                        fontSize: 20,
                        color: esquema.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${Textos.municipio(parcela.municipio)} · $cultivo',
                      style: Tipografia.cuerpo.copyWith(
                        color: esquema.onSurfaceVariant,
                      ),
                    ),
                    if (temperatura != null || nivel != null) ...[
                      const SizedBox(height: Medidas.espacioXs),
                      Wrap(
                        spacing: Medidas.espacioXs,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (temperatura != null)
                            Text(
                              '$temperatura°',
                              style: Tipografia.datoGrande.copyWith(
                                fontSize: 26,
                                color: esquema.onSurface,
                              ),
                            ),
                          if (nivel != null) ChipSemaforo(nivel: nivel!),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Accion extends StatelessWidget {
  const _Accion({
    required this.icono,
    required this.texto,
    required this.color,
    required this.alPresionar,
  });

  final IconData icono;
  final String texto;
  final Color color;
  final VoidCallback alPresionar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: TarjetaParcela.anchoAccion,
      child: Material(
        color: color,
        child: InkWell(
          onTap: alPresionar,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: 26, color: Colors.white),
              const SizedBox(height: 2),
              Text(
                texto,
                style: Tipografia.etiquetaChica.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

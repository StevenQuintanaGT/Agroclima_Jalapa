import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/aviso_apoyo.dart';
import '../../componentes/boton_principal.dart';
import '../../componentes/boton_secundario.dart';
import '../../componentes/chip_semaforo.dart';
import '../../componentes/esqueleto_carga.dart';
import '../../componentes/estado_vacio.dart';
import '../../componentes/icono_riesgo.dart';
import '../../config/rutas.dart';
import '../../config/tema/colores_semaforo.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/alerta.dart';
import '../../modelos/parcela.dart';
import 'detalle_alerta_vm.dart';

/// Detalle de alerta (pantalla 22, HU-11): qué pasa y cuándo, lo esperado
/// frente a lo que aguanta el cultivo (D-14), qué hacer, "Ya tomé medidas"
/// y compartir por WhatsApp. Siempre como información de apoyo (RN-07).
class DetalleAlertaPantalla extends StatelessWidget {
  const DetalleAlertaPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DetalleAlertaVm>();
    final alerta = vm.alerta;
    if (vm.cargando) {
      return Scaffold(
        appBar: AppBar(),
        body: const Padding(
          padding: EdgeInsets.all(Medidas.margenPantalla),
          child: Column(
            children: [
              EsqueletoCarga(alto: 110),
              SizedBox(height: Medidas.separacionTarjetas),
              EsqueletoCarga(alto: 200),
            ],
          ),
        ),
      );
    }
    if (alerta == null) {
      return Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: EstadoVacio(
            icono: Symbols.notifications_off,
            titulo: Textos.alertaNoEsta,
            detalle: Textos.alertaNoEstaDetalle,
            accion: BotonPrincipal(
              texto: Textos.verAvisos,
              alPresionar: () => context.go(Rutas.alertas),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: Column(
        children: [
          _Encabezado(alerta: alerta),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(Medidas.margenPantalla),
              children: [
                _Cuando(alerta: alerta, parcela: vm.parcela, ahora: vm.ahora),
                const SizedBox(height: Medidas.separacionTarjetas),
                _PorQue(alerta: alerta),
                if (vm.medidas.isNotEmpty) ...[
                  const SizedBox(height: Medidas.espacioM),
                  Text(
                    Textos.quePuedeHacer,
                    style: Tipografia.titulo.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _Medidas(medidas: vm.medidas),
                ],
                const SizedBox(height: Medidas.espacioM),
                const AvisoApoyo(),
              ],
            ),
          ),
          _Acciones(
            atendida: alerta.atendida,
            alAtender: vm.atender,
            alCompartir: vm.compartir,
          ),
        ],
      ),
    );
  }
}

/// Encabezado del color del nivel, con el riesgo en grande.
class _Encabezado extends StatelessWidget {
  const _Encabezado({required this.alerta});

  final Alerta alerta;

  @override
  Widget build(BuildContext context) {
    final claro = Theme.of(context).brightness == Brightness.light;
    final tono = ColoresSemaforo.of(context).de(alerta.nivel);
    // En claro, fondo fuerte y letra blanca; en oscuro, fondo apagado.
    final fondo = claro ? tono.icono : tono.fondo;
    final letra = claro ? Colors.white : tono.texto;
    final palabra = Textos.palabraNivel(alerta.nivel);
    // Fondo oscuro en claro y en oscuro: íconos claros en la barra de estado.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        color: fondo,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              4,
              4,
              Medidas.margenPantalla,
              20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BackButton(color: letra),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      Icon(IconoRiesgo.de(alerta), size: 52, color: letra),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              label: palabra,
                              excludeSemantics: true,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: letra.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      ChipSemaforo.iconoDe(alerta.nivel),
                                      size: 16,
                                      color: letra,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      palabra,
                                      style: Tipografia.etiquetaChica.copyWith(
                                        color: letra,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Semantics(
                              header: true,
                              child: Text(
                                Textos.tituloAlerta(alerta),
                                style: Tipografia.titular.copyWith(
                                  color: letra,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Parcela, cultivo y etapa, y cuándo pasa.
class _Cuando extends StatelessWidget {
  const _Cuando({
    required this.alerta,
    required this.parcela,
    required this.ahora,
  });

  final Alerta alerta;
  final Parcela? parcela;
  final DateTime ahora;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final tono = ColoresSemaforo.of(context).de(alerta.nivel);
    final linea = Textos.parcelaYCultivo(
      parcela?.nombre ?? alerta.parcelaNombre,
      parcela?.cultivo ?? alerta.cultivo,
      parcela?.etapa,
    );
    return _Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Fila(
            icono: Symbols.agriculture,
            colorIcono: esquema.primary,
            child: Text(
              linea,
              style: Tipografia.cuerpoGrande.copyWith(
                color: esquema.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Fila(
            icono: Symbols.schedule,
            colorIcono: tono.icono,
            child: Text(
              Textos.cuandoAlerta(alerta, ahora),
              style: Tipografia.cuerpoGrande.copyWith(
                fontWeight: FontWeight.w700,
                color: esquema.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Por qué le avisamos": lo esperado frente a lo que aguanta el cultivo,
/// como comparación y en una frase (no como fórmula).
class _PorQue extends StatelessWidget {
  const _PorQue({required this.alerta});

  final Alerta alerta;

  @override
  Widget build(BuildContext context) {
    final tono = ColoresSemaforo.of(context).de(alerta.nivel);
    Widget columna(String etiqueta, String valor, {required bool fuerte}) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              etiqueta,
              style: Tipografia.cuerpo.copyWith(color: tono.texto),
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: (fuerte ? Tipografia.datoGrande : Tipografia.titular)
                  .copyWith(color: fuerte ? tono.icono : tono.texto),
            ),
          ],
        );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tono.fondo,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        border: Border.all(color: tono.borde, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Textos.porQueAvisamos,
            style: Tipografia.subtitulo.copyWith(
              fontWeight: FontWeight.w700,
              color: tono.texto,
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: columna(
                    Textos.seEspera(alerta.tipoRiesgo),
                    Textos.valorAlerta(alerta.tipoRiesgo, alerta.valorEsperado),
                    fuerte: true,
                  ),
                ),
                VerticalDivider(
                  width: 24,
                  thickness: 2,
                  color: tono.borde.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: columna(
                    Textos.aguanta(alerta.cultivo, alerta.tipoRiesgo),
                    Textos.valorAlerta(alerta.tipoRiesgo, alerta.valorUmbral),
                    fuerte: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            Textos.diferenciaAlerta(alerta),
            style: Tipografia.cuerpoGrande.copyWith(color: tono.texto),
          ),
        ],
      ),
    );
  }
}

class _Medidas extends StatelessWidget {
  const _Medidas({required this.medidas});

  final List<String> medidas;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return _Tarjeta(
      relleno: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < medidas.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(18),
              child: _Fila(
                icono: Symbols.task_alt,
                colorIcono: esquema.primary,
                child: Text(
                  medidas[i],
                  style: Tipografia.cuerpoGrande.copyWith(
                    color: esquema.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Acciones al pie, donde alcanza el pulgar.
class _Acciones extends StatelessWidget {
  const _Acciones({
    required this.atendida,
    required this.alAtender,
    required this.alCompartir,
  });

  final bool atendida;
  final VoidCallback alAtender;
  final VoidCallback alCompartir;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: esquema.surface,
        border: Border(top: BorderSide(color: esquema.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Medidas.margenPantalla),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BotonPrincipal(
                texto: atendida ? Textos.yaTomoMedidas : Textos.yaTomeMedidas,
                icono: Symbols.check,
                alPresionar: atendida ? null : alAtender,
              ),
              const SizedBox(height: 12),
              BotonSecundario(
                texto: Textos.avisarWhatsApp,
                icono: Symbols.share,
                alPresionar: alCompartir,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.child,
    this.relleno = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsets relleno;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: relleno,
      decoration: BoxDecoration(
        color: esquema.surface,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        border: Border.all(color: esquema.outlineVariant),
      ),
      child: child,
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.icono,
    required this.colorIcono,
    required this.child,
  });

  final IconData icono;
  final Color colorIcono;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icono, size: 26, color: colorIcono),
      const SizedBox(width: 14),
      Expanded(child: child),
    ],
  );
}

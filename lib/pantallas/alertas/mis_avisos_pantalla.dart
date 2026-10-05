import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/chip_semaforo.dart';
import '../../componentes/icono_riesgo.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/colores_semaforo.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/enums.dart';
import '../../modelos/umbral.dart';
import 'mis_avisos_vm.dart';

/// "Mis avisos" (pantalla 23, HU-12): interruptor por tipo de riesgo, desde
/// qué nivel avisar y no sonar de noche (PELIGRO suena igual). Lo que
/// aguanta el cultivo se muestra pero no se cambia (D-20).
class MisAvisosPantalla extends StatelessWidget {
  const MisAvisosPantalla({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MisAvisosVm>();
    final esquema = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text(Textos.misAvisos)),
      body: ListView(
        padding: const EdgeInsets.all(Medidas.margenPantalla),
        children: [
          const _Titulo(Textos.deQueAvisamos),
          _Tarjeta(
            child: Column(
              children: [
                for (final p in vm.preferencias) ...[
                  if (p != vm.preferencias.first) const Divider(height: 1),
                  _Interruptor(
                    tipo: p.tipoRiesgo,
                    activa: p.activa,
                    alCambiar: (valor) => vm.cambiarActiva(p.tipoRiesgo, valor),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Symbols.info, size: 20, color: esquema.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  Textos.aunqueApague,
                  style: Tipografia.cuerpo.copyWith(
                    color: esquema.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const _Titulo(Textos.avisarmeDesde),
          Row(
            children: [
              for (final nivel in NivelSeveridad.values) ...[
                if (nivel != NivelSeveridad.values.first)
                  const SizedBox(width: 10),
                Expanded(
                  child: _OpcionNivel(
                    nivel: nivel,
                    elegida: vm.nivelMinimo == nivel,
                    alTocar: () => vm.cambiarNivelMinimo(nivel),
                  ),
                ),
              ],
            ],
          ),
          const _Titulo(Textos.noSonarDeNoche),
          _Tarjeta(
            child: MergeSemantics(
              child: SwitchListTile(
                value: vm.silencioActivo,
                onChanged: vm.cambiarSilencio,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                secondary: Icon(
                  Symbols.bedtime,
                  size: 28,
                  color: esquema.onSurfaceVariant,
                ),
                title: Text(
                  Textos.horarioSilencio(vm.silencioDesde, vm.silencioHasta),
                  style: Tipografia.subtitulo.copyWith(
                    color: esquema.onSurface,
                  ),
                ),
                subtitle: Text(
                  Textos.peligroSiSuena,
                  style: Tipografia.cuerpo.copyWith(
                    color: esquema.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          if (vm.limites.isNotEmpty) ...[
            const _Titulo(Textos.loQueAguanta),
            Text(
              Textos.loQueAguantaDetalle,
              style: Tipografia.cuerpo.copyWith(
                color: esquema.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            for (final entrada in vm.limites.entries) ...[
              _Limites(cultivo: entrada.key, umbrales: entrada.value),
              const SizedBox(height: Medidas.separacionTarjetas),
            ],
          ],
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Medidas.espacioM, bottom: 10),
    child: Semantics(
      header: true,
      child: Text(
        texto,
        style: Tipografia.titulo.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
  );
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Material(
      color: esquema.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        side: BorderSide(color: esquema.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _Interruptor extends StatelessWidget {
  const _Interruptor({
    required this.tipo,
    required this.activa,
    required this.alCambiar,
  });

  final TipoRiesgo tipo;
  final bool activa;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final claro = Theme.of(context).brightness == Brightness.light;
    final colorTipo = switch (tipo) {
      TipoRiesgo.temperaturaBaja ||
      TipoRiesgo.lluviaIntensa ||
      TipoRiesgo.humedadAlta =>
        claro ? Colores.acentoCielo : Colores.acentoCieloTemaOscuro,
      TipoRiesgo.sequia || TipoRiesgo.temperaturaAlta => ColoresSemaforo.of(
        context,
      ).precaucion.icono,
      TipoRiesgo.vientoFuerte => esquema.onSurfaceVariant,
    };
    // Apagado: ícono y nombre en gris, como en el diseño.
    final apagado = esquema.onSurfaceVariant.withValues(alpha: 0.75);
    return MergeSemantics(
      child: SwitchListTile(
        value: activa,
        onChanged: alCambiar,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        secondary: Icon(
          IconoRiesgo.deTipo(tipo),
          size: 28,
          color: activa ? colorTipo : apagado,
        ),
        title: Text(
          Textos.tipoAviso(tipo),
          style: Tipografia.cuerpoGrande.copyWith(
            fontWeight: FontWeight.w500,
            color: activa ? esquema.onSurface : apagado,
          ),
        ),
      ),
    );
  }
}

class _OpcionNivel extends StatelessWidget {
  const _OpcionNivel({
    required this.nivel,
    required this.elegida,
    required this.alTocar,
  });

  final NivelSeveridad nivel;
  final bool elegida;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final tono = ColoresSemaforo.of(context).de(nivel);
    return Semantics(
      button: true,
      selected: elegida,
      label: '${Textos.avisarmeDesde}: ${Textos.nivelMinimo(nivel)}',
      excludeSemantics: true,
      child: Material(
        color: elegida ? tono.fondo : esquema.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          side: BorderSide(
            color: elegida ? tono.borde : esquema.outlineVariant,
            width: elegida ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: alTocar,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 96),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    ChipSemaforo.iconoDe(nivel),
                    size: 28,
                    color: tono.icono,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    Textos.nivelMinimo(nivel),
                    textAlign: TextAlign.center,
                    style: Tipografia.cuerpo.copyWith(
                      fontWeight: elegida ? FontWeight.w700 : FontWeight.w500,
                      color: elegida ? tono.texto : esquema.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lo que aguanta un cultivo: un renglón por tipo de riesgo.
class _Limites extends StatelessWidget {
  const _Limites({required this.cultivo, required this.umbrales});

  final Cultivo? cultivo;
  final List<Umbral> umbrales;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return _Tarjeta(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Symbols.agriculture, size: 24, color: esquema.primary),
                const SizedBox(width: 10),
                Text(
                  cultivo == null
                      ? Textos.sinCultivoAguanta
                      : Textos.cultivo(cultivo!),
                  style: Tipografia.subtitulo.copyWith(
                    fontWeight: FontWeight.w700,
                    color: esquema.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final umbral in umbrales)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      IconoRiesgo.deTipo(umbral.tipoRiesgo),
                      size: 22,
                      color: esquema.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        Textos.tipoAviso(umbral.tipoRiesgo),
                        style: Tipografia.cuerpoGrande.copyWith(
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Text(
                      Textos.valorAlerta(umbral.tipoRiesgo, umbral.valor),
                      style: Tipografia.cuerpoGrande.copyWith(
                        fontWeight: FontWeight.w700,
                        color: esquema.onSurface,
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

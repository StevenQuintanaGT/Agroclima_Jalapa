import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../componentes/icono_clima.dart';
import '../../config/tema/colores.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/clima_actual.dart';
import '../../modelos/franja_pronostico.dart';
import '../../modelos/resumen_dia.dart';
import '../../utilidades/fechas.dart';

/// "Hoy, hora por hora" del panel (pantalla 17, HU-08): ahora y las
/// próximas franjas de 3 h, con ícono, temperatura y probabilidad de lluvia.
class PorHoras extends StatelessWidget {
  const PorHoras({
    super.key,
    required this.actual,
    required this.franjas,
    required this.alTocar,
  });

  final ClimaActual actual;
  final List<FranjaPronostico> franjas;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final columnas = [
      _Hora(
        titulo: Textos.ahora,
        codigo: actual.codigoClima,
        esDeDia: actual.esDeDia,
        temperatura: actual.temperatura,
      ),
      for (final franja in franjas)
        _Hora(
          titulo: Textos.horaSinMinutos(
            Fechas.aHoraGuatemala(franja.fechaHora),
          ),
          codigo: franja.codigoClima,
          esDeDia: _esDeDia(franja.fechaHora),
          temperatura: franja.temperatura,
          probabilidad: franja.probabilidadLluvia,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Titulo(Textos.horaPorHora),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: columnas.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: Medidas.separacionTarjetas),
            itemBuilder: (_, i) => InkWell(
              borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
              onTap: alTocar,
              child: columnas[i],
            ),
          ),
        ),
      ],
    );
  }

  static bool _esDeDia(DateTime instante) {
    final hora = Fechas.aHoraGuatemala(instante).hour;
    return hora >= 6 && hora < 18;
  }
}

class _Hora extends StatelessWidget {
  const _Hora({
    required this.titulo,
    required this.codigo,
    required this.esDeDia,
    required this.temperatura,
    this.probabilidad,
  });

  final String titulo;
  final int codigo;
  final bool esDeDia;
  final double temperatura;
  final double? probabilidad;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final claro = Theme.of(context).brightness == Brightness.light;
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: esquema.surface,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
        border: Border.all(color: esquema.outlineVariant),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            titulo,
            style: Tipografia.cuerpoChico.copyWith(
              color: esquema.onSurfaceVariant,
            ),
          ),
          IconoClima(codigo: codigo, esDeDia: esDeDia, tamano: 32),
          Text(
            Textos.grados(temperatura),
            style: Tipografia.subtitulo.copyWith(color: esquema.onSurface),
          ),
          Text(
            probabilidad == null ? ' ' : Textos.porcentaje(probabilidad!),
            style: Tipografia.cuerpoChico.copyWith(
              color: claro
                  ? Colores.acentoCielo
                  : Colores.acentoCieloTemaOscuro,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Los próximos días" del panel (HU-08): una fila por día; tocarla abre el
/// detalle de ese día (pantalla 19).
class ProximosDias extends StatelessWidget {
  const ProximosDias({super.key, required this.dias, required this.alTocar});

  final List<ResumenDia> dias;
  final void Function(ResumenDia dia) alTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Titulo(Textos.proximosDias(dias.length)),
        Container(
          decoration: BoxDecoration(
            color: esquema.surface,
            borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
            border: Border.all(color: esquema.outlineVariant),
          ),
          child: Column(
            children: [
              for (var i = 0; i < dias.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _FilaDia(
                  dia: dias[i],
                  esHoy: i == 0,
                  alTocar: () => alTocar(dias[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilaDia extends StatelessWidget {
  const _FilaDia({
    required this.dia,
    required this.esHoy,
    required this.alTocar,
  });

  final ResumenDia dia;
  final bool esHoy;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final claro = Theme.of(context).brightness == Brightness.light;
    final nombre = esHoy ? Textos.hoy : Textos.nombreDia(dia.dia);
    return Semantics(
      button: true,
      label:
          '$nombre: ${Textos.maxima} ${Textos.grados(dia.temperaturaMaxima)}, '
          '${Textos.minima} ${Textos.grados(dia.temperaturaMinima)}'
          '${dia.probabilidadLluvia == null ? '' : ', ${Textos.vaALlover} ${Textos.porcentaje(dia.probabilidadLluvia!)}'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: alTocar,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Medidas.alturaFila),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    nombre,
                    style: Tipografia.cuerpoGrande.copyWith(
                      fontWeight: FontWeight.w500,
                      color: esquema.onSurface,
                    ),
                  ),
                ),
                if (dia.codigoClima != null)
                  IconoClima(
                    codigo: dia.codigoClima!,
                    esDeDia: true,
                    tamano: 28,
                  ),
                SizedBox(
                  width: 52,
                  child: Text(
                    dia.probabilidadLluvia == null
                        ? ''
                        : Textos.porcentaje(dia.probabilidadLluvia!),
                    textAlign: TextAlign.right,
                    style: Tipografia.cuerpo.copyWith(
                      color: claro
                          ? Colores.acentoCielo
                          : Colores.acentoCieloTemaOscuro,
                    ),
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: Text.rich(
                    TextSpan(
                      text: '${Textos.grados(dia.temperaturaMaxima)} ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: esquema.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text: Textos.grados(dia.temperaturaMinima),
                          style: TextStyle(
                            fontWeight: FontWeight.w400,
                            color: esquema.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.right,
                    style: Tipografia.cuerpoGrande,
                  ),
                ),
                Icon(
                  Symbols.chevron_right,
                  size: 22,
                  color: esquema.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
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
    child: Text(
      texto,
      style: Tipografia.titulo.copyWith(
        fontSize: 22,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

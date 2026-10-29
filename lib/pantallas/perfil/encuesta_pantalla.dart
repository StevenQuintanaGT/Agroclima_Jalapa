import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../componentes/boton_principal.dart';
import '../../componentes/campo_texto.dart';
import '../../componentes/chip_seleccion.dart';
import '../../config/tema/medidas.dart';
import '../../config/tema/tipografia.dart';
import '../../config/textos.dart';
import '../../modelos/respuestas_encuesta.dart';
import '../../utilidades/fechas.dart';
import 'encuesta_vm.dart';

/// "Su opinión" (Perfil → debajo de Ayuda, D-58): encuesta de satisfacción
/// de 8 preguntas con pastillas, más el permiso para el trabajo de
/// graduación. Si ya respondió, muestra sus respuestas para cambiarlas.
class EncuestaPantalla extends StatelessWidget {
  const EncuestaPantalla({super.key});

  Future<void> _enviar(BuildContext context, EncuestaVm vm) async {
    final mensajero = ScaffoldMessenger.of(context);
    final enviada = await vm.enviar();
    mensajero.showSnackBar(
      SnackBar(
        content: Text(
          enviada ? Textos.graciasOpinion : Textos.opinionNoSeEnvio,
        ),
      ),
    );
    if (enviada && context.mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EncuestaVm>();
    final esquema = Theme.of(context).colorScheme;
    final r = vm.respuestas;
    return Scaffold(
      appBar: AppBar(title: const Text(Textos.suOpinion)),
      body: vm.cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                Medidas.margenPantalla,
                Medidas.espacioS,
                Medidas.margenPantalla,
                Medidas.espacioL,
              ),
              children: [
                Text(Textos.encuestaIntro, style: Tipografia.cuerpoGrande),
                if (vm.yaRespondio) ...[
                  const SizedBox(height: Medidas.espacioS),
                  _YaRespondio(fecha: vm.fechaRespuesta),
                ],
                _Pregunta(texto: Textos.preguntaFacil, pregunta: 'p1', vm: vm),
                _Pregunta(
                  texto: Textos.preguntaColores,
                  pregunta: 'p2',
                  vm: vm,
                ),
                _Pregunta(
                  texto: Textos.preguntaLlegoAviso,
                  pregunta: 'p3',
                  vm: vm,
                ),
                if (r.p3 == 'si')
                  _Detalle(
                    etiqueta: Textos.deQueFueAviso,
                    valor: r.detalleAviso,
                    alCambiar: vm.cambiarDetalleAviso,
                  ),
                _Pregunta(
                  texto: Textos.preguntaPlanificar,
                  pregunta: 'p4',
                  vm: vm,
                ),
                _Pregunta(
                  texto: Textos.preguntaHizoAlgo,
                  pregunta: 'p5',
                  vm: vm,
                ),
                if (r.p5 == 'si')
                  _Detalle(
                    etiqueta: Textos.queHizo,
                    valor: r.detalleAccion,
                    alCambiar: vm.cambiarDetalleAccion,
                  ),
                _Pregunta(
                  texto: Textos.preguntaEvitoDanio,
                  pregunta: 'p6',
                  vm: vm,
                ),
                if (r.p6 == 'si')
                  _Detalle(
                    etiqueta: Textos.cualDanio,
                    valor: r.detalleDanio,
                    alCambiar: vm.cambiarDetalleDanio,
                  ),
                _Pregunta(
                  texto: Textos.preguntaRecomendaria,
                  pregunta: 'p7',
                  vm: vm,
                ),
                const SizedBox(height: Medidas.espacioM),
                CampoTexto(
                  etiqueta: Textos.preguntaCambiaria,
                  ayuda: Textos.sugerenciaAyuda,
                  valorInicial: r.p8,
                  alCambiar: vm.cambiarSugerencia,
                  lineas: 4,
                  accionTeclado: TextInputAction.newline,
                ),
                const SizedBox(height: Medidas.espacioM),
                const Divider(),
                _Titulo(Textos.preguntaPermiso),
                Wrap(
                  spacing: Medidas.espacioXs,
                  runSpacing: Medidas.espacioXs,
                  children: [
                    ChipSeleccion(
                      texto: Textos.si,
                      elegido: r.consentimiento == true,
                      alTocar: () => vm.cambiarConsentimiento(true),
                    ),
                    ChipSeleccion(
                      texto: Textos.no,
                      elegido: r.consentimiento == false,
                      alTocar: () => vm.cambiarConsentimiento(false),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  Textos.permisoAyuda,
                  style: Tipografia.cuerpoChico.copyWith(
                    color: esquema.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: Medidas.espacioM),
                if (!r.completa) ...[
                  Text(
                    Textos.faltanRespuestas,
                    style: Tipografia.cuerpoChico.copyWith(
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Medidas.espacioS),
                ],
                BotonPrincipal(
                  texto: Textos.enviar,
                  icono: Symbols.send,
                  cargando: vm.enviando,
                  textoCargando: Textos.enviandoOpinion,
                  alPresionar: vm.puedeEnviar
                      ? () => _enviar(context, vm)
                      : null,
                ),
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
    padding: const EdgeInsets.only(
      top: Medidas.espacioM,
      bottom: Medidas.espacioS,
    ),
    child: Text(texto, style: Tipografia.subtitulo),
  );
}

/// Una pregunta de opción única: el texto y sus pastillas.
class _Pregunta extends StatelessWidget {
  const _Pregunta({
    required this.texto,
    required this.pregunta,
    required this.vm,
  });

  final String texto;
  final String pregunta;
  final EncuestaVm vm;

  @override
  Widget build(BuildContext context) {
    final elegido = vm.respuestas.elegido(pregunta);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Titulo(texto),
        Wrap(
          spacing: Medidas.espacioXs,
          runSpacing: Medidas.espacioXs,
          children: [
            for (final valor in RespuestasEncuesta.opciones[pregunta]!)
              ChipSeleccion(
                texto: Textos.opcionEncuesta(pregunta, valor),
                elegido: elegido == valor,
                alTocar: () => vm.elegir(pregunta, valor),
              ),
          ],
        ),
      ],
    );
  }
}

/// Texto opcional que aparece al responder "Sí".
class _Detalle extends StatelessWidget {
  const _Detalle({
    required this.etiqueta,
    required this.valor,
    required this.alCambiar,
  });

  final String etiqueta;
  final String? valor;
  final ValueChanged<String> alCambiar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Medidas.espacioS),
    child: CampoTexto(
      etiqueta: etiqueta,
      valorInicial: valor,
      alCambiar: alCambiar,
      lineas: 3,
      accionTeclado: TextInputAction.newline,
    ),
  );
}

/// Aviso en verde claro: ya respondió y puede cambiar sus respuestas.
class _YaRespondio extends StatelessWidget {
  const _YaRespondio({required this.fecha});

  final DateTime? fecha;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final local = fecha == null ? null : Fechas.aHoraGuatemala(fecha!);
    return Container(
      padding: const EdgeInsets.all(Medidas.espacioS),
      decoration: BoxDecoration(
        color: esquema.primaryContainer,
        borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
      ),
      child: Row(
        children: [
          Icon(Symbols.check_circle, color: esquema.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              Textos.yaRespondioEncuesta(local),
              style: Tipografia.cuerpo.copyWith(
                color: esquema.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

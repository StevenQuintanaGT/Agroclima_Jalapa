import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../config/tema/colores.dart';
import '../config/tema/medidas.dart';
import '../config/tema/tipografia.dart';
import '../config/textos.dart';

/// Campo de formulario del diseño: etiqueta escrita como se habla encima,
/// 56 dp, borde de 2 dp. Si el valor es válido muestra palomita verde
/// (validación positiva); si hay error, borde rojo y mensaje debajo.
/// Las contraseñas llevan el botón "Ver" con palabra, no solo el ojo.
class CampoTexto extends StatefulWidget {
  const CampoTexto({
    super.key,
    required this.etiqueta,
    required this.alCambiar,
    this.valorInicial,
    this.ayuda,
    this.error,
    this.valido = false,
    this.prefijo,
    this.icono,
    this.esContrasena = false,
    this.teclado,
    this.accionTeclado = TextInputAction.next,
    this.autocompletar,
    this.formatos,
    this.alEnviar,
  });

  final String etiqueta;
  final ValueChanged<String> alCambiar;
  final String? valorInicial;

  /// Texto de ayuda visible desde el inicio (no solo al fallar).
  final String? ayuda;
  final String? error;
  final bool valido;

  /// Texto fijo antes del valor, p. ej. "+502".
  final String? prefijo;
  final IconData? icono;
  final bool esContrasena;
  final TextInputType? teclado;
  final TextInputAction accionTeclado;
  final Iterable<String>? autocompletar;
  final List<TextInputFormatter>? formatos;
  final ValueChanged<String>? alEnviar;

  @override
  State<CampoTexto> createState() => _CampoTextoState();
}

class _CampoTextoState extends State<CampoTexto> {
  bool _oculto = true;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;
    final colorEtiqueta = tema.brightness == Brightness.light
        ? Colores.textoSecundario
        : esquema.onSurfaceVariant;
    final mostrarValido = widget.valido && widget.error == null;
    final bordeValido = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Medidas.radioCampo),
      borderSide: BorderSide(color: esquema.primary, width: 2),
    );

    Widget? sufijo;
    if (widget.esContrasena) {
      sufijo = _BotonVer(
        oculto: _oculto,
        alTocar: () => setState(() => _oculto = !_oculto),
      );
    } else if (mostrarValido) {
      sufijo = Icon(Symbols.check_circle, size: 24, color: esquema.primary);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.etiqueta,
          style: Tipografia.cuerpoChico.copyWith(
            fontWeight: FontWeight.w700,
            color: colorEtiqueta,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: widget.valorInicial,
          onChanged: widget.alCambiar,
          onFieldSubmitted: widget.alEnviar,
          obscureText: widget.esContrasena && _oculto,
          enableSuggestions: !widget.esContrasena,
          autocorrect: !widget.esContrasena,
          keyboardType: widget.teclado,
          textInputAction: widget.accionTeclado,
          autofillHints: widget.autocompletar,
          inputFormatters: widget.formatos,
          style: Tipografia.cuerpoGrande.copyWith(color: esquema.onSurface),
          decoration: InputDecoration(
            // El prefijo fijo ("+502") se ve siempre, no solo al escribir.
            prefixIcon: widget.prefijo != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 16, right: 10),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        widget.prefijo!,
                        style: Tipografia.cuerpoGrande.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colores.textoTenue,
                        ),
                      ),
                    ),
                  )
                : widget.icono == null
                ? null
                : Icon(widget.icono, size: 22),
            prefixIconConstraints: widget.prefijo != null
                ? const BoxConstraints(minHeight: Medidas.minimoTactil)
                : null,
            suffixIcon: sufijo,
            errorText: widget.error,
            errorMaxLines: 3,
            enabledBorder: mostrarValido ? bordeValido : null,
            focusedBorder: mostrarValido ? bordeValido : null,
          ),
        ),
        if (widget.ayuda != null && widget.error == null) ...[
          const SizedBox(height: 6),
          Text(
            widget.ayuda!,
            style: Tipografia.cuerpoChico.copyWith(
              color: esquema.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _BotonVer extends StatelessWidget {
  const _BotonVer({required this.oculto, required this.alTocar});

  final bool oculto;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.light
        ? Colores.primarioOscuro
        : Colores.primarioTemaOscuro;
    final palabra = oculto ? Textos.ver : Textos.ocultar;
    return Semantics(
      button: true,
      label: palabra,
      excludeSemantics: true,
      child: InkWell(
        onTap: alTocar,
        // Fuera del orden de foco: "Siguiente" en el teclado debe pasar al
        // próximo campo, no a este botón.
        canRequestFocus: false,
        borderRadius: BorderRadius.circular(Medidas.radioCampo),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: Medidas.minimoTactil,
            minHeight: Medidas.minimoTactil,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  oculto ? Symbols.visibility : Symbols.visibility_off,
                  size: 22,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  palabra,
                  style: Tipografia.etiquetaChica.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

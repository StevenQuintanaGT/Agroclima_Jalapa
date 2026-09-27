import 'package:flutter/material.dart';

import 'colores.dart';
import 'colores_semaforo.dart';
import 'medidas.dart';
import 'tipografia.dart';

/// Temas claro (por defecto, se lee bajo el sol) y oscuro (consultas de
/// madrugada). Material 3 adaptado a usuarios rurales (docs/DISENO_UI.md §1).
class TemaApp {
  TemaApp._();

  static ThemeData get claro => _construir(
    brillo: Brightness.light,
    esquema: const ColorScheme(
      brightness: Brightness.light,
      primary: Colores.primario,
      onPrimary: Colors.white,
      primaryContainer: Colores.contenedor,
      onPrimaryContainer: Colores.sobreContenedor,
      secondary: Colores.acentoCielo,
      onSecondary: Colors.white,
      tertiary: Colores.primarioOscuro,
      onTertiary: Colors.white,
      error: Colores.peligroBorde,
      onError: Colors.white,
      errorContainer: Colores.peligroFondo,
      onErrorContainer: Colores.peligroTexto,
      surface: Colores.superficie,
      onSurface: Colores.texto,
      onSurfaceVariant: Colores.textoSecundario,
      surfaceContainerLowest: Colores.superficie,
      surfaceContainerLow: Colores.fondo,
      surfaceContainer: Colores.fondo,
      surfaceContainerHigh: Colores.divisor,
      surfaceContainerHighest: Colores.esqueleto,
      outline: Colores.bordeFuerte,
      outlineVariant: Colores.borde,
    ),
    fondo: Colores.fondo,
    barraSuperior: Colores.primarioOscuro,
    enlace: Colores.primarioOscuro,
    textoTenue: Colores.textoTenue,
    semaforo: ColoresSemaforo.claro,
  );

  static ThemeData get oscuro => _construir(
    brillo: Brightness.dark,
    esquema: const ColorScheme(
      brightness: Brightness.dark,
      primary: Colores.primarioTemaOscuro,
      onPrimary: Colores.sobreContenedor,
      primaryContainer: Colores.contenedorTemaOscuro,
      onPrimaryContainer: Colores.primarioTemaOscuro,
      secondary: Colores.acentoCieloTemaOscuro,
      onSecondary: Colores.fondoOscuro,
      tertiary: Colores.primarioTemaOscuro,
      onTertiary: Colores.sobreContenedor,
      error: Colores.peligroTextoOscuro,
      onError: Colores.fondoOscuro,
      errorContainer: Colores.peligroFondoOscuro,
      onErrorContainer: Colores.peligroTextoOscuro,
      surface: Colores.superficieOscura,
      onSurface: Colores.textoOscuro,
      onSurfaceVariant: Colores.textoSecundarioOscuro,
      surfaceContainerLowest: Colores.fondoOscuro,
      surfaceContainerLow: Colores.fondoOscuro,
      surfaceContainer: Colores.superficieOscura,
      surfaceContainerHigh: Colores.bordeOscuro,
      surfaceContainerHighest: Colores.bordeOscuro,
      outline: Colores.textoTenueOscuro,
      outlineVariant: Colores.bordeOscuro,
    ),
    fondo: Colores.fondoOscuro,
    barraSuperior: Colores.superficieOscura,
    enlace: Colores.primarioTemaOscuro,
    textoTenue: Colores.textoTenueOscuro,
    semaforo: ColoresSemaforo.oscuro,
  );

  static ThemeData _construir({
    required Brightness brillo,
    required ColorScheme esquema,
    required Color fondo,
    required Color barraSuperior,
    required Color enlace,
    required Color textoTenue,
    required ColoresSemaforo semaforo,
  }) {
    final textos = TextTheme(
      displayLarge: Tipografia.datoDestacado,
      displayMedium: Tipografia.datoGrande,
      headlineMedium: Tipografia.titular,
      headlineSmall: Tipografia.titulo,
      titleLarge: Tipografia.subtitulo,
      titleMedium: Tipografia.cuerpoGrande.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: Tipografia.cuerpoGrande,
      bodyMedium: Tipografia.cuerpo,
      bodySmall: Tipografia.cuerpoChico,
      labelLarge: Tipografia.boton,
      labelMedium: Tipografia.etiqueta,
      labelSmall: Tipografia.etiquetaChica,
    ).apply(bodyColor: esquema.onSurface, displayColor: esquema.onSurface);

    final bordeCampo = OutlineInputBorder(
      borderRadius: BorderRadius.circular(Medidas.radioCampo),
      borderSide: BorderSide(color: esquema.outline, width: 2),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brillo,
      colorScheme: esquema,
      fontFamily: Tipografia.familia,
      textTheme: textos,
      scaffoldBackgroundColor: fondo,
      extensions: [semaforo],
      appBarTheme: AppBarTheme(
        backgroundColor: barraSuperior,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: Tipografia.subtitulo.copyWith(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white, size: 26),
      ),
      cardTheme: CardThemeData(
        color: esquema.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Medidas.radioTarjeta),
          side: BorderSide(color: esquema.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: esquema.surfaceContainerHigh,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(Medidas.alturaBotonPrincipal),
          textStyle: Tipografia.boton,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Medidas.radioBoton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(Medidas.alturaBotonSecundario),
          // Secundario neutro ("Ahora no", "Ver datos guardados"); la variante
          // verde la aplica BotonSecundario(destacado: true).
          foregroundColor: esquema.onSurfaceVariant,
          backgroundColor: esquema.surface,
          textStyle: Tipografia.boton,
          side: BorderSide(color: esquema.outline, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Medidas.radioBoton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: enlace,
          minimumSize: const Size(Medidas.minimoTactil, Medidas.minimoTactil),
          textStyle: Tipografia.cuerpo.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surface,
        constraints: const BoxConstraints(minHeight: Medidas.alturaCampo),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Medidas.espacioS,
          vertical: Medidas.espacioS,
        ),
        border: bordeCampo,
        enabledBorder: bordeCampo,
        focusedBorder: bordeCampo.copyWith(
          borderSide: BorderSide(color: esquema.primary, width: 2),
        ),
        errorBorder: bordeCampo.copyWith(
          borderSide: BorderSide(color: esquema.error, width: 2),
        ),
        focusedErrorBorder: bordeCampo.copyWith(
          borderSide: BorderSide(color: esquema.error, width: 2),
        ),
        hintStyle: Tipografia.cuerpoGrande.copyWith(color: textoTenue),
        errorStyle: Tipografia.cuerpoChico.copyWith(color: esquema.error),
        prefixIconColor: textoTenue,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: esquema.surface,
        selectedColor: esquema.primary,
        labelStyle: Tipografia.cuerpo.copyWith(fontWeight: FontWeight.w500),
        secondaryLabelStyle: Tipografia.cuerpo.copyWith(
          fontWeight: FontWeight.w700,
          color: esquema.onPrimary,
        ),
        side: BorderSide(color: esquema.outline, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Medidas.radioPildora),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colores.bannerSinConexion,
        contentTextStyle: Tipografia.cuerpo.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

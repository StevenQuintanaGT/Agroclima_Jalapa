import 'package:flutter/painting.dart';

/// Tokens de color (Tabla 71 y handoff de diseño, docs/diseno/).
/// Las pantallas usan estos nombres, nunca hexadecimales sueltos.
class Colores {
  Colores._();

  // ---------- Tema claro ----------
  static const Color primario = Color(0xFF2E7D32);
  static const Color primarioOscuro = Color(0xFF1B5E20);
  static const Color contenedor = Color(0xFFC8E6C9);
  static const Color contenedorClaro = Color(0xFFE8F5E9);
  static const Color sobreContenedor = Color(0xFF14351A);
  static const Color acentoCielo = Color(0xFF0277BD);
  static const Color acentoCieloOscuro = Color(0xFF01426A);

  static const Color fondo = Color(0xFFF7F6F2);
  static const Color superficie = Color(0xFFFFFFFF);
  static const Color borde = Color(0xFFE2E0D8);
  static const Color bordeFuerte = Color(0xFFB9B7AE);
  static const Color divisor = Color(0xFFEDEBE4);
  static const Color bordeBarraInferior = Color(0xFFDCDAD3);

  static const Color texto = Color(0xFF1A1C19);
  static const Color textoSecundario = Color(0xFF3D4139);
  static const Color textoTerciario = Color(0xFF4A4E47);
  static const Color textoTenue = Color(0xFF6B6F68);
  static const Color navegacionInactiva = Color(0xFF5B5F58);
  static const Color deshabilitado = Color(0xFF9B9F98);
  static const Color indicadorInactivo = Color(0xFFC9C7BF);

  static const Color esqueleto = Color(0xFFE4E2DA);
  static const Color sol = Color(0xFFF2A007);
  static const Color bannerSinConexion = Color(0xFF3D4139);
  static const Color fondoDatoGuardado = Color(0xFFEFEDE6);

  // ---------- Semáforo (Tabla 72) ----------
  // Color de borde/franja, fondo, texto e ícono por nivel. PRECAUCIÓN no usa
  // #B26A00 para texto (3.84:1, DECISIONES D-04): texto #4A2A00 e ícono #8A4B00.
  static const Color normalBorde = Color(0xFF2E7D32);
  static const Color normalFondo = Color(0xFFE8F5E9);
  static const Color normalTexto = Color(0xFF14351A);
  static const Color normalIcono = Color(0xFF2E7D32);

  static const Color precaucionBorde = Color(0xFFB26A00);
  static const Color precaucionFondo = Color(0xFFFFF3D6);
  static const Color precaucionTexto = Color(0xFF4A2A00);
  static const Color precaucionIcono = Color(0xFF8A4B00);

  static const Color peligroBorde = Color(0xFFB3261E);
  static const Color peligroFondo = Color(0xFFFDE7E7);
  static const Color peligroTexto = Color(0xFF410E0B);
  static const Color peligroIcono = Color(0xFF8C1D18);

  // ---------- Tema oscuro ----------
  static const Color fondoOscuro = Color(0xFF10130F);
  static const Color superficieOscura = Color(0xFF1E231C);
  static const Color bordeOscuro = Color(0xFF2E342B);
  static const Color textoOscuro = Color(0xFFE6E9E2);
  static const Color textoSecundarioOscuro = Color(0xFFC3C8BE);
  static const Color textoTenueOscuro = Color(0xFFA8ADA3);
  static const Color primarioTemaOscuro = Color(0xFFA5D6A7);
  static const Color contenedorTemaOscuro = Color(0xFF14301A);
  static const Color acentoCieloTemaOscuro = Color(0xFF8FD0F5);
  static const Color solTemaOscuro = Color(0xFFF6C453);

  static const Color normalFondoOscuro = Color(0xFF14301A);
  static const Color normalTextoOscuro = Color(0xFFA5D6A7);
  static const Color precaucionFondoOscuro = Color(0xFF3A2A08);
  static const Color precaucionTextoOscuro = Color(0xFFF6C453);
  static const Color peligroFondoOscuro = Color(0xFF4A1512);
  static const Color peligroTextoOscuro = Color(0xFFF2B8B5);
  static const Color peligroBordeOscuro = Color(0xFFFF5449);
}

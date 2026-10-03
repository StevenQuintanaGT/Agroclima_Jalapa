import 'dart:io';

import 'package:agroclima_jalapa/servicios/validacion_geografica.dart';

/// Límites reales de los 7 municipios, leídos del archivo de la app.
ValidacionGeografica limitesReales() => ValidacionGeografica.desdeGeoJson(
  File(ValidacionGeografica.rutaLimites).readAsStringSync(),
);

// Puntos conocidos (cabeceras municipales aproximadas).
const cabeceraJalapa = (lat: 14.6339, lon: -89.9889);
const cabeceraMonjas = (lat: 14.5003, lon: -89.8722);
const ciudadGuatemala = (lat: 14.6349, lon: -90.5069);

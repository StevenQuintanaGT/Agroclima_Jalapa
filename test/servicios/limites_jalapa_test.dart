import 'dart:io';

import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/servicios/validacion_geografica.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Prueba con los límites reales (assets/geo/jalapa_municipios.geojson).
void main() {
  group('carga', pruebasCarga);

  final validacion = ValidacionGeografica.desdeGeoJson(
    File('assets/geo/jalapa_municipios.geojson').readAsStringSync(),
  );

  test('el archivo trae los 7 municipios', () {
    expect(validacion.municipios, Municipio.values.toSet());
  });

  test('cada cabecera municipal cae en su municipio', () {
    // Coordenadas aproximadas del centro de cada cabecera.
    final cabeceras = {
      Municipio.jalapa: (14.6339, -89.9889),
      Municipio.sanPedroPinula: (14.6633, -89.8461),
      Municipio.sanLuisJilotepeque: (14.6431, -89.7311),
      Municipio.sanManuelChaparron: (14.5172, -89.7633),
      Municipio.sanCarlosAlzatate: (14.4978, -90.0617),
      Municipio.monjas: (14.5003, -89.8722),
      Municipio.mataquescuintla: (14.5294, -90.1844),
    };
    for (final MapEntry(key: municipio, value: (lat, lon))
        in cabeceras.entries) {
      expect(
        validacion.municipioDe(lat, lon),
        municipio,
        reason: '${municipio.valor} ($lat, $lon)',
      );
    }
  });

  test('cabeceras de otros departamentos quedan fuera (VA-01)', () {
    final fuera = {
      'Ciudad de Guatemala': (14.6349, -90.5069),
      'Jutiapa': (14.2917, -89.8958),
      'Chiquimula': (14.7997, -89.5444),
      'Cuilapa': (14.2797, -90.2989),
    };
    for (final MapEntry(key: lugar, value: (lat, lon)) in fuera.entries) {
      expect(validacion.municipioDe(lat, lon), isNull, reason: lugar);
    }
  });
}

void pruebasCarga() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('la app carga los límites desde sus assets', () async {
    final validacion = await ValidacionGeografica.cargar(rootBundle);
    expect(validacion.municipioDe(14.6339, -89.9889), Municipio.jalapa);
  });
}

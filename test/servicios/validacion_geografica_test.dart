import 'dart:convert';

import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/servicios/celda_clima.dart';
import 'package:agroclima_jalapa/servicios/validacion_geografica.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cuadrado [lon1, lon2] × [lat1, lat2] como anillo GeoJSON cerrado.
List<List<double>> _cuadro(
  double lon1,
  double lat1,
  double lon2,
  double lat2,
) => [
  [lon1, lat1],
  [lon2, lat1],
  [lon2, lat2],
  [lon1, lat2],
  [lon1, lat1],
];

String _geoJson(List<Map<String, dynamic>> entidades) =>
    jsonEncode({'type': 'FeatureCollection', 'features': entidades});

Map<String, dynamic> _entidad(
  String municipio,
  Map<String, dynamic> geometria,
) => {
  'type': 'Feature',
  'properties': {'municipio': municipio},
  'geometry': geometria,
};

void main() {
  // Límites de juguete (no son los reales): dos municipios vecinos, uno con
  // un hueco y otro de dos partes.
  final validacion = ValidacionGeografica.desdeGeoJson(
    _geoJson([
      _entidad('jalapa', {
        'type': 'Polygon',
        'coordinates': [
          _cuadro(-90.0, 14.5, -89.9, 14.7),
          _cuadro(-89.97, 14.58, -89.93, 14.62), // hueco
        ],
      }),
      _entidad('monjas', {
        'type': 'MultiPolygon',
        'coordinates': [
          [_cuadro(-89.9, 14.5, -89.8, 14.6)],
          [_cuadro(-89.7, 14.5, -89.6, 14.6)],
        ],
      }),
      _entidad('otroDepartamento', {
        'type': 'Polygon',
        'coordinates': [_cuadro(-91, 14, -90.5, 14.5)],
      }),
    ]),
  );

  group('ValidacionGeografica.municipioDe', () {
    test('punto dentro de un polígono simple', () {
      expect(validacion.municipioDe(14.65, -89.95), Municipio.jalapa);
    });

    test('punto en el hueco no pertenece al municipio', () {
      expect(validacion.municipioDe(14.60, -89.95), isNull);
    });

    test('cada parte de un MultiPolygon cuenta', () {
      expect(validacion.municipioDe(14.55, -89.85), Municipio.monjas);
      expect(validacion.municipioDe(14.55, -89.65), Municipio.monjas);
    });

    test('entre las dos partes no hay municipio', () {
      expect(validacion.municipioDe(14.55, -89.75), isNull);
    });

    test('fuera de Jalapa devuelve null (VA-01)', () {
      expect(
        validacion.municipioDe(14.63, -90.51),
        isNull,
      ); // Ciudad de Guatemala
      expect(validacion.estaEnJalapa(15.0, -89.95), isFalse);
    });

    test('se ignoran entidades que no son municipios de Jalapa', () {
      expect(validacion.municipioDe(14.2, -90.7), isNull);
      expect(validacion.municipios, {Municipio.jalapa, Municipio.monjas});
    });
  });

  test('geometría desconocida es un error claro', () {
    expect(
      () => ValidacionGeografica.desdeGeoJson(
        _geoJson([
          _entidad('jalapa', {
            'type': 'Point',
            'coordinates': [-89.9, 14.6],
          }),
        ]),
      ),
      throwsFormatException,
    );
  });

  group('CeldaClima (D-07)', () {
    test('redondea a 0.05° con 2 decimales', () {
      expect(CeldaClima.calcular(14.6342, -89.9871), '14.65_-90.00');
      expect(CeldaClima.calcular(14.6249, -89.9524), '14.60_-89.95');
    });

    test('parcelas cercanas comparten celda', () {
      expect(
        CeldaClima.calcular(14.6301, -89.9802),
        CeldaClima.calcular(14.6399, -89.9899),
      );
    });

    test('el centro es la coordenada de la celda', () {
      final centro = CeldaClima.centro('14.65_-89.95');
      expect(centro.lat, 14.65);
      expect(centro.lon, -89.95);
    });

    test('Municipio usa los valores de Firestore', () {
      expect(Municipio.values.map((m) => m.valor), [
        'jalapa',
        'sanPedroPinula',
        'sanLuisJilotepeque',
        'sanManuelChaparron',
        'sanCarlosAlzatate',
        'monjas',
        'mataquescuintla',
      ]);
    });
  });
}

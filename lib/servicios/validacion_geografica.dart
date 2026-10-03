import 'dart:convert';

import 'package:flutter/services.dart';

import '../modelos/enums.dart';

/// Un anillo de un polígono: lista de puntos (longitud, latitud), como en
/// GeoJSON.
typedef Anillo = List<({double lon, double lat})>;

/// Polígono con su contorno exterior y posibles huecos.
class Poligono {
  const Poligono({required this.exterior, this.huecos = const []});

  final Anillo exterior;
  final List<Anillo> huecos;

  /// ¿El punto está dentro del contorno y fuera de todos los huecos?
  bool contiene(double lat, double lon) {
    if (!_dentroDe(exterior, lat, lon)) return false;
    for (final hueco in huecos) {
      if (_dentroDe(hueco, lat, lon)) return false;
    }
    return true;
  }

  /// Punto en polígono por trazado de rayos (ray casting): se cuentan los
  /// cruces de un rayo horizontal hacia el este; impar = dentro.
  static bool _dentroDe(Anillo anillo, double lat, double lon) {
    var dentro = false;
    for (var i = 0, j = anillo.length - 1; i < anillo.length; j = i++) {
      final a = anillo[i];
      final b = anillo[j];
      final cruza =
          (a.lat > lat) != (b.lat > lat) &&
          lon < (b.lon - a.lon) * (lat - a.lat) / (b.lat - a.lat) + a.lon;
      if (cruza) dentro = !dentro;
    }
    return dentro;
  }
}

/// CO-05 · ¿En qué municipio de Jalapa cae un punto? (RN-02, VA-01).
/// Usa los límites de `assets/geo/jalapa_municipios.geojson`, sin servicios
/// externos (DECISIONES D-11): funciona sin señal y no gasta cuota.
class ValidacionGeografica {
  ValidacionGeografica(this._limites);

  /// Lee un GeoJSON `FeatureCollection` cuyas entidades traen la propiedad
  /// `municipio` con el valor de la enumeración (p. ej. `sanPedroPinula`) y
  /// geometría `Polygon` o `MultiPolygon`.
  factory ValidacionGeografica.desdeGeoJson(String geoJson) {
    final datos = jsonDecode(geoJson) as Map<String, dynamic>;
    final limites = <Municipio, List<Poligono>>{};
    for (final entidad in datos['features'] as List) {
      final propiedades = entidad['properties'] as Map<String, dynamic>;
      final municipio = Municipio.desdeValor(
        propiedades['municipio'] as String?,
      );
      if (municipio == null) continue;
      final geometria = entidad['geometry'] as Map<String, dynamic>;
      limites.putIfAbsent(municipio, () => []).addAll(_poligonosDe(geometria));
    }
    return ValidacionGeografica(limites);
  }

  /// Ruta del archivo de límites dentro de la app.
  static const String rutaLimites = 'assets/geo/jalapa_municipios.geojson';

  /// Carga los límites incluidos en la app (no necesita señal).
  static Future<ValidacionGeografica> cargar(AssetBundle assets) async =>
      ValidacionGeografica.desdeGeoJson(await assets.loadString(rutaLimites));

  final Map<Municipio, List<Poligono>> _limites;

  /// Municipios con límites cargados.
  Set<Municipio> get municipios => _limites.keys.toSet();

  /// Municipio que contiene el punto, o `null` si está fuera de Jalapa.
  Municipio? municipioDe(double lat, double lon) {
    for (final MapEntry(key: municipio, value: poligonos) in _limites.entries) {
      for (final poligono in poligonos) {
        if (poligono.contiene(lat, lon)) return municipio;
      }
    }
    return null;
  }

  bool estaEnJalapa(double lat, double lon) => municipioDe(lat, lon) != null;

  /// Centro aproximado (del rectángulo que lo encierra) de un municipio, o
  /// de todo el departamento si [municipio] es `null`. Sirve para centrar el
  /// mapa (HU-03: "carga centrado en el departamento de Jalapa").
  ({double lat, double lon}) centro([Municipio? municipio]) {
    final poligonos = municipio == null
        ? _limites.values.expand((p) => p)
        : _limites[municipio] ?? const <Poligono>[];
    var minLat = double.infinity, maxLat = -double.infinity;
    var minLon = double.infinity, maxLon = -double.infinity;
    for (final poligono in poligonos) {
      for (final punto in poligono.exterior) {
        if (punto.lat < minLat) minLat = punto.lat;
        if (punto.lat > maxLat) maxLat = punto.lat;
        if (punto.lon < minLon) minLon = punto.lon;
        if (punto.lon > maxLon) maxLon = punto.lon;
      }
    }
    if (minLat == double.infinity) return centroJalapa;
    return (lat: (minLat + maxLat) / 2, lon: (minLon + maxLon) / 2);
  }

  /// Cabecera de Jalapa: respaldo si no hay límites cargados.
  static const centroJalapa = (lat: 14.6339, lon: -89.9889);

  static List<Poligono> _poligonosDe(Map<String, dynamic> geometria) {
    final coordenadas = geometria['coordinates'] as List;
    return switch (geometria['type']) {
      'Polygon' => [_poligono(coordenadas)],
      'MultiPolygon' => [
        for (final partes in coordenadas) _poligono(partes as List),
      ],
      final otro => throw FormatException('Geometría no soportada: $otro'),
    };
  }

  static Poligono _poligono(List anillos) {
    final todos = [
      for (final anillo in anillos)
        [
          for (final punto in anillo as List)
            (
              lon: ((punto as List)[0] as num).toDouble(),
              lat: (punto[1] as num).toDouble(),
            ),
        ],
    ];
    return Poligono(exterior: todos.first, huecos: todos.skip(1).toList());
  }
}

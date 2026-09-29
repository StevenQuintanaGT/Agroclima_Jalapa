import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/preferencia_alerta.dart';
import 'package:agroclima_jalapa/modelos/usuario.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Usuario nuevo usa los defectos de la Tabla 64', () {
    const usuario = Usuario(uid: 'u1', nombre: 'Ana', correo: 'ana@c.com');
    expect(usuario.toMap(), {
      'uid': 'u1',
      'nombre': 'Ana',
      'telefono': '',
      'correo': 'ana@c.com',
      'unidadTemperatura': 'C',
      'unidadArea': 'manzana',
      'temaOscuro': false,
      'ahorroDatos': false,
      'tokensFcm': <String>[],
    });
  });

  test('Usuario ida y vuelta por Map', () {
    const original = Usuario(
      uid: 'u1',
      nombre: 'Ana',
      correo: 'ana@c.com',
      telefono: '+50255123456',
      unidadArea: 'hectarea',
      tokensFcm: ['t1'],
    );
    final copia = Usuario.fromMap(original.toMap());
    expect(copia.toMap(), original.toMap());
  });

  test('PreferenciaAlerta por defecto (Tabla 65)', () {
    final mapa = PreferenciaAlerta.porDefecto(TipoRiesgo.sequia).toMap();
    expect(mapa, {
      'tipoRiesgo': 'sequia',
      'activa': true,
      'nivelMinimo': 'preventiva',
      'silencioDesde': '22:00',
      'silencioHasta': '05:00',
    });
    expect(PreferenciaAlerta.fromMap(mapa).tipoRiesgo, TipoRiesgo.sequia);
  });

  test('TipoRiesgo usa los 6 valores de Firestore', () {
    expect(TipoRiesgo.values.map((t) => t.valor), [
      'lluviaIntensa',
      'vientoFuerte',
      'sequia',
      'temperaturaBaja',
      'temperaturaAlta',
      'humedadAlta',
    ]);
  });
}

import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/alerta.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/repositorios/alertas_repositorio.dart';
import 'package:agroclima_jalapa/repositorios/auth_repositorio.dart';
import 'package:agroclima_jalapa/servicios/alertas_servicio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../apoyo/alertas_de_prueba.dart';

class _RepositorioFalso extends Mock implements AlertasRepositorio {}

class _AuthFalso extends Mock implements AuthRepositorio {}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  List<String> ids(List<Alerta> lista) => lista.map((a) => a.alertaId).toList();

  group('activas y anteriores (HU-11)', () {
    final lista = [
      alertaDePrueba(id: 'ayer', dia: 4),
      alertaDePrueba(
        id: 'precaucion-hoy',
        nivel: NivelSeveridad.preventiva,
        dia: 5,
      ),
      alertaDePrueba(
        id: 'peligro-jueves',
        dia: 8,
        tipo: TipoRiesgo.vientoFuerte,
      ),
      alertaDePrueba(id: 'peligro-manana', dia: 6),
      alertaDePrueba(
        id: 'normal-hoy',
        nivel: NivelSeveridad.informativa,
        dia: 5,
        tipo: TipoRiesgo.sequia,
      ),
      alertaDePrueba(id: 'hace-dias', dia: 1, tipo: TipoRiesgo.vientoFuerte),
    ];

    test(
      'activas: hoy en adelante, PELIGRO primero y lo más cercano primero',
      () {
        expect(ids(AlertasServicio.activas(lista, ahoraDePrueba)), [
          'peligro-manana',
          'peligro-jueves',
          'precaucion-hoy',
          'normal-hoy',
        ]);
      },
    );

    test('anteriores: días pasados, lo más reciente primero', () {
      expect(ids(AlertasServicio.anteriores(lista, ahoraDePrueba)), [
        'ayer',
        'hace-dias',
      ]);
    });

    test(
      'a las 11 p.m. del lunes (martes en UTC) lo del lunes sigue activo',
      () {
        final noche = DateTime.utc(2026, 10, 6, 5);
        expect(
          ids(AlertasServicio.activas(lista, noche)),
          contains('precaucion-hoy'),
        );
      },
    );

    test('si el riesgo empeoró ese día, solo se ve la de nivel más alto', () {
      final dos = [
        alertaDePrueba(
          id: 'antes',
          nivel: NivelSeveridad.preventiva,
          leida: false,
        ),
        alertaDePrueba(
          id: 'despues',
          nivel: NivelSeveridad.critica,
          leida: true,
        ),
      ];
      expect(ids(AlertasServicio.activas(dos, ahoraDePrueba)), ['despues']);
      // La de nivel menor no cuenta como sin leer.
      expect(AlertasServicio.sinLeer(dos, ahoraDePrueba), 0);
    });

    test('sin leer: solo activas sin abrir', () {
      final varias = [
        alertaDePrueba(id: 'a', dia: 6),
        alertaDePrueba(id: 'b', dia: 7, leida: true),
        alertaDePrueba(id: 'c', dia: 4),
      ];
      expect(AlertasServicio.sinLeer(varias, ahoraDePrueba), 1);
    });
  });

  group('lecturas y cambios', () {
    late _RepositorioFalso repositorio;
    late _AuthFalso auth;
    late AlertasServicio servicio;

    setUp(() {
      repositorio = _RepositorioFalso();
      auth = _AuthFalso();
      servicio = AlertasServicio(repositorio: repositorio, auth: auth);
      when(() => repositorio.marcarLeida(any())).thenAnswer((_) async {});
      when(() => repositorio.marcarAtendida(any())).thenAnswer((_) async {});
    });

    test('sin sesión no hay alertas', () async {
      when(() => auth.uidActual).thenReturn(null);
      expect(await servicio.misAlertas().first, isEmpty);
    });

    test('con sesión, las del usuario', () async {
      when(() => auth.uidActual).thenReturn('ana');
      when(() => repositorio.delUsuario('ana'))
          .thenAnswer((_) => Stream.value([alertaDePrueba()]));
      expect(await servicio.misAlertas().first, hasLength(1));
    });

    test('marca leída y atendida solo una vez', () async {
      await servicio.marcarLeida(alertaDePrueba());
      await servicio.marcarLeida(alertaDePrueba(leida: true));
      await servicio.marcarAtendida(alertaDePrueba(atendida: true));
      verify(() => repositorio.marcarLeida('a1')).called(1);
      verifyNever(() => repositorio.marcarAtendida(any()));
    });
  });

  group('textos de la alerta', () {
    test('título: helada, frío y los demás', () {
      expect(Textos.tituloAlerta(alertaDePrueba()), 'Puede caer helada');
      expect(
        Textos.tituloAlerta(alertaDePrueba(esperado: 13, umbral: 15)),
        'Frío',
      );
      expect(
        Textos.tituloAlerta(
          alertaDePrueba(tipo: TipoRiesgo.vientoFuerte, umbral: 30),
        ),
        'Viento fuerte',
      );
    });

    test('cuándo: en lenguaje hablado', () {
      expect(
        Textos.cuandoAlerta(alertaDePrueba(), ahoraDePrueba),
        'Mañana en la madrugada',
      );
      expect(
        Textos.cuandoAlerta(
          alertaDePrueba(tipo: TipoRiesgo.vientoFuerte, dia: 5),
          ahoraDePrueba,
        ),
        'Hoy',
      );
      expect(
        Textos.cuandoAlerta(
          alertaDePrueba(
            tipo: TipoRiesgo.temperaturaAlta,
            dia: 8,
            diasConsecutivos: 3,
          ),
          ahoraDePrueba,
        ),
        'El jueves por la tarde · 3 días seguidos',
      );
      expect(
        Textos.cuandoAlerta(
          alertaDePrueba(tipo: TipoRiesgo.sequia, dia: 7),
          ahoraDePrueba,
        ),
        'A partir del miércoles',
      );
      expect(
        Textos.cuandoAlerta(
          alertaDePrueba(tipo: TipoRiesgo.vientoFuerte, dia: 2),
          ahoraDePrueba,
        ),
        'El viernes 2 de octubre',
      );
    });

    test('lo esperado frente a lo que aguanta el cultivo', () {
      final frio = alertaDePrueba(
        esperado: 13.4,
        umbral: 15,
        nivel: NivelSeveridad.preventiva,
      );
      expect(Textos.valorAlerta(frio.tipoRiesgo, frio.valorEsperado), '13 °C');
      expect(
        Textos.aguanta(frio.cultivo, frio.tipoRiesgo),
        'El café aguanta hasta',
      );
      expect(
        Textos.diferenciaAlerta(frio),
        'Va a estar 2 grados más frío de lo que aguanta su cultivo.',
      );

      final sequia = alertaDePrueba(
        tipo: TipoRiesgo.sequia,
        esperado: 7,
        umbral: 5,
        cultivo: Cultivo.maiz,
      );
      expect(Textos.seEspera(sequia.tipoRiesgo), 'Se esperan');
      expect(Textos.valorAlerta(sequia.tipoRiesgo, 7), '7 días');
      expect(
        Textos.aguanta(Cultivo.maiz, TipoRiesgo.sequia),
        'El maíz aguanta',
      );
      expect(
        Textos.diferenciaAlerta(sequia),
        'Van a ser 2 días más sin lluvia de lo que aguanta su cultivo.',
      );

      final viento = alertaDePrueba(
        tipo: TipoRiesgo.vientoFuerte,
        esperado: 30.2,
        umbral: 30,
        cultivo: null,
      );
      expect(Textos.aguanta(null, viento.tipoRiesgo), 'Lo seguro es hasta');
      expect(
        Textos.diferenciaAlerta(viento),
        'Va a llegar al límite de lo seguro.',
      );
    });

    test('parcela y cultivo, con la etapa en el detalle', () {
      expect(Textos.parcelaYCultivo('La Joya', Cultivo.cafe), 'La Joya · Café');
      expect(
        Textos.parcelaYCultivo('La Joya', Cultivo.cafe, Etapa.floracion),
        'La Joya · Café floreando',
      );
      expect(Textos.parcelaYCultivo('Potrero', null), 'Potrero');
    });

    test('compartir lleva el aviso de apoyo (RN-07)', () {
      final texto = Textos.textoCompartir(alertaDePrueba());
      expect(
        texto,
        startsWith(
          'PELIGRO: puede caer helada en La Joya. Mañana en la madrugada puede '
          'bajar a -1 °C.',
        ),
      );
      expect(texto, contains(Textos.avisoApoyo));
    });
  });

  test('una alerta que no se entiende no se muestra', () {
    final base = {
      'tipoRiesgo': 'temperaturaBaja',
      'nivel': 'critica',
      'valorEsperado': -1,
      'valorUmbral': 0,
    };
    expect(Alerta.fromMap('x', base, fechaEvento: eventoDe(6)), isNotNull);
    expect(
      Alerta.fromMap('x', {...base, 'nivel': 'rojo'}, fechaEvento: eventoDe(6)),
      isNull,
    );
    expect(
      Alerta.fromMap('x', {
        ...base,
        'tipoRiesgo': 'granizo',
      }, fechaEvento: eventoDe(6)),
      isNull,
    );
    expect(
      Alerta.fromMap('x', {
        ...base,
        'valorEsperado': null,
      }, fechaEvento: eventoDe(6)),
      isNull,
    );
  });
}

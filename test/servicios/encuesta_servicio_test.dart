import 'package:agroclima_jalapa/config/constantes.dart';
import 'package:agroclima_jalapa/modelos/encuesta.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/parcela.dart';
import 'package:agroclima_jalapa/modelos/respuestas_encuesta.dart';
import 'package:agroclima_jalapa/repositorios/auth_repositorio.dart';
import 'package:agroclima_jalapa/repositorios/encuestas_repositorio.dart';
import 'package:agroclima_jalapa/servicios/encuesta_servicio.dart';
import 'package:agroclima_jalapa/servicios/parcelas_servicio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _AuthFalso extends Mock implements AuthRepositorio {}

class _RepositorioFalso extends Mock implements EncuestasRepositorio {}

class _ParcelasFalsas extends Mock implements ParcelasServicio {}

Parcela _parcela(String nombre, Municipio m, Cultivo? c, DateTime? fecha) =>
    Parcela(
      parcelaId: nombre,
      usuarioId: 'ana',
      nombre: nombre,
      municipio: m,
      cultivo: c,
      latitud: 14.5,
      longitud: -89.87,
      celdaClima: '14.50_-89.85',
      fechaRegistro: fecha,
    );

const _completas = RespuestasEncuesta(
  p1: 'facil',
  p2: 'todo',
  p3: 'no',
  detalleAviso: 'no debe quedar',
  p4: 'algo',
  p5: 'si',
  detalleAccion: '  Tapé el almácigo  ',
  p6: 'no',
  p7: 'talVez',
  p8: '   ',
  consentimiento: false,
);

void main() {
  late _AuthFalso auth;
  late _RepositorioFalso repositorio;
  late _ParcelasFalsas parcelas;
  late EncuestaServicio servicio;

  setUpAll(() {
    registerFallbackValue(
      const Encuesta(uid: '', respuestas: RespuestasEncuesta(), versionApp: ''),
    );
  });

  setUp(() {
    auth = _AuthFalso();
    repositorio = _RepositorioFalso();
    parcelas = _ParcelasFalsas();
    when(() => auth.uidActual).thenReturn('ana');
    when(() => repositorio.guardar(any())).thenAnswer((_) async {});
    servicio = EncuestaServicio(
      auth: auth,
      repositorio: repositorio,
      parcelas: parcelas,
    );
  });

  Encuesta guardada() =>
      verify(() => repositorio.guardar(captureAny())).captured.single
          as Encuesta;

  test(
    'guarda con uid, versión y municipio y cultivo de la primera parcela',
    () async {
      when(() => parcelas.misParcelas()).thenAnswer(
        (_) => Stream.value([
          _parcela(
            'A nueva',
            Municipio.jalapa,
            Cultivo.frijol,
            DateTime(2026, 9),
          ),
          _parcela(
            'Z vieja',
            Municipio.monjas,
            Cultivo.cafe,
            DateTime(2026, 3),
          ),
        ]),
      );
      await servicio.enviar(_completas);
      final encuesta = guardada();
      expect(encuesta.uid, 'ana');
      expect(encuesta.versionApp, Constantes.versionApp);
      expect(encuesta.municipio, 'monjas');
      expect(encuesta.cultivo, 'cafe');
    },
  );

  test(
    'limpia los textos: detalle solo si dijo que sí, vacíos fuera',
    () async {
      when(() => parcelas.misParcelas())
          .thenAnswer((_) => Stream.value(const []));
      await servicio.enviar(_completas);
      final r = guardada().respuestas;
      expect(r.detalleAviso, isNull);
      expect(r.detalleAccion, 'Tapé el almácigo');
      expect(r.p8, isNull);
      expect(r.consentimiento, isFalse);
    },
  );

  test(
    'sin parcelas (o sin señal) se envía sin municipio ni cultivo',
    () async {
      when(() => parcelas.misParcelas())
          .thenAnswer((_) => Stream.error(Exception('sin señal')));
      await servicio.enviar(_completas);
      final encuesta = guardada();
      expect(encuesta.municipio, isNull);
      expect(encuesta.cultivo, isNull);
    },
  );

  test('incompleta o sin sesión no se guarda', () async {
    expect(
      () => servicio.enviar(const RespuestasEncuesta(p1: 'facil')),
      throwsStateError,
    );
    when(() => auth.uidActual).thenReturn(null);
    expect(() => servicio.enviar(_completas), throwsStateError);
    expect(await servicio.miEncuesta(), isNull);
    verifyNever(() => repositorio.guardar(any()));
  });
}

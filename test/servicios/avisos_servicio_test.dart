import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/parcela.dart';
import 'package:agroclima_jalapa/modelos/preferencia_alerta.dart';
import 'package:agroclima_jalapa/repositorios/firestore_umbrales_repositorio.dart';
import 'package:agroclima_jalapa/repositorios/firestore_usuario_repositorio.dart';
import 'package:agroclima_jalapa/servicios/avisos_servicio.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dart:convert';
import 'dart:io';

Parcela _parcela(Cultivo? cultivo, Etapa? etapa) => Parcela(
  parcelaId: '${cultivo?.valor}${etapa?.valor}',
  usuarioId: 'ana',
  nombre: 'P',
  municipio: Municipio.jalapa,
  latitud: 14.63,
  longitud: -89.99,
  celdaClima: '14.65_-90.00',
  cultivo: cultivo,
  etapa: etapa,
);

void main() {
  group('preferencias (Tabla 65)', () {
    test('completa las que faltan con los valores por defecto', () {
      final lista = AvisosServicio.completar([
        const PreferenciaAlerta(
          tipoRiesgo: TipoRiesgo.vientoFuerte,
          activa: false,
        ),
      ]);
      expect(lista.map((p) => p.tipoRiesgo), AvisosServicio.orden);
      expect(AvisosServicio.orden.toSet(), TipoRiesgo.values.toSet());
      expect(
        lista.where((p) => !p.activa).single.tipoRiesgo,
        TipoRiesgo.vientoFuerte,
      );
      expect(lista.first.nivelMinimo, NivelSeveridad.preventiva);
      expect(lista.first.silencioActivo, isTrue);
    });

    test('apagar un tipo no toca los demás', () {
      final lista = AvisosServicio.conActiva(
        AvisosServicio.completar(const []),
        TipoRiesgo.humedadAlta,
        false,
      );
      expect(lista.where((p) => !p.activa).map((p) => p.tipoRiesgo), [
        TipoRiesgo.humedadAlta,
      ]);
    });

    test('nivel mínimo y silencio se aplican a todos', () {
      var lista = AvisosServicio.conNivelMinimo(
        AvisosServicio.completar(const []),
        NivelSeveridad.critica,
      );
      expect(
        lista.every((p) => p.nivelMinimo == NivelSeveridad.critica),
        isTrue,
      );
      lista = AvisosServicio.conSilencio(lista, false);
      expect(
        lista.every((p) => !p.silencioActivo && p.silencioDesde == ''),
        isTrue,
      );
      lista = AvisosServicio.conSilencio(lista, true);
      expect(
        lista.every(
          (p) => p.silencioDesde == '22:00' && p.silencioHasta == '05:00',
        ),
        isTrue,
      );
    });

    test(
      'se guardan y se leen de Firestore (las vacías siguen vacías)',
      () async {
        final db = FakeFirebaseFirestore();
        final repo = FirestoreUsuarioRepositorio(db: db);
        final lista = AvisosServicio.conSilencio(
          AvisosServicio.conActiva(
            AvisosServicio.completar(const []),
            TipoRiesgo.sequia,
            false,
          ),
          false,
        );
        await repo.guardarPreferencias('ana', lista);
        final doc = await db.doc('usuarios/ana/preferencias/sequia').get();
        expect(doc.data(), {
          'tipoRiesgo': 'sequia',
          'activa': false,
          'nivelMinimo': 'preventiva',
          'silencioDesde': '',
          'silencioHasta': '',
        });
        final leidas = await repo.observarPreferencias('ana').first;
        expect(leidas, hasLength(6));
        expect(
          leidas.firstWhere((p) => p.tipoRiesgo == TipoRiesgo.sequia).activa,
          isFalse,
        );
        expect(leidas.first.silencioActivo, isFalse);
      },
    );
  });

  group('lo que aguanta el cultivo (D-20)', () {
    late List<dynamic> catalogo;

    setUpAll(() async {
      final db = FakeFirebaseFirestore();
      final semilla = jsonDecode(
        File('functions/seed/umbrales.json').readAsStringSync(),
      ) as List<dynamic>;
      for (final u in semilla.cast<Map<String, dynamic>>()) {
        await db.doc('umbrales/${u['umbralId']}').set(u);
      }
      catalogo = await FirestoreUmbralesRepositorio(db: db).vigentes();
    });

    Map<TipoRiesgo, double> valores(Cultivo? cultivo, List<Parcela> parcelas) =>
        {
          for (final u in AvisosServicio.limitesPorCultivo(
            catalogo.cast(),
            parcelas,
          )[cultivo]!)
            u.tipoRiesgo: u.valor,
        };

    test(
      'café: avisa desde 15 °C de frío, 30 °C de calor y 85 % de humedad',
      () {
        expect(
          valores(Cultivo.cafe, [_parcela(Cultivo.cafe, Etapa.floracion)]),
          {
            TipoRiesgo.lluviaIntensa: 15,
            TipoRiesgo.vientoFuerte: 15,
            TipoRiesgo.sequia: 5,
            TipoRiesgo.temperaturaBaja: 15,
            TipoRiesgo.temperaturaAlta: 30,
            TipoRiesgo.humedadAlta: 85,
          },
        );
      },
    );

    test('sin cultivo: solo los generales; un grupo por cultivo', () {
      final parcelas = [
        _parcela(null, null),
        _parcela(Cultivo.maiz, Etapa.desarrolloVegetativo),
      ];
      final limites = AvisosServicio.limitesPorCultivo(
        catalogo.cast(),
        parcelas,
      );
      expect(limites.keys, unorderedEquals([null, Cultivo.maiz]));
      expect(valores(null, parcelas), {
        TipoRiesgo.lluviaIntensa: 15,
        TipoRiesgo.vientoFuerte: 15,
        TipoRiesgo.sequia: 5,
        TipoRiesgo.temperaturaBaja: 0,
      });
      expect(valores(Cultivo.maiz, parcelas)[TipoRiesgo.temperaturaAlta], 35);
    });
  });

  test('horario de silencio en palabras', () {
    expect(
      Textos.horarioSilencio('22:00', '05:00'),
      'De 10:00 p.m. a 5:00 a.m.',
    );
    expect(
      Textos.horarioSilencio('12:30', '00:00'),
      'De 12:30 p.m. a 12:00 a.m.',
    );
  });
}

import 'dart:convert';

import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/parcela.dart';
import 'package:agroclima_jalapa/modelos/registro_dia.dart';
import 'package:agroclima_jalapa/servicios/exportar_reporte.dart';
import 'package:agroclima_jalapa/servicios/reportes_servicio.dart';
import 'package:excel/excel.dart' as xl;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../apoyo/alertas_de_prueba.dart';

const _parcela = Parcela(
  parcelaId: 'guayabal',
  usuarioId: 'ana',
  nombre: 'El Guayabal',
  municipio: Municipio.jalapa,
  latitud: 14.63,
  longitud: -89.99,
  celdaClima: '14.65_-90.00',
  cultivo: Cultivo.maiz,
);

/// Semana del martes 29 de septiembre al lunes 5 de octubre de 2026 (hoy).
const _registros = [
  RegistroDia(
    fecha: '20260929',
    temperatura: 20,
    temperaturaMinima: 15,
    temperaturaMaxima: 26,
    precipitacion: 0,
  ),
  RegistroDia(
    fecha: '20261001',
    temperatura: 19,
    temperaturaMinima: 13,
    temperaturaMaxima: 25,
    precipitacion: 12.4,
  ),
  RegistroDia(
    fecha: '20261002',
    temperatura: 21,
    temperaturaMinima: 16,
    temperaturaMaxima: 29,
    precipitacion: 34.6,
  ),
  RegistroDia(fecha: '20261004', temperatura: 18, precipitacion: 0.4),
];

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  final periodo = Periodo.ultimosDias(7, ahoraDePrueba);
  final alertas = [
    alertaDePrueba(
      id: 'a',
      parcelaId: 'guayabal',
      dia: 2,
      tipo: TipoRiesgo.lluviaIntensa,
      nivel: NivelSeveridad.preventiva,
      esperado: 18,
      umbral: 15,
    ),
    // Empeoró el mismo día: cuenta una vez, como PELIGRO.
    alertaDePrueba(
      id: 'b',
      parcelaId: 'guayabal',
      dia: 2,
      tipo: TipoRiesgo.lluviaIntensa,
      nivel: NivelSeveridad.critica,
      esperado: 34,
      umbral: 30,
      atendida: true,
    ),
    alertaDePrueba(id: 'c', parcelaId: 'otra', dia: 2),
    alertaDePrueba(id: 'd', parcelaId: 'guayabal', dia: 6),
  ];
  final resumen = ReportesServicio.calcular(
    parcela: _parcela,
    periodo: periodo,
    registros: _registros,
    alertas: alertas,
  );

  group('período', () {
    test('los últimos 7 días terminan hoy en Guatemala', () {
      expect(periodo.idDesde, '20260929');
      expect(periodo.idHasta, '20261005');
      expect(periodo.cantidadDias, 7);
      // A las 11 p.m. del lunes (martes en UTC) sigue siendo lunes.
      expect(
        Periodo.ultimosDias(7, DateTime.utc(2026, 10, 6, 5)).idHasta,
        '20261005',
      );
    });

    test('en palabras', () {
      expect(
        Textos.periodoEnPalabras(periodo.desde, periodo.hasta),
        'Del 29 de septiembre al 5 de octubre de 2026',
      );
      expect(
        Textos.periodoEnPalabras(
          DateTime.utc(2026, 10, 4),
          DateTime.utc(2026, 10, 10),
        ),
        'Del 4 al 10 de octubre de 2026',
      );
    });
  });

  group('resumen (4 indicadores)', () {
    test('un registro por día; los que faltan van vacíos', () {
      expect(resumen.dias.map((d) => d.fecha), periodo.ids);
      expect(resumen.dias[1].temperatura, isNull);
      expect(resumen.hayDatos, isTrue);
    });

    test('días con lluvia (≥ 1 mm), lluvia total y noche más fría', () {
      expect(resumen.diasConLluvia, 2);
      expect(resumen.lluviaTotal, closeTo(47.4, 0.001));
      expect(resumen.nocheMasFria?.fecha, '20261001');
      expect(ResumenPeriodo.minimaDe(resumen.nocheMasFria!), 13);
      expect(resumen.diaMasCaliente?.fecha, '20261002');
      expect(resumen.diaMasLluvioso?.fecha, '20261002');
    });

    test('avisos: solo de la parcela y del período, sin repetir', () {
      expect(resumen.alertas.map((a) => a.alertaId), ['b']);
      expect(resumen.avisosPeligro, 1);
      expect(resumen.nivelDelDia('20261002'), NivelSeveridad.critica);
      expect(resumen.nivelDelDia('20261001'), isNull);
    });

    test('una temperatura suelta no cuenta como la noche más fría si hay mínimas del ciclo', () {
      final conSuelta = ReportesServicio.calcular(
        parcela: _parcela,
        periodo: periodo,
        registros: [
          ..._registros,
          const RegistroDia(fecha: '20261005', temperatura: 9),
        ],
        alertas: const [],
      );
      expect(conSuelta.nocheMasFria?.fecha, '20261001');
      // Sin ninguna mínima del ciclo, se usa la registrada.
      final soloRegistradas = ReportesServicio.calcular(
        parcela: _parcela,
        periodo: periodo,
        registros: const [
          RegistroDia(fecha: '20261003', temperatura: 17),
          RegistroDia(fecha: '20261005', temperatura: 9),
        ],
        alertas: const [],
      );
      expect(soloRegistradas.nocheMasFria?.fecha, '20261005');
    });

    test('sin datos ni avisos', () {
      final vacio = ReportesServicio.calcular(
        parcela: _parcela,
        periodo: periodo,
        registros: const [],
        alertas: const [],
      );
      expect(vacio.hayDatos, isFalse);
      expect(vacio.nocheMasFria, isNull);
      expect(vacio.avisosPeligro, 0);
      expect(Textos.fraseLluvia(null, null), 'No llovió en estos días.');
    });

    test('frases de las gráficas', () {
      expect(
        Textos.fraseTemperatura(
          DateTime.utc(2026, 10, 1),
          13,
          DateTime.utc(2026, 10, 2),
          29,
        ),
        'La noche más fría fue el jueves 1, con 13 °C. Lo más caliente fue el viernes 2, con 29 °C.',
      );
      expect(
        Textos.fraseLluvia(DateTime.utc(2026, 10, 2), 34.6),
        'Llovió más el viernes 2: 35 mm.',
      );
    });
  });

  test('nombre del archivo sin tildes ni espacios', () {
    expect(
      ReportesServicio.nombreArchivo(resumen),
      'agroclima_el-guayabal_20260929_20261005',
    );
  });

  group('archivos (D-51)', () {
    test(
      'CSV: BOM, encabezados sin tildes, punto decimal y vacíos sin dato',
      () {
        final bytes = ExportarReporte.csv(resumen);
        expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
        final lineas = utf8.decode(bytes.sublist(3)).trim().split('\r\n');
        expect(
          lineas.first,
          'fecha,temperatura_minima,temperatura_maxima,temperatura_registrada,lluvia_mm,aviso',
        );
        expect(lineas, hasLength(8));
        expect(lineas[1], '2026-09-29,15.0,26.0,20.0,0.0,');
        expect(lineas[2], '2026-09-30,,,,,');
        expect(lineas[4], '2026-10-02,16.0,29.0,21.0,34.6,PELIGRO');
      },
    );

    test('Excel: hojas Resumen, Días y Avisos con números como números', () {
      final libro = xl.Excel.decodeBytes(ExportarReporte.excel(resumen));
      expect(
        libro.tables.keys,
        containsAll([Textos.hojaResumen, Textos.hojaDias, Textos.hojaAvisos]),
      );
      final dias = libro.tables[Textos.hojaDias]!;
      expect(dias.maxRows, 8);
      expect(dias.rows[4][4]?.value, isA<xl.DoubleCellValue>());
      expect((dias.rows[4][4]!.value! as xl.DoubleCellValue).value, 34.6);
      final avisos = libro.tables[Textos.hojaAvisos]!;
      expect(avisos.maxRows, 2);
      expect(avisos.rows[1][5]?.value.toString(), Textos.si);
    });

    test('PDF: es un PDF de verdad', () async {
      final bytes = await ExportarReporte.pdf(resumen, ahora: ahoraDePrueba);
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(bytes.length, greaterThan(2000));
    });
  });
}

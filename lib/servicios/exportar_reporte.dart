import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart' as xl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../config/textos.dart';
import '../modelos/alerta.dart';
import '../modelos/registro_dia.dart';
import 'reportes_servicio.dart';

/// Formatos del reporte (D-51).
enum FormatoReporte {
  pdf('pdf', 'application/pdf'),
  excel(
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ),
  csv('csv', 'text/csv');

  const FormatoReporte(this.extension, this.tipoMime);

  final String extension;
  final String tipoMime;
}

/// Arma los archivos del reporte en el teléfono, con los datos ya guardados:
/// sin servidor, sin señal y sin costo (plans/05, D-51).
class ExportarReporte {
  ExportarReporte._();

  static Future<Uint8List> archivo(
    ResumenPeriodo r,
    FormatoReporte formato, {
    required DateTime ahora,
  }) async => switch (formato) {
    FormatoReporte.pdf => pdf(r, ahora: ahora),
    FormatoReporte.excel => Uint8List.fromList(excel(r)),
    FormatoReporte.csv => csv(r),
  };

  static String? _numero(double? v) => v?.toStringAsFixed(1);
  static String _fechaIso(String id) =>
      '${id.substring(0, 4)}-${id.substring(4, 6)}-${id.substring(6, 8)}';
  static String _cultivo(ResumenPeriodo r) => r.parcela.cultivo == null
      ? Textos.sinCultivoReporte
      : Textos.cultivo(r.parcela.cultivo!);

  // ---------------------------------------------------------------- CSV

  /// La tabla de días, una fila por día: UTF-8 con BOM (para que Excel lea las
  /// tildes), separador coma, punto decimal y fechas AAAA-MM-DD.
  static Uint8List csv(ResumenPeriodo r) {
    String campo(String? v) {
      if (v == null) return '';
      return v.contains(RegExp('[",\n]')) ? '"${v.replaceAll('"', '""')}"' : v;
    }

    final filas = [
      Textos.encabezadosCsv.join(','),
      for (final d in r.dias)
        [
          _fechaIso(d.fecha),
          _numero(d.temperaturaMinima),
          _numero(d.temperaturaMaxima),
          _numero(d.temperatura),
          _numero(d.precipitacion),
          r.nivelDelDia(d.fecha) == null
              ? null
              : Textos.palabraNivel(r.nivelDelDia(d.fecha)!),
        ].map(campo).join(','),
    ];
    return Uint8List.fromList([
      0xEF, 0xBB, 0xBF, // BOM
      ...utf8.encode('${filas.join('\r\n')}\r\n'),
    ]);
  }

  // -------------------------------------------------------------- Excel

  /// Hojas Resumen, Días y Avisos; los números van como números.
  static List<int> excel(ResumenPeriodo r) {
    final libro = xl.Excel.createExcel();
    libro.rename(libro.getDefaultSheet()!, Textos.hojaResumen);
    final resumen = libro[Textos.hojaResumen];
    final dias = libro[Textos.hojaDias];
    final avisos = libro[Textos.hojaAvisos];

    xl.CellValue texto(String v) => xl.TextCellValue(v);
    xl.CellValue? numero(double? v) => v == null
        ? null
        : xl.DoubleCellValue(double.parse(v.toStringAsFixed(1)));

    final fria = r.nocheMasFria;
    resumen
      ..appendRow([texto(Textos.tituloReporte)])
      ..appendRow([texto(Textos.etiquetaNombre), texto(r.parcela.nombre)])
      ..appendRow([
        texto(Textos.etiquetaMunicipio),
        texto(Textos.municipio(r.parcela.municipio)),
      ])
      ..appendRow([texto(Textos.etiquetaCultivo), texto(_cultivo(r))])
      ..appendRow([texto(Textos.desde), texto(_fechaIso(r.periodo.idDesde))])
      ..appendRow([texto(Textos.hasta), texto(_fechaIso(r.periodo.idHasta))])
      ..appendRow([
        texto(Textos.diasConLluvia(2)),
        xl.IntCellValue(r.diasConLluvia),
      ])
      ..appendRow([
        texto(Textos.nocheMasFria),
        fria == null ? null : numero(ResumenPeriodo.minimaDe(fria)),
      ])
      ..appendRow([texto(Textos.llovioEnTotal), numero(r.lluviaTotal)])
      ..appendRow([
        texto(Textos.avisosDePeligro(2)),
        xl.IntCellValue(r.avisosPeligro),
      ]);

    dias.appendRow([
      for (final t in [
        Textos.fecha,
        Textos.minimaGrados,
        Textos.maximaGrados,
        Textos.registradaGrados,
        Textos.lluviaMm,
        Textos.aviso,
      ])
        texto(t),
    ]);
    for (final d in r.dias) {
      final nivel = r.nivelDelDia(d.fecha);
      dias.appendRow([
        texto(_fechaIso(d.fecha)),
        numero(d.temperaturaMinima),
        numero(d.temperaturaMaxima),
        numero(d.temperatura),
        numero(d.precipitacion),
        nivel == null ? null : texto(Textos.palabraNivel(nivel)),
      ]);
    }

    avisos.appendRow([
      for (final t in [
        Textos.fecha,
        Textos.riesgo,
        Textos.nivel,
        Textos.seEsperaba,
        Textos.loQueAguantaCorto,
        Textos.tomoMedidas,
      ])
        texto(t),
    ]);
    for (final a in r.alertas) {
      avisos.appendRow([
        texto(_fechaIsoDe(a)),
        texto(Textos.tituloAlerta(a)),
        texto(Textos.palabraNivel(a.nivel)),
        texto(Textos.valorAlerta(a.tipoRiesgo, a.valorEsperado)),
        texto(Textos.valorAlerta(a.tipoRiesgo, a.valorUmbral)),
        texto(a.atendida ? Textos.si : Textos.no),
      ]);
    }
    return libro.encode()!;
  }

  static String _fechaIsoDe(Alerta a) {
    final local = a.fechaEvento.toUtc().add(const Duration(hours: -6));
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  // ---------------------------------------------------------------- PDF

  /// Encabezado, parcela y período, los 4 indicadores, tabla de días, avisos
  /// y el pie de información de apoyo (RN-07).
  static Future<Uint8List> pdf(ResumenPeriodo r, {required DateTime ahora}) {
    final verde = PdfColor.fromInt(0xFF1B5E20);
    final gris = PdfColor.fromInt(0xFF4A4E47);
    final fria = r.nocheMasFria;
    final documento = pw.Document(
      title: '${Textos.tituloReporte} · ${r.parcela.nombre}',
      author: Textos.nombreApp,
    );

    pw.Widget indicador(String valor, String etiqueta) => pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        margin: const pw.EdgeInsets.only(right: 8),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey400),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              valor,
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(etiqueta, style: pw.TextStyle(fontSize: 9, color: gris)),
          ],
        ),
      ),
    );

    // Las fuentes del PDF no traen la raya larga: sin dato va un guion.
    String celda(double? v) => v == null ? '-' : v.toStringAsFixed(1);

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(36),
        footer: (contexto) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Divider(color: PdfColors.grey400),
            pw.Text(
              '${Textos.avisoApoyo} ${Textos.fuenteDatosReporte}',
              style: pw.TextStyle(fontSize: 8, color: gris),
            ),
            pw.Text(
              '${Textos.generado(ahora)} · ${contexto.pageNumber}/${contexto.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: gris),
            ),
          ],
        ),
        build: (contexto) => [
          pw.Text(
            Textos.nombreApp,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: verde,
            ),
          ),
          pw.Text(
            Textos.tituloReporte,
            style: const pw.TextStyle(fontSize: 14),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            '${r.parcela.nombre} · ${Textos.municipio(r.parcela.municipio)} · '
            '${_cultivo(r)}',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            Textos.periodoEnPalabras(r.periodo.desde, r.periodo.hasta),
            style: pw.TextStyle(fontSize: 11, color: gris),
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              indicador(
                '${r.diasConLluvia}',
                Textos.diasConLluvia(r.diasConLluvia),
              ),
              indicador(
                fria == null
                    ? '-'
                    : '${ResumenPeriodo.minimaDe(fria)!.round()} °C',
                Textos.nocheMasFria,
              ),
              indicador('${r.lluviaTotal.round()} mm', Textos.llovioEnTotal),
              indicador(
                '${r.avisosPeligro}',
                Textos.avisosDePeligro(r.avisosPeligro),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            Textos.diaPorDia,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: [
              Textos.fecha,
              Textos.minimaGrados,
              Textos.maximaGrados,
              Textos.lluviaMm,
              Textos.aviso,
            ],
            data: [
              for (final RegistroDia d in r.dias)
                [
                  '${d.dia.day} ${Textos.nombreMes(d.dia)}',
                  // Solo mínimas y máximas del ciclo: la temperatura suelta
                  // de un día repetida en las dos columnas confunde.
                  celda(d.temperaturaMinima),
                  celda(d.temperaturaMaxima),
                  celda(d.precipitacion),
                  r.nivelDelDia(d.fecha) == null
                      ? ''
                      : Textos.palabraNivel(r.nivelDelDia(d.fecha)!),
                ],
            ],
            headerStyle: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: verde),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            Textos.avisosDelPeriodo,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (r.alertas.isEmpty)
            pw.Text(Textos.ningunAviso, style: const pw.TextStyle(fontSize: 10))
          else
            pw.TableHelper.fromTextArray(
              headers: [
                Textos.fecha,
                Textos.riesgo,
                Textos.nivel,
                Textos.seEsperaba,
                Textos.loQueAguantaCorto,
                Textos.tomoMedidas,
              ],
              data: [
                for (final a in r.alertas)
                  [
                    _fechaIsoDe(a),
                    Textos.tituloAlerta(a),
                    Textos.palabraNivel(a.nivel),
                    Textos.valorAlerta(a.tipoRiesgo, a.valorEsperado),
                    Textos.valorAlerta(a.tipoRiesgo, a.valorUmbral),
                    a.atendida ? Textos.si : Textos.no,
                  ],
              ],
              headerStyle: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: pw.BoxDecoration(color: verde),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
            ),
        ],
      ),
    );
    return documento.save();
  }
}

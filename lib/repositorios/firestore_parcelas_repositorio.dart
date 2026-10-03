import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/parcela.dart';
import 'parcelas_repositorio.dart';

/// [ParcelasRepositorio] con Cloud Firestore. Las consultas siempre filtran
/// por `usuarioId`, o las reglas las rechazan (MODELO_DATOS §5).
class FirestoreParcelasRepositorio implements ParcelasRepositorio {
  FirestoreParcelasRepositorio({this._db});

  final FirebaseFirestore? _db;

  FirebaseFirestore get _firestore => _db ?? FirebaseFirestore.instance;

  /// Si el servidor no confirma en este tiempo, la parcela queda guardada en
  /// el teléfono y Firestore la sube sola cuando vuelva la señal.
  static const Duration esperaConfirmacion = Duration(seconds: 8);

  CollectionReference<Map<String, dynamic>> get _parcelas =>
      _firestore.collection('parcelas');

  @override
  Future<ParcelaGuardada> crear(Parcela parcela) async {
    final ref = _parcelas.doc();
    var pendiente = false;
    await ref
        .set({
          ...parcela.toMap(),
          'parcelaId': ref.id,
          // ≥ 4 decimales (HU-03); se guardan 6 (~0.1 m).
          'ubicacion': GeoPoint(
            _seisDecimales(parcela.latitud),
            _seisDecimales(parcela.longitud),
          ),
          'fechaRegistro': FieldValue.serverTimestamp(),
          'fechaActualizacion': FieldValue.serverTimestamp(),
        })
        .timeout(esperaConfirmacion, onTimeout: () => pendiente = true);
    return ParcelaGuardada(parcelaId: ref.id, pendiente: pendiente);
  }

  @override
  Stream<List<Parcela>> listar(String usuarioId) => _parcelas
      .where('usuarioId', isEqualTo: usuarioId)
      .snapshots()
      .map(
        (consulta) =>
            [for (final doc in consulta.docs) _desdeDoc(doc.id, doc.data())]
              ..sort((a, b) => a.nombre.compareTo(b.nombre)),
      );

  @override
  Stream<Parcela?> observar(String parcelaId) =>
      _parcelas.doc(parcelaId).snapshots().map((doc) {
        final datos = doc.data();
        return datos == null ? null : _desdeDoc(doc.id, datos);
      });

  @override
  Future<List<String>> nombres(String usuarioId) async {
    final consulta = await _parcelas
        .where('usuarioId', isEqualTo: usuarioId)
        .get();
    return [for (final doc in consulta.docs) doc.data()['nombre'] as String];
  }

  @override
  Future<bool> actualizar(Parcela parcela) async {
    var pendiente = false;
    final datos = {
      ...parcela.toMap(),
      'ubicacion': GeoPoint(
        _seisDecimales(parcela.latitud),
        _seisDecimales(parcela.longitud),
      ),
      'fechaActualizacion': FieldValue.serverTimestamp(),
    };
    await _parcelas
        .doc(parcela.parcelaId)
        .update(datos)
        .timeout(esperaConfirmacion, onTimeout: () => pendiente = true);
    return pendiente;
  }

  @override
  Future<bool> eliminar(String parcelaId) async {
    var pendiente = false;
    await _parcelas
        .doc(parcelaId)
        .delete()
        .timeout(esperaConfirmacion, onTimeout: () => pendiente = true);
    return pendiente;
  }

  static Parcela _desdeDoc(String id, Map<String, dynamic> datos) {
    final ubicacion = datos['ubicacion'] as GeoPoint;
    final fecha = datos['fechaRegistro'];
    return Parcela.fromMap(
      id,
      datos,
      latitud: ubicacion.latitude,
      longitud: ubicacion.longitude,
      fechaRegistro: fecha is Timestamp ? fecha.toDate() : null,
    );
  }

  static double _seisDecimales(double valor) =>
      (valor * 1e6).roundToDouble() / 1e6;
}

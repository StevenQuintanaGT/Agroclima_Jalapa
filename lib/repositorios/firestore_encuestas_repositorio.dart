import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/encuesta.dart';
import 'encuestas_repositorio.dart';

/// [EncuestasRepositorio] con Cloud Firestore: un documento por usuario,
/// con el uid como id.
class FirestoreEncuestasRepositorio implements EncuestasRepositorio {
  FirestoreEncuestasRepositorio({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Si el servidor no confirma en este tiempo, la encuesta sigue guardada
  /// en el teléfono y Firestore la sube sola cuando vuelva la señal.
  static const Duration esperaConfirmacion = Duration(seconds: 10);

  DocumentReference<Map<String, dynamic>> _encuesta(String uid) =>
      _db.collection('encuestas').doc(uid);

  @override
  Future<Encuesta?> obtener(String uid) async {
    final doc = await _encuesta(uid).get();
    final datos = doc.data();
    if (datos == null) return null;
    return Encuesta.fromMap(datos, fecha: _fecha);
  }

  static DateTime? _fecha(Object? valor) =>
      valor is Timestamp ? valor.toDate() : null;

  /// `set` sin combinar: un detalle que se borró no queda guardado.
  @override
  Future<void> guardar(Encuesta encuesta) => _encuesta(encuesta.uid)
      .set({
        ...encuesta.toMap(),
        'fechaRespuesta': FieldValue.serverTimestamp(),
      })
      .timeout(esperaConfirmacion, onTimeout: () {});
}

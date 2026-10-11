import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../config/constantes.dart';
import '../modelos/alerta.dart';
import 'alertas_repositorio.dart';

/// [AlertasRepositorio] con Cloud Firestore y su persistencia sin conexión
/// (HU-15): las alertas ya bajadas se ven aunque no haya señal (RT-05).
class FirestoreAlertasRepositorio implements AlertasRepositorio {
  FirestoreAlertasRepositorio({this._db});

  final FirebaseFirestore? _db;

  CollectionReference<Map<String, dynamic>> get _alertas =>
      (_db ?? FirebaseFirestore.instance).collection('alertas');

  @override
  Stream<List<Alerta>> delUsuario(String usuarioId, {int? limite}) => _alertas
      .where('usuarioId', isEqualTo: usuarioId)
      .orderBy('fechaGeneracion', descending: true)
      .limit(limite ?? Constantes.alertasEnLista)
      .snapshots()
      .map(
        (consulta) => [
          for (final doc in consulta.docs) ?_desdeDoc(doc.id, doc.data()),
        ],
      );

  @override
  Stream<Alerta?> observar(String alertaId) =>
      _alertas.doc(alertaId).snapshots().map((doc) {
        final datos = doc.data();
        return datos == null ? null : _desdeDoc(doc.id, datos);
      });

  @override
  Future<void> marcarLeida(String alertaId) =>
      _actualizar(alertaId, {'leida': true});

  @override
  Future<void> marcarAtendida(String alertaId) =>
      _actualizar(alertaId, {'atendida': true});

  /// Sin `await` del servidor: sin señal la escritura queda en cola y se
  /// sube sola (la regla solo deja cambiar `leida` y `atendida`).
  Future<void> _actualizar(String alertaId, Map<String, Object> cambios) {
    _alertas
        .doc(alertaId)
        .update(cambios)
        .catchError((Object e) => debugPrint('Alerta $alertaId: $e'));
    return Future.value();
  }

  Alerta? _desdeDoc(String id, Map<String, dynamic> datos) {
    final evento = datos['fechaEvento'];
    if (evento is! Timestamp) return null;
    final alerta = Alerta.fromMap(
      id,
      datos,
      fechaEvento: evento.toDate().toUtc(),
      fechaGeneracion: (datos['fechaGeneracion'] as Timestamp?)
          ?.toDate()
          .toUtc(),
    );
    if (alerta == null) debugPrint('Alerta $id ignorada: no se entiende');
    return alerta;
  }
}

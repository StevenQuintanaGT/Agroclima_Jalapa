import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/registro_dia.dart';
import 'historial_repositorio.dart';

/// [HistorialRepositorio] con Cloud Firestore.
class FirestoreHistorialRepositorio implements HistorialRepositorio {
  FirestoreHistorialRepositorio({this._db});

  final FirebaseFirestore? _db;

  @override
  Stream<List<RegistroDia>> dias(String parcelaId, {required int limite}) =>
      (_db ?? FirebaseFirestore.instance)
          .collection('parcelas/$parcelaId/condiciones')
          // Por el campo `fecha` (= id): Firestore no recorre ids al revés,
          // y el índice de un campo lo crea solo, en los dos sentidos.
          .orderBy('fecha', descending: true)
          .limit(limite)
          .snapshots()
          .map(
            (consulta) => [
              for (final doc in consulta.docs)
                RegistroDia.fromMap(doc.id, doc.data()),
            ],
          );
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../modelos/umbral.dart';
import 'umbrales_repositorio.dart';

/// [UmbralesRepositorio] con Cloud Firestore. La app nunca escribe aquí: lo
/// cargan el script de semilla o la consola de Firebase.
class FirestoreUmbralesRepositorio implements UmbralesRepositorio {
  FirestoreUmbralesRepositorio({this._db});

  final FirebaseFirestore? _db;

  FirebaseFirestore get _firestore => _db ?? FirebaseFirestore.instance;

  @override
  Future<List<Umbral>> vigentes() async {
    final consulta = await _firestore
        .collection('umbrales')
        .where('vigente', isEqualTo: true)
        .get();
    final lista = <Umbral>[];
    for (final doc in consulta.docs) {
      final umbral = Umbral.fromMap(doc.id, doc.data());
      if (umbral == null) {
        debugPrint('Umbral ${doc.id} ignorado: no se entiende');
      } else {
        lista.add(umbral);
      }
    }
    return lista;
  }
}

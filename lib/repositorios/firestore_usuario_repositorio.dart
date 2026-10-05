import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../modelos/enums.dart';
import '../modelos/preferencia_alerta.dart';
import '../modelos/usuario.dart';
import 'usuario_repositorio.dart';

/// [UsuarioRepositorio] con Cloud Firestore.
class FirestoreUsuarioRepositorio implements UsuarioRepositorio {
  FirestoreUsuarioRepositorio({FirebaseFirestore? db})
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Si el servidor no confirma en este tiempo, la escritura sigue guardada
  /// en el teléfono y Firestore la sube sola cuando vuelva la señal.
  static const Duration esperaConfirmacion = Duration(seconds: 10);

  DocumentReference<Map<String, dynamic>> _perfil(String uid) =>
      _db.collection('usuarios').doc(uid);

  @override
  Future<void> crearPerfil(Usuario usuario) async {
    final lote = _db.batch();
    lote.set(_perfil(usuario.uid), {
      ...usuario.toMap(),
      'fechaRegistro': FieldValue.serverTimestamp(),
    });
    for (final tipo in TipoRiesgo.values) {
      lote.set(
        _perfil(usuario.uid).collection('preferencias').doc(tipo.valor),
        PreferenciaAlerta.porDefecto(tipo).toMap(),
      );
    }
    await lote.commit().timeout(esperaConfirmacion, onTimeout: () {});
  }

  @override
  Future<Usuario?> obtenerPerfil(String uid) async {
    final doc = await _perfil(uid).get();
    final datos = doc.data();
    if (datos == null) return null;
    return Usuario.fromMap(
      datos,
      fecha: (valor) => valor is Timestamp ? valor.toDate() : null,
    );
  }

  @override
  Future<void> agregarTokenAvisos(String uid, String token) =>
      _perfil(uid)
          .update({
            'tokensFcm': FieldValue.arrayUnion([token]),
          })
          .timeout(esperaConfirmacion, onTimeout: () {});

  @override
  Future<void> quitarTokenAvisos(String uid, String token) =>
      _perfil(uid)
          .update({
            'tokensFcm': FieldValue.arrayRemove([token]),
          })
          .timeout(esperaConfirmacion, onTimeout: () {});

  @override
  Stream<List<PreferenciaAlerta>> observarPreferencias(String uid) =>
      _perfil(uid)
          .collection('preferencias')
          .snapshots()
          .map(
            (consulta) => [
              for (final doc in consulta.docs)
                if (TipoRiesgo.desdeValor(doc.id) != null)
                  PreferenciaAlerta.fromMap({
                    ...doc.data(),
                    'tipoRiesgo': doc.id,
                  }),
            ],
          );

  @override
  Future<void> guardarPreferencias(String uid, List<PreferenciaAlerta> lista) {
    final lote = _db.batch();
    for (final preferencia in lista) {
      lote.set(
        _perfil(uid)
            .collection('preferencias')
            .doc(preferencia.tipoRiesgo.valor),
        preferencia.toMap(),
      );
    }
    return lote.commit().timeout(esperaConfirmacion, onTimeout: () {});
  }

  @override
  Future<void> borrarDatosLocales() async {
    await _db.terminate();
    await _db.clearPersistence();
  }
}

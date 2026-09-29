import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'auth_repositorio.dart';

/// [AuthRepositorio] con Firebase Authentication. Firebase guarda solo el
/// token de sesión; la contraseña nunca se guarda en el teléfono (RNF-01).
class FirebaseAuthRepositorio implements AuthRepositorio {
  FirebaseAuthRepositorio({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  @override
  String? get uidActual => _auth.currentUser?.uid;

  @override
  Stream<String?> get cambiosDeSesion =>
      _auth.authStateChanges().map((usuario) => usuario?.uid);

  @override
  Future<String> registrarConCorreo({
    required String correo,
    required String contrasena,
    required String nombre,
  }) async {
    try {
      final credencial = await _auth.createUserWithEmailAndPassword(
        email: correo,
        password: contrasena,
      );
      final usuario = credencial.user!;
      await usuario.updateDisplayName(nombre);
      return usuario.uid;
    } on FirebaseAuthException catch (error) {
      debugPrint('FirebaseAuth ${error.code}: ${error.message}');
      throw ErrorAcceso(codigoDeAcceso(error.code, error.message));
    }
  }

  @override
  Future<void> cerrarSesion() => _auth.signOut();
}

final RegExp _pareceSinSenal = RegExp(
  r'failed to connect|unable to resolve host|network|timeout|timed out|'
  r'unreachable|i/o error|connection',
  caseSensitive: false,
);

/// Código estable para la pantalla. Sin señal, Firebase a veces responde
/// `unknown` o `internal-error` en lugar de `network-request-failed`; se
/// reconoce por el mensaje para decirle al productor la causa real.
@visibleForTesting
String codigoDeAcceso(String codigo, String? mensaje) {
  final generico = codigo == 'unknown' || codigo == 'internal-error';
  if (generico && mensaje != null && _pareceSinSenal.hasMatch(mensaje)) {
    return 'network-request-failed';
  }
  return codigo;
}

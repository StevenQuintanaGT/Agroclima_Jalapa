import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_repositorio.dart';

/// [AuthRepositorio] con Firebase Authentication y Google. Firebase guarda
/// solo el token de sesión; la contraseña nunca se guarda en el teléfono (RNF-01).
class FirebaseAuthRepositorio implements AuthRepositorio {
  FirebaseAuthRepositorio({FirebaseAuth? auth, GoogleSignIn? google})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = google ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleListo;

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
  }) => _traducir(() async {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: correo,
      password: contrasena,
    );
    final usuario = credencial.user!;
    await usuario.updateDisplayName(nombre);
    return usuario.uid;
  });

  @override
  Future<DatosAcceso> iniciarSesionConCorreo({
    required String correo,
    required String contrasena,
  }) => _traducir(() async {
    final credencial = await _auth.signInWithEmailAndPassword(
      email: correo,
      password: contrasena,
    );
    return _datos(credencial.user!);
  });

  @override
  Future<DatosAcceso> iniciarSesionConGoogle() => _traducir(() async {
    _googleListo ??= _google.initialize();
    await _googleListo;
    final GoogleSignInAccount cuenta;
    try {
      cuenta = await _google.authenticate();
    } on GoogleSignInException catch (error) {
      debugPrint('Google ${error.code}: ${error.description}');
      throw ErrorAcceso(
        error.code == GoogleSignInExceptionCode.canceled
            ? ErrorAcceso.cancelado
            : 'google-${error.code.name}',
      );
    }
    final credencial = await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: cuenta.authentication.idToken),
    );
    return _datos(credencial.user!);
  });

  @override
  Future<void> recuperarContrasena(String correo) =>
      _traducir(() => _auth.sendPasswordResetEmail(email: correo));

  @override
  Future<void> cerrarSesion() async {
    if (_googleListo != null) {
      try {
        await _google.signOut();
      } catch (error) {
        debugPrint('Google signOut: $error');
      }
    }
    await _auth.signOut();
  }

  DatosAcceso _datos(User usuario) => DatosAcceso(
    uid: usuario.uid,
    nombre: usuario.displayName ?? '',
    correo: usuario.email ?? '',
  );

  Future<T> _traducir<T>(Future<T> Function() accion) async {
    try {
      return await accion();
    } on FirebaseAuthException catch (error) {
      debugPrint('FirebaseAuth ${error.code}: ${error.message}');
      throw ErrorAcceso(codigoDeAcceso(error.code, error.message));
    }
  }
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

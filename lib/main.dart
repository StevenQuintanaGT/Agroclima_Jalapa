import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/entorno.dart';
import 'config/rutas.dart';
import 'repositorios/auth_repositorio.dart';
import 'repositorios/firebase_auth_repositorio.dart';
import 'repositorios/firestore_usuario_repositorio.dart';
import 'repositorios/usuario_repositorio.dart';
import 'servicios/cuenta_servicio.dart';
import 'servicios/estado_sesion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await _iniciarFirebase();

  // Proveedor de dependencias: las pantallas solo ven contratos (RNF-20).
  final AuthRepositorio auth = FirebaseAuthRepositorio();
  final UsuarioRepositorio usuarios = FirestoreUsuarioRepositorio();
  final estadoSesion = EstadoSesion(auth);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepositorio>.value(value: auth),
        Provider<UsuarioRepositorio>.value(value: usuarios),
        Provider(
          create: (_) => CuentaServicio(auth: auth, usuarios: usuarios),
        ),
        ChangeNotifierProvider<EstadoSesion>.value(value: estadoSesion),
      ],
      child: AgroClimaApp(enrutador: crearEnrutador(haySesion: estadoSesion)),
    ),
  );
}

/// Solo Android: las opciones salen de android/app/google-services.json,
/// que genera `flutterfire configure` (DECISIONES D-22).
Future<void> _iniciarFirebase() async {
  try {
    await Firebase.initializeApp();
    if (Entorno.usarEmuladores) {
      await FirebaseAuth.instance.useAuthEmulator(Entorno.hostEmuladores, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(
        Entorno.hostEmuladores,
        8080,
      );
      debugPrint('Usando emuladores de Firebase en ${Entorno.hostEmuladores}');
    }
    // Persistencia sin conexión: el productor ve lo último guardado (HU-15, RNF-08).
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (error) {
    debugPrint(
      'Firebase no se inicializó (¿falta google-services.json?): $error',
    );
  }
}

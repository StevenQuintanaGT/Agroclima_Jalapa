import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'config/entorno.dart';
import 'config/rutas.dart';
import 'repositorios/auth_repositorio.dart';
import 'repositorios/firebase_auth_repositorio.dart';
import 'repositorios/firestore_parcelas_repositorio.dart';
import 'repositorios/firestore_usuario_repositorio.dart';
import 'repositorios/cache_local.dart';
import 'repositorios/clima_repositorio.dart';
import 'repositorios/openweather_clima_repositorio.dart';
import 'repositorios/parcelas_repositorio.dart';
import 'repositorios/preferencias_locales_repositorio.dart';
import 'repositorios/shared_preferences_locales_repositorio.dart';
import 'repositorios/usuario_repositorio.dart';
import 'servicios/cuenta_servicio.dart';
import 'servicios/busqueda_lugares_servicio.dart';
import 'servicios/clima_servicio.dart';
import 'servicios/conectividad_servicio.dart';
import 'servicios/openweather_cliente.dart';
import 'servicios/estado_sesion.dart';
import 'servicios/notificaciones_servicio.dart';
import 'servicios/parcelas_servicio.dart';
import 'servicios/ubicacion_servicio.dart';
import 'servicios/validacion_geografica.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await _iniciarFirebase();

  // Proveedor de dependencias: las pantallas solo ven contratos (RNF-20).
  final AuthRepositorio auth = FirebaseAuthRepositorio();
  final UsuarioRepositorio usuarios = FirestoreUsuarioRepositorio();
  final PreferenciasLocalesRepositorio preferencias =
      await SharedPreferencesLocalesRepositorio.crear();
  final notificaciones = NotificacionesServicio();
  final cuenta = CuentaServicio(
    auth: auth,
    usuarios: usuarios,
    notificaciones: notificaciones,
  )..vigilarTokenDeAvisos();
  final estadoSesion = EstadoSesion(auth);
  final validacion = await ValidacionGeografica.cargar(rootBundle);
  final ParcelasRepositorio parcelas = FirestoreParcelasRepositorio();
  final ClimaRepositorio clima = OpenWeatherClimaRepositorio(
    cliente: OpenWeatherCliente(clave: Entorno.openWeatherApiKey),
    cache: SharedPreferencesCacheLocal(),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthRepositorio>.value(value: auth),
        Provider<UsuarioRepositorio>.value(value: usuarios),
        Provider<PreferenciasLocalesRepositorio>.value(value: preferencias),
        Provider.value(value: notificaciones),
        Provider(create: (_) => UbicacionServicio()),
        Provider.value(value: cuenta),
        Provider<ParcelasRepositorio>.value(value: parcelas),
        Provider(
          create: (_) => ParcelasServicio(
            repositorio: parcelas,
            auth: auth,
            validacion: validacion,
          ),
        ),
        Provider(create: (_) => BusquedaLugaresServicio()),
        Provider<ClimaRepositorio>.value(value: clima),
        Provider(create: (_) => ClimaServicio(clima)),
        Provider(create: (_) => ConectividadServicio()),
        ChangeNotifierProvider<EstadoSesion>.value(value: estadoSesion),
      ],
      child: AgroClimaApp(
        enrutador: crearEnrutador(
          haySesion: estadoSesion,
          preferencias: preferencias,
        ),
      ),
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

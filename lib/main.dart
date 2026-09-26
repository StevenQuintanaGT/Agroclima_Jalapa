import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');
  await _iniciarFirebase();
  // Los repositorios y servicios se registran con MultiProvider a medida que
  // se construyen (HT-02 en adelante).
  runApp(const AgroClimaApp());
}

/// Solo Android: las opciones salen de android/app/google-services.json,
/// que genera `flutterfire configure` (DECISIONES D-22).
Future<void> _iniciarFirebase() async {
  try {
    await Firebase.initializeApp();
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

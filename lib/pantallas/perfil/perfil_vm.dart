import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../modelos/enums.dart';
import '../../modelos/parcela.dart';
import '../../modelos/usuario.dart';
import '../../servicios/cuenta_servicio.dart';
import '../../servicios/parcelas_servicio.dart';
import '../../servicios/perfil_servicio.dart';
import '../../utilidades/validadores.dart';

/// Estado del perfil (pantalla 28): datos del productor, cuántas parcelas
/// tiene y dónde, cambiar nombre y teléfono, y cerrar sesión (HU-02).
class PerfilVm extends ChangeNotifier {
  PerfilVm({
    required this._cuenta,
    required this._perfil,
    required ParcelasServicio parcelas,
  }) {
    _perfil.addListener(_avisar);
    _suscripcion = parcelas.misParcelas().listen(
      (lista) {
        _parcelas = lista;
        _avisar();
      },
      onError: (Object error) => debugPrint('Parcelas no disponibles: $error'),
    );
  }

  final CuentaServicio _cuenta;
  final PerfilServicio _perfil;
  late final StreamSubscription<List<Parcela>> _suscripcion;
  List<Parcela> _parcelas = const [];
  bool _cerrando = false;
  bool _guardando = false;
  bool _descartado = false;

  Usuario? get usuario => _perfil.usuario;
  int get cantidadParcelas => _parcelas.length;
  bool get cerrando => _cerrando;
  bool get guardando => _guardando;

  /// El municipio donde tiene más parcelas (el de la primera si empatan).
  Municipio? get municipio {
    if (_parcelas.isEmpty) return null;
    final cuenta = <Municipio, int>{};
    for (final p in _parcelas) {
      cuenta[p.municipio] = (cuenta[p.municipio] ?? 0) + 1;
    }
    return cuenta.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  /// Teléfono sin "+502" para el campo, que ya muestra el prefijo.
  String get telefonoLocal {
    final telefono = usuario?.telefono ?? '';
    final digitos = Validadores.soloDigitos(telefono);
    return digitos.length > 8 ? digitos.substring(digitos.length - 8) : digitos;
  }

  /// Guarda nombre y teléfono. Devuelve `false` si algo no es válido (la hoja
  /// muestra el error con los mismos validadores del registro). Sin señal
  /// queda en el teléfono y se sube sola.
  Future<bool> guardarDatos({
    required String nombre,
    required String telefono,
  }) async {
    if (Validadores.nombre(nombre) != null ||
        Validadores.telefono(telefono) != null) {
      return false;
    }
    _guardando = true;
    _avisar();
    try {
      await _perfil.guardarDatos(
        nombre: nombre.trim(),
        telefono: Validadores.telefonoConCodigo(telefono),
      );
      return true;
    } catch (error) {
      debugPrint('No se guardaron los datos: $error');
      return false;
    } finally {
      _guardando = false;
      _avisar();
    }
  }

  Future<void> cerrarSesion() async {
    if (_cerrando) return;
    _cerrando = true;
    _avisar();
    try {
      await _cuenta.cerrarSesion();
    } catch (error) {
      debugPrint('Cerrar sesión falló: $error');
    } finally {
      _cerrando = false;
      _avisar();
    }
  }

  void _avisar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _perfil.removeListener(_avisar);
    _suscripcion.cancel();
    super.dispose();
  }
}

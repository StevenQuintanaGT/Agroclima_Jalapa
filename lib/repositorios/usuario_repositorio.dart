import '../modelos/preferencia_alerta.dart';
import '../modelos/usuario.dart';

/// Contrato del perfil del productor y sus preferencias de avisos.
/// Implementación: `FirestoreUsuarioRepositorio`.
abstract class UsuarioRepositorio {
  /// Crea `usuarios/{uid}` y las 6 preferencias por defecto (Tablas 64 y 65)
  /// en una sola escritura.
  Future<void> crearPerfil(Usuario usuario);

  /// Perfil del usuario, o `null` si todavía no existe.
  Future<Usuario?> obtenerPerfil(String uid);

  /// Perfil en vivo (Perfil y Ajustes, pantallas 28 y 29). Sin señal, la
  /// copia del teléfono; `null` si no existe.
  Stream<Usuario?> observarPerfil(String uid);

  /// Cambia nombre y teléfono (el correo no se cambia). Sin señal queda en el
  /// teléfono y se sube sola.
  Future<void> guardarDatos(
    String uid, {
    required String nombre,
    required String telefono,
  });

  /// Cambia solo los ajustes que se pasan (pantalla 29). Sin señal queda en
  /// el teléfono y se sube sola.
  Future<void> guardarAjustes(
    String uid, {
    String? unidadTemperatura,
    String? unidadArea,
    bool? temaOscuro,
    bool? ahorroDatos,
  });

  /// Pide eliminar la cuenta (D-55): marca `eliminacionSolicitada` y vacía
  /// los tokens para que ningún teléfono reciba más avisos. **Espera al
  /// servidor**: si no confirma a tiempo lanza `TimeoutException`, porque al
  /// cerrar sesión se borra la copia local y la marca se perdería.
  Future<void> solicitarEliminacion(String uid);

  /// Agrega el token de avisos de este teléfono (Tabla 76: un token por
  /// teléfono con sesión activa).
  Future<void> agregarTokenAvisos(String uid, String token);

  /// Quita el token al cerrar sesión: este teléfono deja de recibir avisos.
  Future<void> quitarTokenAvisos(String uid, String token);

  /// Preferencias de avisos en vivo (`usuarios/{uid}/preferencias`, Tabla 65).
  /// Sin señal, la copia del teléfono.
  Stream<List<PreferenciaAlerta>> observarPreferencias(String uid);

  /// Guarda varias preferencias juntas. Sin señal queda en el teléfono y se
  /// sube sola; el ciclo la usa en su siguiente vuelta.
  Future<void> guardarPreferencias(String uid, List<PreferenciaAlerta> lista);

  /// Borra la copia local de los datos al cerrar sesión (MODELO_DATOS §7).
  Future<void> borrarDatosLocales();
}

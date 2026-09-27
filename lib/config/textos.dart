import '../modelos/enums.dart';

/// Todos los textos visibles de la app (RNF-13). Trato de usted, palabras del
/// campo, sin anglicismos ni códigos de error (docs/DISENO_UI.md §6).
/// Los textos de pantallas vienen del diseño (docs/diseno/).
class Textos {
  Textos._();

  // ---------- Marca ----------
  static const String nombreApp = 'AgroClima Jalapa';
  static const String marca = 'AgroClima';
  static const String marcaLugar = 'Jalapa';
  static const String lema = 'El clima de su parcela, antes de que pase';

  // ---------- Barra inferior ----------
  static const String navInicio = 'Inicio';
  static const String navMapa = 'Mapa';
  static const String navAlertas = 'Alertas';
  static const String navReportes = 'Reportes';
  static const String navPerfil = 'Perfil';

  // ---------- Semáforo (Tabla 72) ----------
  static String palabraNivel(NivelSeveridad nivel) => switch (nivel) {
    NivelSeveridad.informativa => 'NORMAL',
    NivelSeveridad.preventiva => 'PRECAUCIÓN',
    NivelSeveridad.critica => 'PELIGRO',
  };

  // ---------- Componentes transversales ----------
  static const String intentarDeNuevo = 'Intentar de nuevo';
  static const String verDatosGuardados = 'Ver datos guardados';
  static const String sinInternetTitulo = 'No hay internet';
  static const String sinInternetDetalle =
      'Le mostramos lo último que guardamos';
  static String datosDel(String fechaHora) => 'Datos del $fechaHora';
  static const String avisoApoyo =
      'Esta información es de apoyo. No sustituye los avisos oficiales de '
      'INSIVUMEH o CONRED.';
  static const String errorServicioTitulo = 'No pudimos traer el clima';
  static const String errorServicioDetalle =
      'Puede ser la señal o que el servicio esté ocupado. Intente otra vez en '
      'un momento.';
  static const String cargandoClima = 'Buscando el clima de su parcela…';
  static const String enConstruccionTitulo = 'Muy pronto';
  static const String enConstruccionDetalle =
      'Esta parte de la aplicación todavía se está preparando.';

  // ---------- Onboarding (pantallas 02–04) ----------
  static const String omitir = 'Omitir';
  static const String siguiente = 'Siguiente';
  static const String empezar = 'Empezar';
  static const String onboarding1Titulo = 'Marque su parcela';
  static const String onboarding1Detalle =
      'Ponga un punto donde está su terreno.';
  static const String onboarding2Titulo = 'Vea el clima de ahí';
  static const String onboarding2Detalle =
      'No el del pueblo: el de su terreno.';
  static const String onboarding3Titulo = 'Le avisamos antes';
  static const String onboarding3Detalle =
      'Un día antes de la helada o el aguacero.';

  // ---------- Inicio de sesión (05) ----------
  static const String entrarTitulo = 'Entre a su cuenta';
  static const String correo = 'Su correo';
  static const String contrasena = 'Su contraseña';
  static const String ver = 'Ver';
  static const String ocultar = 'Ocultar';
  static const String olvideContrasena = 'Olvidé mi contraseña';
  static const String entrar = 'Entrar';
  static const String entrando = 'Entrando…';
  static const String o = 'o';
  static const String entrarConGoogle = 'Entrar con Google';
  static const String sinCuenta = '¿Todavía no tiene cuenta?';
  static const String crearCuenta = 'Crear cuenta';

  // ---------- Registro (06) ----------
  static const String nombreCompleto = 'Su nombre completo';
  static const String telefono = 'Su teléfono';
  static const String creeContrasena = 'Cree una contraseña';
  static const String prefijoGuatemala = '+502';
  static const String ayudaContrasena = 'Use al menos 8 letras o números.';
  static const String repetirContrasena = 'Repita la contraseña';
  static const String aceptoTerminosAntes = 'Acepto los ';
  static const String terminosDeUso = 'términos de uso';
  static const String aceptoTerminosDespues = ' y el manejo de mis datos.';
  static const String crearMiCuenta = 'Crear mi cuenta';

  // ---------- Recuperar contraseña (07) ----------
  static const String recuperarTitulo = 'Recuperar contraseña';
  static const String recuperarDetalle =
      'Escriba su correo y le mandamos un enlace para poner una contraseña nueva.';
  static const String enviarEnlace = 'Enviar enlace';
  static const String enlaceEnviadoTitulo = 'Ya se lo enviamos';
  static const String enlaceEnviadoDetalle =
      'Revise su correo. Si no lo ve, busque en "correo no deseado".';

  // ---------- Permisos (08–09) ----------
  static const String ahoraNo = 'Ahora no';
  static const String permisoUbicacionTitulo =
      'Necesitamos saber dónde está su parcela';
  static const String permisoUbicacionDetalle =
      'Así le damos el clima de su terreno y no el de otro lugar. Nadie más ve '
      'dónde está.';
  static const String permitir = 'Permitir';
  static const String permisoAvisosTitulo = 'Deje que le avisemos del peligro';
  static const String permisoAvisosDetalle =
      'Le mandamos un aviso un día antes de una helada, un aguacero o viento '
      'fuerte. Solo eso.';
  static const String permitirAvisos = 'Permitir avisos';

  // ---------- Validaciones (VA-04, VA-05) ----------
  static const String errorCorreo = 'Ese correo no se ve bien. Revíselo.';
  static const String errorContrasenaCorta =
      'La contraseña necesita al menos 8 letras o números.';
  static const String errorContrasenasDistintas =
      'Las dos contraseñas no son iguales.';
  static const String errorNombreVacio = 'Escriba su nombre.';
}

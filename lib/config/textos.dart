import 'package:intl/intl.dart';

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
  static const String creandoCuenta = 'Creando su cuenta…';

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
  static const String errorContrasenaVacia = 'Escriba su contraseña.';
  static const String errorTelefono =
      'Escriba los 8 números de su teléfono, o déjelo vacío.';
  static const String errorTerminos =
      'Para crear la cuenta, marque que acepta los términos.';

  // ---------- Errores de acceso (plans/01, utilidades/errores.dart) ----------
  static const String errorCorreoEnUso =
      'Ese correo ya tiene cuenta. ¿Quiere entrar?';
  static const String errorCredenciales =
      'El correo o la contraseña no coinciden.';
  static const String errorContrasenaDebil =
      'La contraseña debe tener al menos 8 letras o números.';
  static const String errorSinSenal =
      'No hay señal. Intente de nuevo cuando tenga internet.';
  static const String errorMuchosIntentos =
      'Hubo muchos intentos. Espere un momento y vuelva a probar.';
  static const String errorGenerico = 'No se pudo completar. Intente de nuevo.';
  static const String errorGoogle =
      'No se pudo entrar con Google. Intente de nuevo o use su correo.';

  // ---------- Enumeraciones (MODELO_DATOS §2, D-01, D-02) ----------
  static String municipio(Municipio m) => switch (m) {
    Municipio.jalapa => 'Jalapa',
    Municipio.sanPedroPinula => 'San Pedro Pinula',
    Municipio.sanLuisJilotepeque => 'San Luis Jilotepeque',
    Municipio.sanManuelChaparron => 'San Manuel Chaparrón',
    Municipio.sanCarlosAlzatate => 'San Carlos Alzatate',
    Municipio.monjas => 'Monjas',
    Municipio.mataquescuintla => 'Mataquescuintla',
  };

  static String cultivo(Cultivo c) => switch (c) {
    Cultivo.maiz => 'Maíz',
    Cultivo.frijol => 'Frijol',
    Cultivo.cafe => 'Café',
    Cultivo.hortalizas => 'Hortalizas',
  };

  static String etapa(Etapa e) => switch (e) {
    Etapa.siembra => 'Siembra',
    Etapa.desarrolloVegetativo => 'Creciendo',
    Etapa.floracion => 'Floreando',
    Etapa.llenado => 'Llenando el grano',
    Etapa.cosecha => 'Cosecha',
  };

  // ---------- Registro de parcela (pantallas 10–13) ----------
  static const String nuevaParcela = 'Nueva parcela';
  static String pasoDe(int paso, int total) => 'Paso $paso de $total';
  static const String pregNombreParcela = '¿Cómo le llama a su parcela?';
  static const String ayudaNombreParcela = 'Un nombre que usted reconozca.';
  static const String pregMunicipio = '¿En qué municipio queda?';
  static const String pregCultivo = '¿Qué siembra ahí?';
  static const String pregEtapa = '¿Cómo va el cultivo?';
  static const String sinSembrar = 'Todavía no he sembrado';
  static const String ayudaSinSembrar =
      'Le avisaremos de helada, lluvia fuerte, viento y días sin lluvia.';
  static const String tituloPaso3 = 'Ponga el punto';
  static const String buscarLugar = 'Buscar aldea o lugar';
  static const String sinResultados =
      'No encontramos ese lugar. Mueva el pin hasta su terreno.';
  static const String arrastrePin = 'Arrastre el pin';
  static const String fuenteMapa =
      'Imágenes: Esri, Maxar, Earthstar Geographics y la comunidad GIS';
  static const String usarMiUbicacion = 'Usar mi ubicación';
  static const String buscandoUbicacion = 'Buscando dónde está…';
  static const String coordenadas = 'Coordenadas';
  static const String altura = 'Altura';
  static String msnm(int metros) => '${_miles.format(metros)} msnm';
  static final NumberFormat _miles = NumberFormat('#,##0', 'en_US');
  static const String alturaVacia = 'Escriba la altura (opcional)';
  static const String pregTamano = '¿Cuánto mide? (aproximado)';
  static const String manzanas = 'manzanas';
  static const String hectareasCorto = 'ha';
  static const String tituloPaso4 = 'Revise los datos';
  static const String etiquetaNombre = 'Nombre';
  static const String etiquetaMunicipio = 'Municipio';
  static const String etiquetaCultivo = 'Cultivo';
  static const String etiquetaTamanoAltura = 'Tamaño y altura';
  static const String cambiar = 'Cambiar';
  static const String sinDato = 'Sin dato';
  static const String guardarParcela = 'Guardar parcela';
  static const String guardandoParcela = 'Guardando…';
  static const String guardadaSinSenal =
      'Guardada. Se enviará cuando haya señal.';

  // Validaciones de parcela (VA-01, VA-02, VA-03)
  static const String errorNombreParcelaVacio =
      'Escriba un nombre para su parcela.';
  static const String errorNombreParcelaLargo =
      'Use un nombre más corto (hasta 40 letras).';
  static const String errorNombreParcelaRepetido =
      'Ya tiene una parcela con ese nombre. Use otro.';
  static const String errorFueraDeJalapa =
      'Ese punto queda fuera del departamento de Jalapa. Mueva el pin hasta su '
      'terreno.';
  static String avisoOtroMunicipio(String municipio) =>
      'Ese punto queda en $municipio. Lo cambiamos por usted.';
  static const String errorArea = 'Escriba un número mayor que cero.';
  static const String errorElijaMunicipio = 'Elija el municipio.';
  static const String errorElijaCultivo =
      'Elija lo que siembra, o "Todavía no he sembrado".';
  static const String errorElijaEtapa = 'Elija cómo va el cultivo.';
  static const String errorMuevaPin =
      'Mueva el pin hasta su terreno, busque el lugar o use su ubicación.';
  static const String errorAltura = 'Escriba la altura en números.';
  static const String sinPermisoUbicacion =
      'Sin permiso de ubicación no podemos saber dónde está. Puede mover el pin '
      'en el mapa.';
  static const String ubicacionApagada =
      'La ubicación del teléfono está apagada. Enciéndala o mueva el pin.';
  static const String sinUbicacion =
      'No pudimos saber dónde está. Mueva el pin en el mapa.';
  static const String registrarParcela = 'Registrar mi parcela';

  // ---------- Mis parcelas (pantallas 14–16, HU-06) ----------
  static const String misParcelas = 'Mis parcelas';
  static String terrenosRegistrados(int cantidad) =>
      cantidad == 1 ? '1 terreno registrado' : '$cantidad terrenos registrados';
  static const String agregarParcela = 'Agregar parcela';
  static const String vacioParcelasTitulo =
      'Todavía no ha registrado su parcela';
  static const String vacioParcelasDetalle =
      'Marque su terreno en el mapa y empiece a recibir el clima y los avisos.';
  static const String errorParcelasTitulo = 'No pudimos traer sus parcelas';
  static const String errorParcelasDetalle =
      'Puede ser la señal. Intente otra vez en un momento.';
  static const String editar = 'Editar';
  static const String borrar = 'Borrar';
  static String accionesDeParcela(String nombre) =>
      '$nombre. Deslice a la izquierda para editar o borrar.';
  static const String editarParcela = 'Editar parcela';
  static const String guardarCambios = 'Guardar cambios';
  static const String cambiosGuardados = 'Cambios guardados.';
  static const String etiquetaCultivoFase = 'Cultivo y fase';
  static const String borrarParcela = 'Borrar parcela';
  static const String borrandoParcela = 'Borrando…';
  static String preguntaBorrar(String nombre) => '¿Borrar $nombre?';
  static const String detalleBorrar =
      'Se pierde su historial de clima y ya no recibirá avisos de este '
      'terreno.';
  static const String siBorrar = 'Sí, borrar';
  static const String noQuedarme = 'No, quedarme';
  static const String parcelaBorrada = 'Se borró la parcela.';
  static const String borradaSinSenal =
      'Borrada en su teléfono. Se terminará de borrar cuando haya señal.';
  static const String parcelaNoExiste = 'Esa parcela ya no existe.';

  // ---------- Sesión ----------
  static const String cerrarSesion = 'Cerrar sesión';
  static const String cerrandoSesion = 'Cerrando sesión…';
  static const String enviandoEnlace = 'Enviando…';
}

import 'package:intl/intl.dart';

import '../modelos/alerta.dart';
import '../modelos/capa_clima.dart';
import '../modelos/enums.dart';
import '../modelos/error_clima.dart';

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

  // ---------- Panel principal (pantallas 17, 18, 32–34; HU-07) ----------
  /// Frase llana para el código de condición del proveedor.
  static String fraseClima(int codigo, {required bool esDeDia}) =>
      switch (codigo) {
        >= 200 && < 300 => 'Tormenta',
        >= 300 && < 400 => 'Llovizna',
        500 => 'Lluvia ligera',
        501 => 'Lluvia',
        >= 502 && < 505 => 'Lluvia fuerte',
        >= 520 && < 600 => 'Aguaceros',
        >= 500 && < 600 => 'Lluvia',
        >= 600 && < 700 => 'Granizo o nieve',
        >= 700 && < 800 => 'Neblina',
        800 => esDeDia ? 'Soleado' : 'Despejado',
        801 => 'Poco nublado',
        802 => 'Medio nublado',
        _ => 'Nublado',
      };

  /// Rumbo del viento en 8 direcciones (de dónde viene).
  static String rumbo(double grados) {
    const rumbos = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
    return rumbos[((grados % 360) / 45).round() % 8];
  }

  static String grados(double valor) => '${valor.round()}°';
  static const String seSiente = 'Se siente';
  static const String maxima = 'Máx';
  static const String minima = 'Mín';
  static const String humedad = 'Humedad';
  static const String vientoKmH = 'Viento km/h';
  static const String vaALlover = 'Va a llover';
  static const String llovioHoy = 'Llovió hoy';
  static const String saleElSol = 'Sale el sol';
  static const String seOcultaElSol = 'Se oculta';
  static const String sinDatoCorto = '—';
  static String milimetros(double mm) =>
      '${mm < 10 ? mm.toStringAsFixed(mm == mm.roundToDouble() ? 0 : 1) : mm.round()} mm';
  static String porcentaje(double fraccion) => '${(fraccion * 100).round()}%';
  static String horaCorta(DateTime local) {
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m ${local.hour < 12 ? 'a.m.' : 'p.m.'}';
  }

  /// "12 de agosto, 6:00 a.m." (hora de pared de Guatemala).
  static String fechaYHora(DateTime local) =>
      '${DateFormat("d 'de' MMMM", 'es').format(local)}, ${horaCorta(local)}';

  static String actualizadoHace(Duration tiempo) {
    final minutos = tiempo.inMinutes;
    final cuando = switch (minutos) {
      < 1 => 'hace un momento',
      1 => 'hace 1 minuto',
      < 60 => 'hace $minutos minutos',
      < 120 => 'hace 1 hora',
      < 1440 => 'hace ${tiempo.inHours} horas',
      _ => 'hace ${tiempo.inDays} ${tiempo.inDays == 1 ? 'día' : 'días'}',
    };
    return 'Datos de OpenWeather · actualizado $cuando';
  }

  static const String deslizaParaActualizar =
      'Deslice hacia abajo para actualizar';
  static const String elegirParcela = 'Elegir parcela';
  static const String verMisParcelas = 'Ver mis parcelas';
  static const String sinDatosClimaTitulo =
      'Todavía no hay datos de esta parcela';
  static const String noSeActualizoTitulo = 'No pudimos actualizar';

  /// Causa probable en lenguaje llano (pantalla 34).
  static String causaErrorClima(MotivoErrorClima motivo) => switch (motivo) {
    MotivoErrorClima.sinConexion => 'No hay internet en este momento.',
    MotivoErrorClima.tiempoAgotado =>
      'La señal está muy débil. Intente otra vez en un momento.',
    MotivoErrorClima.limiteAlcanzado || MotivoErrorClima.servicioCaido =>
      'El servicio del clima está ocupado. Intente otra vez en un rato.',
    MotivoErrorClima.claveInvalida || MotivoErrorClima.respuestaInvalida =>
      'El servicio del clima no respondió bien. Intente más tarde.',
  };

  // ---------- Pronóstico (panel y pantalla 19, HU-08) ----------
  static const String horaPorHora = 'Hora por hora';
  static String proximosDias(int cantidad) => 'Los próximos $cantidad días';
  static const String ahora = 'Ahora';
  static const String hoy = 'Hoy';
  static const String pronosticoDetallado = 'Pronóstico detallado';
  static const String verDetalle = 'Ver el detalle';

  /// "8 a.m.", "12 p.m.".
  static String horaSinMinutos(DateTime local) {
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    return '$h ${local.hour < 12 ? 'a.m.' : 'p.m.'}';
  }

  /// "Miércoles".
  static String nombreDia(DateTime dia) {
    final nombre = DateFormat('EEEE', 'es').format(dia);
    return nombre[0].toUpperCase() + nombre.substring(1);
  }

  /// "13 ago".
  static String diaCorto(DateTime dia) =>
      DateFormat('d MMM', 'es').format(dia).replaceAll('.', '');

  static const String comoCambiaTemperatura = 'Cómo cambia la temperatura';

  /// "a las 5 de la mañana", "a la 1 de la tarde", "a las 12 del mediodía".
  static String aLaHora(DateTime local) {
    final hora = local.hour;
    if (hora == 0) return 'a la medianoche';
    if (hora == 12) return 'a las 12 del mediodía';
    final h = hora % 12;
    final parte = switch (hora) {
      < 12 => 'de la mañana',
      < 19 => 'de la tarde',
      _ => 'de la noche',
    };
    return '${h == 1 ? 'a la' : 'a las'} $h $parte';
  }

  static String loMasFrio(DateTime local) =>
      'Lo más frío será ${aLaHora(local)}';
  static const String cuantaLluvia = 'Cuánta lluvia caerá';

  /// Interpreta la intensidad en mm/h (plans/03 §6).
  static String intensidadLluvia(double mmHora) => switch (mmHora) {
    < 2.5 => 'lluvia ligera',
    <= 15 => 'lluvia moderada',
    _ => 'lluvia fuerte',
  };

  static String totalEsperado({
    required bool esHoy,
    required double mm,
    required double mmHora,
  }) => mm < 0.1
      ? 'No se espera lluvia ${esHoy ? 'hoy' : 'ese día'}'
      : 'Total esperado ${esHoy ? 'hoy' : 'ese día'}: ${milimetros(mm)} — ${intensidadLluvia(mmHora)}';

  static const String madrugada = 'madrugada';
  static const String manana = 'mañana';
  static const String tarde = 'tarde';
  static const String noche = 'noche';
  static const String vientoMasFuerte = 'Viento más fuerte';
  static const String humedadDelAire = 'Humedad del aire';
  static const String saleYSePone = 'Sale y se pone el sol';
  static String kmPorHora(double valor) => '${valor.round()} km/h';

  // ---------- Sesión ----------
  static const String cerrarSesion = 'Cerrar sesión';
  static const String cerrandoSesion = 'Cerrando sesión…';
  static const String enviandoEnlace = 'Enviando…';

  // ---------- Avisos (HU-10): canales de Android ----------
  // El teléfono los muestra en Ajustes → Notificaciones de la app.
  static const String canalPeligro = 'Avisos de PELIGRO';
  static const String canalPeligroDetalle =
      'Riesgos graves para sus parcelas. Suenan aunque sea de noche.';
  static const String canalPrecaucion = 'Avisos de PRECAUCIÓN';
  static const String canalPrecaucionDetalle =
      'Riesgos que conviene atender pronto.';
  static const String canalNormal = 'Avisos normales';
  static const String canalNormalDetalle =
      'Información del clima de sus parcelas.';

  // ---------- Centro y detalle de alertas (pantallas 21, 22 y 35, HU-11) ----------
  static const String avisos = 'Avisos';
  static const String activos = 'Activos';
  static const String anteriores = 'Anteriores';
  static String sinLeer(int n) =>
      n == 1 ? '1 aviso sin ver' : '$n avisos sin ver';
  static const String nuevo = 'Nuevo';
  static const String todoTranquilo = 'Todo tranquilo';
  static const String todoTranquiloDetalle =
      'No hay peligro para sus parcelas en los próximos días. Le avisamos si '
      'algo cambia.';
  static const String sinAnteriores = 'Todavía no hay avisos anteriores';
  static const String sinAnterioresDetalle =
      'Aquí quedan los avisos de días que ya pasaron.';
  static const String alertaNoEsta = 'Este aviso ya no está';
  static const String alertaNoEstaDetalle =
      'Puede que la parcela se haya borrado. Vea sus otros avisos.';
  static const String verAvisos = 'Ver mis avisos';
  static const String porQueAvisamos = 'Por qué le avisamos';
  static const String quePuedeHacer = 'Qué puede hacer hoy';
  static const String yaTomeMedidas = 'Ya tomé medidas';
  static const String yaTomoMedidas = 'Ya tomó medidas';
  static const String todas = 'Todas';
  static const String verMasAvisos = 'Ver más avisos';
  static const String buscandoMasAvisos = 'Buscando avisos…';
  static const String avisarWhatsApp = 'Avisar por WhatsApp';

  /// Riesgo en pocas palabras: "Puede caer helada", "Viento fuerte".
  static String tituloAlerta(Alerta a) => a.esHelada
      ? 'Puede caer helada'
      : switch (a.tipoRiesgo) {
          TipoRiesgo.lluviaIntensa => 'Lluvia fuerte',
          TipoRiesgo.vientoFuerte => 'Viento fuerte',
          TipoRiesgo.sequia => 'Días sin lluvia',
          TipoRiesgo.temperaturaBaja => 'Frío',
          TipoRiesgo.temperaturaAlta => 'Mucho calor',
          TipoRiesgo.humedadAlta => 'Mucha humedad',
        };

  /// "La Joya · Café" (tarjeta) o "La Joya · Café floreando" (detalle).
  static String parcelaYCultivo(String parcela, Cultivo? c, [Etapa? e]) {
    if (c == null) return parcela;
    final etapaTexto = e == null ? '' : ' ${etapa(e).toLowerCase()}';
    return '$parcela · ${cultivo(c)}$etapaTexto';
  }

  /// Cuándo pasa, en lenguaje hablado: "Mañana en la madrugada", "Hoy",
  /// "El jueves por la tarde", "A partir del viernes". La alerta es por día
  /// (D-48): la parte del día sale del tipo de riesgo (el frío es de
  /// madrugada y el calor de tarde).
  static String cuandoAlerta(Alerta a, DateTime ahora) {
    final evento = _diaRelativo(a.fechaEvento, ahora);
    if (a.tipoRiesgo == TipoRiesgo.sequia) {
      return evento.pasado
          ? 'Desde el ${evento.fecha}'
          : 'A partir ${evento.desde}';
    }
    final parte = switch (a.tipoRiesgo) {
      TipoRiesgo.temperaturaBaja => ' en la madrugada',
      TipoRiesgo.temperaturaAlta => ' por la tarde',
      _ => '',
    };
    final seguidos = (a.diasConsecutivos ?? 1) > 1
        ? ' · ${a.diasConsecutivos} días seguidos'
        : '';
    return '${_mayuscula(evento.texto)}$parte$seguidos';
  }

  /// Día del evento respecto de hoy, en hora de Guatemala.
  static ({String texto, String desde, String fecha, bool pasado}) _diaRelativo(
    DateTime fechaEvento,
    DateTime ahora,
  ) {
    final local = fechaEvento.toUtc().add(const Duration(hours: -6));
    final dia = DateTime.utc(local.year, local.month, local.day);
    final ahoraLocal = ahora.toUtc().add(const Duration(hours: -6));
    final hoy = DateTime.utc(ahoraLocal.year, ahoraLocal.month, ahoraLocal.day);
    final diferencia = dia.difference(hoy).inDays;
    final semana = DateFormat('EEEE', 'es').format(dia);
    final fecha = '$semana ${DateFormat("d 'de' MMMM", 'es').format(dia)}';
    return switch (diferencia) {
      0 => (texto: 'hoy', desde: 'de hoy', fecha: fecha, pasado: false),
      1 => (texto: 'mañana', desde: 'de mañana', fecha: fecha, pasado: false),
      > 1 && < 7 => (
        texto: 'el $semana',
        desde: 'del $semana',
        fecha: fecha,
        pasado: false,
      ),
      _ => (
        texto: 'el $fecha',
        desde: 'del $fecha',
        fecha: fecha,
        pasado: diferencia < 0,
      ),
    };
  }

  static String _mayuscula(String texto) =>
      texto.isEmpty ? texto : texto[0].toUpperCase() + texto.substring(1);

  /// Valor con su unidad: "2 °C", "20 mm por hora", "7 días".
  static String valorAlerta(TipoRiesgo tipo, double valor) {
    final n = valor.round();
    return switch (tipo) {
      TipoRiesgo.temperaturaBaja || TipoRiesgo.temperaturaAlta => '$n °C',
      TipoRiesgo.lluviaIntensa => '$n mm por hora',
      TipoRiesgo.vientoFuerte => '$n km/h',
      TipoRiesgo.humedadAlta => '$n %',
      TipoRiesgo.sequia => n == 1 ? '1 día' : '$n días',
    };
  }

  static String seEspera(TipoRiesgo tipo) =>
      tipo == TipoRiesgo.sequia ? 'Se esperan' : 'Se espera';

  /// "El café aguanta hasta" (D-14: el valor es el del umbral real).
  static String aguanta(Cultivo? c, TipoRiesgo tipo) {
    final hasta = tipo == TipoRiesgo.sequia ? '' : ' hasta';
    return switch (c) {
      Cultivo.maiz => 'El maíz aguanta$hasta',
      Cultivo.frijol => 'El frijol aguanta$hasta',
      Cultivo.cafe => 'El café aguanta$hasta',
      Cultivo.hortalizas => 'Las hortalizas aguantan$hasta',
      null => 'Lo seguro es$hasta',
    };
  }

  /// Frase de la comparación: "Va a estar 2 grados más frío de lo que
  /// aguanta su cultivo."
  static String diferenciaAlerta(Alerta a) {
    final limite = a.cultivo == null
        ? 'de lo seguro'
        : 'de lo que aguanta su cultivo';
    final d = (a.valorEsperado - a.valorUmbral).abs().round();
    if (d == 0) return 'Va a llegar al límite $limite.';
    final grados = d == 1 ? 'grado' : 'grados';
    return switch (a.tipoRiesgo) {
      TipoRiesgo.temperaturaBaja => 'Va a estar $d $grados más frío $limite.',
      TipoRiesgo.temperaturaAlta =>
        'Va a estar $d $grados más caliente $limite.',
      TipoRiesgo.lluviaIntensa => 'Va a llover $d mm por hora más $limite.',
      TipoRiesgo.vientoFuerte => 'El viento va a soplar $d km/h más $limite.',
      TipoRiesgo.humedadAlta => 'La humedad va a estar $d % más alta $limite.',
      TipoRiesgo.sequia =>
        'Van a ser $d ${d == 1 ? 'día' : 'días'} más sin lluvia $limite.',
    };
  }

  /// Texto para compartir por WhatsApp (RN-07: información de apoyo). El
  /// mensaje ya dice cuándo pasa.
  static String textoCompartir(Alerta a) =>
      '${palabraNivel(a.nivel)}: ${tituloAlerta(a).toLowerCase()} en '
      '${a.parcelaNombre}. ${a.mensaje}\n\n'
      'Aviso de $nombreApp. $avisoApoyo';

  /// Lectura de la tarjeta para TalkBack.
  static String lecturaTarjetaAlerta(Alerta a, DateTime ahora) =>
      '${palabraNivel(a.nivel)}. ${tituloAlerta(a)}. '
      '${parcelaYCultivo(a.parcelaNombre, a.cultivo)}. '
      '${cuandoAlerta(a, ahora)}.${a.atendida ? ' $yaTomoMedidas.' : ''}'
      '${a.leida ? '' : ' $nuevo.'}';

  // ---------- Mapa del clima (pantalla 20, HU-09) ----------
  static const String mapaClima = 'Mapa del clima';
  static const String departamentoJalapa = 'Departamento de Jalapa';
  static const String miParcela = 'Mi parcela';
  static const String queSignificanColores = 'Qué significan los colores';
  static const String verMasClaro = 'Ver más claro';
  static const String elijaCapa =
      'Toque Lluvia, Nubes, Calor o Viento para verlo sobre el mapa.';
  static const String errorCapa =
      'No pudimos traer esa capa. El mapa sigue funcionando.';
  static const String sinInternetMapa =
      'Sin internet el mapa y las capas no se pueden cargar.';
  static const String fuenteMapaClima =
      'Mapa: Esri y colaboradores · Clima: OpenWeather';

  static String nombreCapa(CapaClima capa) => switch (capa) {
    CapaClima.lluvia => 'Lluvia',
    CapaClima.nubes => 'Nubes',
    CapaClima.calor => 'Calor',
    CapaClima.viento => 'Viento',
  };

  /// Extremos de la leyenda: (poco, mucho).
  static (String, String) extremosCapa(CapaClima capa) => switch (capa) {
    CapaClima.lluvia => ('Poca lluvia', 'Lluvia fuerte'),
    CapaClima.nubes => ('Pocas nubes', 'Muy nublado'),
    CapaClima.calor => ('Frío', 'Calor'),
    CapaClima.viento => ('Poco viento', 'Viento fuerte'),
  };

  // ---------- Mis avisos (pantalla 23, HU-12) ----------
  static const String misAvisos = 'Mis avisos';
  static const String deQueAvisamos = '¿De qué le avisamos?';
  static const String avisarmeDesde = 'Avisarme desde';
  static const String noSonarDeNoche = 'No sonar de noche';
  static const String peligroSiSuena = 'Los avisos de PELIGRO sí suenan';
  static const String aunqueApague =
      'Aunque apague un aviso, lo verá en Alertas.';
  static const String loQueAguanta = 'Lo que aguanta su cultivo';
  static const String loQueAguantaDetalle =
      'Son los límites con que le avisamos. Vienen de estudios para cada '
      'cultivo.';
  static const String sinCultivoAguanta = 'Parcelas sin cultivo';

  /// Nombre de cada tipo en el interruptor.
  static String tipoAviso(TipoRiesgo tipo) => switch (tipo) {
    TipoRiesgo.temperaturaBaja => 'Frío y helada',
    TipoRiesgo.lluviaIntensa => 'Lluvia fuerte',
    TipoRiesgo.sequia => 'Días sin lluvia',
    TipoRiesgo.vientoFuerte => 'Viento fuerte',
    TipoRiesgo.temperaturaAlta => 'Mucho calor',
    TipoRiesgo.humedadAlta => 'Mucha humedad',
  };

  /// Opciones de "Avisarme desde".
  static String nivelMinimo(NivelSeveridad nivel) => switch (nivel) {
    NivelSeveridad.informativa => 'Todo',
    NivelSeveridad.preventiva => 'Precaución',
    NivelSeveridad.critica => 'Solo peligro',
  };

  /// "De 10:00 p.m. a 5:00 a.m." (horas `HH:mm` de la base).
  static String horarioSilencio(String desde, String hasta) =>
      'De ${_horaDe(desde)} a ${_horaDe(hasta)}';

  static String _horaDe(String hhmm) {
    final partes = hhmm.split(':');
    final hora = int.tryParse(partes.first) ?? 0;
    final minutos = partes.length > 1 ? partes[1] : '00';
    final h = hora % 12 == 0 ? 12 : hora % 12;
    return '$h:$minutos ${hora < 12 ? 'a.m.' : 'p.m.'}';
  }
}

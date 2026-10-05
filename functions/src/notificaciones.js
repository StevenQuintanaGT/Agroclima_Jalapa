'use strict';

/**
 * Envío de avisos por FCM (CO-13, HU-10; UMBRALES.md §6). Corre en la misma
 * vuelta del ciclo que detectó el riesgo (RNF-10).
 *
 * Se avisa si el tipo de riesgo está activo, el nivel llega al mínimo elegido
 * y no es horario de silencio; PELIGRO suena aunque sea horario de silencio.
 * Si no se avisa, la alerta igual queda en la app con `notificada: false`.
 *
 * Varios días seguidos del mismo riesgo y nivel en una parcela (por ejemplo,
 * tres días de calor) se avisan con UNA notificación, la del primer día
 * (DECISIONES D-47). Las alertas de cada día quedan en el centro de alertas.
 */
const { FieldValue } = require('firebase-admin/firestore');
const { diaAnterior, horaLocal } = require('./fechas');
const { rangoNivel } = require('./motor/comparar');

/** Canales Android por nivel (los crea la app: NotificacionesServicio). */
const CANAL = Object.freeze({
  critica: 'alertas_peligro',
  preventiva: 'alertas_precaucion',
  informativa: 'alertas_normal',
});
const COLOR = Object.freeze({ critica: '#B3261E', preventiva: '#B26A00', informativa: '#2E7D32' });

/** Valores por defecto de `preferencias/{tipoRiesgo}` (Tabla 65). */
const PREFERENCIA_POR_DEFECTO = Object.freeze({
  activa: true,
  nivelMinimo: 'preventiva',
  silencioDesde: '22:00',
  silencioHasta: '05:00',
});

// Errores de FCM que significan que el token ya no sirve y hay que quitarlo.
const TOKEN_INVALIDO = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/** ¿La hora "HH:mm" cae en el silencio? El rango puede cruzar la medianoche. */
function enSilencio(hora, desde, hasta) {
  if (!desde || !hasta || desde === hasta) return false;
  return desde < hasta ? hora >= desde && hora < hasta : hora >= desde || hora < hasta;
}

/** ¿Esta alerta se avisa con las preferencias del usuario? */
function debeAvisar(alerta, preferencia, hora) {
  const { activa, nivelMinimo, silencioDesde, silencioHasta } = { ...PREFERENCIA_POR_DEFECTO, ...preferencia };
  if (!activa) return false;
  if (rangoNivel(alerta.nivel) < rangoNivel(nivelMinimo)) return false;
  return alerta.nivel === 'critica' || !enSilencio(hora, silencioDesde, silencioHasta);
}

/** Agrupa días seguidos del mismo riesgo y nivel en una parcela. */
function agruparSeguidas(alertas) {
  const ordenadas = [...alertas].sort(
    (a, b) =>
      `${a.parcelaId}|${a.tipoRiesgo}|${a.nivel}`.localeCompare(`${b.parcelaId}|${b.tipoRiesgo}|${b.nivel}`) ||
      a.fechaEventoId.localeCompare(b.fechaEventoId),
  );
  const grupos = [];
  for (const alerta of ordenadas) {
    const ultimo = grupos[grupos.length - 1]?.at(-1);
    const sigue =
      ultimo &&
      ultimo.parcelaId === alerta.parcelaId &&
      ultimo.tipoRiesgo === alerta.tipoRiesgo &&
      ultimo.nivel === alerta.nivel &&
      diaAnterior(alerta.fechaEventoId) === ultimo.fechaEventoId;
    if (sigue) grupos[grupos.length - 1].push(alerta);
    else grupos.push([alerta]);
  }
  return grupos;
}

function mensajeFcm(alerta, tokens) {
  return {
    tokens,
    notification: { title: alerta.titulo, body: alerta.mensaje },
    data: { alertaId: alerta.alertaId, parcelaId: alerta.parcelaId, nivel: alerta.nivel },
    android: {
      priority: alerta.nivel === 'critica' ? 'high' : 'normal',
      notification: { channelId: CANAL[alerta.nivel], color: COLOR[alerta.nivel], tag: alerta.alertaId },
    },
  };
}

/**
 * @param {object} opciones
 * @param {import('firebase-admin/firestore').Firestore} opciones.db
 * @param {{sendEachForMulticast: Function}} opciones.mensajeria getMessaging(app)
 * @param {Array<object>} opciones.alertas resultado de generarAlertas
 * @param {Date} [opciones.ahora]
 * @param {(mensaje: string) => void} [opciones.registrar]
 */
async function enviarAvisos({ db, mensajeria, alertas, ahora = new Date(), registrar = console.log }) {
  const resumen = { enviadas: 0, sinAviso: 0, fallidas: 0, tokensQuitados: 0 };
  const hora = horaLocal(ahora);
  const porUsuario = new Map();
  for (const alerta of alertas) {
    if (!porUsuario.has(alerta.usuarioId)) porUsuario.set(alerta.usuarioId, []);
    porUsuario.get(alerta.usuarioId).push(alerta);
  }

  for (const [usuarioId, propias] of porUsuario) {
    const perfil = db.collection('usuarios').doc(usuarioId);
    const [usuario, preferencias] = await Promise.all([perfil.get(), perfil.collection('preferencias').get()]);
    let tokens = [...new Set(usuario.get('tokensFcm') ?? [])];
    const prefPorTipo = new Map(preferencias.docs.map((doc) => [doc.id, doc.data()]));
    const invalidos = new Set();

    for (const grupo of agruparSeguidas(propias)) {
      const primera = grupo[0];
      if (tokens.length === 0 || !debeAvisar(primera, prefPorTipo.get(primera.tipoRiesgo), hora)) {
        resumen.sinAviso += grupo.length;
        continue;
      }
      let respuesta;
      try {
        respuesta = await mensajeria.sendEachForMulticast(mensajeFcm(primera, tokens));
      } catch (error) {
        // FCM caído: la alerta queda en la app sin aviso (RT-05).
        resumen.fallidas += grupo.length;
        registrar(`Aviso de ${primera.alertaId} no enviado: ${error.message}`);
        continue;
      }
      respuesta.responses.forEach((r, i) => {
        if (!r.success && TOKEN_INVALIDO.has(r.error?.code)) invalidos.add(tokens[i]);
      });
      tokens = tokens.filter((t) => !invalidos.has(t));
      if (respuesta.successCount > 0) {
        resumen.enviadas += grupo.length;
        const lote = db.batch();
        for (const alerta of grupo) lote.update(db.collection('alertas').doc(alerta.alertaId), { notificada: true });
        await lote.commit();
      } else {
        resumen.fallidas += grupo.length;
      }
    }

    if (invalidos.size > 0) {
      await perfil.update({ tokensFcm: FieldValue.arrayRemove(...invalidos) });
      resumen.tokensQuitados += invalidos.size;
    }
  }
  registrar(
    `Avisos: ${resumen.enviadas} alertas avisadas, ${resumen.sinAviso} sin aviso por preferencias, ` +
      `${resumen.fallidas} fallidas, ${resumen.tokensQuitados} tokens quitados.`,
  );
  return resumen;
}

module.exports = { enviarAvisos, enSilencio, debeAvisar, agruparSeguidas, CANAL };

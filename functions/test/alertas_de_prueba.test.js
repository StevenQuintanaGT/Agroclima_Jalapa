'use strict';

const { riesgosDePrueba } = require('../scripts/alertas-de-prueba');
const { textosAlerta } = require('../src/mensajes');
const { mensajeFcm } = require('../src/notificaciones');

// Lunes 12 de octubre de 2026, 9 p. m. en Guatemala.
const AHORA = new Date('2026-10-13T03:00:00Z');
const parcela = { id: 'p1', get: (campo) => ({ nombre: 'El Chilamatal', cultivo: 'maiz' })[campo] };

test('helada (PELIGRO) mañana y lluvia fuerte (PRECAUCIÓN) pasado mañana', () => {
  const [helada, lluvia] = riesgosDePrueba(parcela, 'u1', AHORA);
  expect(helada).toMatchObject({ tipoRiesgo: 'temperaturaBaja', nivel: 'critica', fechaEvento: '20261013' });
  expect(lluvia).toMatchObject({ tipoRiesgo: 'lluviaIntensa', nivel: 'preventiva', fechaEvento: '20261014' });
  expect(textosAlerta(helada, AHORA).titulo).toBe('PELIGRO: puede caer helada en El Chilamatal');
  expect(textosAlerta(lluvia, AHORA).mensaje).toMatch(/^El miércoles se esperan hasta 22 mm de lluvia por hora\./);
});

test('el aviso de PELIGRO va por su canal y con prioridad alta', () => {
  const mensaje = mensajeFcm(
    { alertaId: 'a1', parcelaId: 'p1', nivel: 'critica', titulo: 'Prueba · PELIGRO', mensaje: 'x' },
    ['t1'],
  );
  expect(mensaje.android).toMatchObject({ priority: 'high', notification: { channelId: 'alertas_peligro' } });
  expect(mensaje.notification.title).toBe('Prueba · PELIGRO');
});

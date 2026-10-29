'use strict';

const { encuestasACsv, ENCABEZADO } = require('../src/encuestas_csv');

const completa = {
  uid: 'secreto-uid',
  p1: 'facil',
  p2: 'mayoria',
  p3: 'si',
  detalleAviso: 'Helada, "la del martes"',
  p4: 'mucho',
  p5: 'si',
  detalleAccion: 'Tapé el almácigo',
  p6: 'sinDanio',
  p7: 'talVez',
  p8: 'Que avise\npor mensaje',
  consentimiento: true,
  municipio: 'monjas',
  cultivo: 'cafe',
  versionApp: '1.1.0',
  fechaRespuesta: new Date('2026-10-29T20:05:00Z'),
};

const filas = (csv) => csv.replace(/^﻿/, '').trimEnd().split('\r\n');

describe('encuestasACsv', () => {
  test('encabezado y una fila con etiquetas en español y hora de Guatemala', () => {
    const csv = encuestasACsv([{ datos: completa, nombre: 'Ana Pérez', correo: 'ana@x.com' }]);
    expect(csv.startsWith('﻿')).toBe(true);
    const [encabezado] = filas(csv);
    expect(encabezado).toBe(ENCABEZADO.join(','));
    expect(csv).toContain('Ana Pérez,Monjas,Café,Fácil,La mayoría,Sí,"Helada, ""la del martes""",Mucho,Sí');
    expect(csv).toContain('Todavía no ha habido daño,,Tal vez,"Que avise\npor mensaje",Sí,1.1.0,2026-10-29 14:05');
  });

  test('nunca incluye correo ni uid', () => {
    const csv = encuestasACsv([{ datos: { ...completa, correo: 'ana@x.com' }, nombre: 'Ana' }]);
    expect(csv).not.toContain('secreto-uid');
    expect(csv).not.toContain('ana@x.com');
    expect(ENCABEZADO).not.toContain('uid');
    expect(ENCABEZADO).not.toContain('correo');
  });

  test('sin permiso no sale el nombre', () => {
    const csv = encuestasACsv([{ datos: { ...completa, consentimiento: false }, nombre: 'Ana' }]);
    const [, fila] = filas(csv);
    expect(fila.startsWith('(sin permiso),')).toBe(true);
    expect(csv).not.toContain('Ana');
    expect(fila).toContain(',No,1.1.0,');
  });

  test('campos que faltan quedan vacíos', () => {
    const csv = encuestasACsv([{ datos: { uid: 'x', p1: 'dificil', consentimiento: true } }]);
    const [, fila] = filas(csv);
    expect(fila.split(',')).toHaveLength(ENCABEZADO.length);
    expect(fila).toBe(',,,Difícil,,,,,,,,,,,Sí,,');
  });
});

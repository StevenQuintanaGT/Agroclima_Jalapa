'use strict';

const catalogoSemilla = require('../seed/umbrales.json');
const { aplicables } = require('../src/umbrales');

const catalogo = catalogoSemilla.map((u) => ({ cultivo: '', etapa: '', duracionDias: 1, ...u }));
const ids = (lista) => lista.map((u) => u.umbralId).sort();

describe('umbrales que aplican a una parcela (UMBRALES.md §3)', () => {
  const generales = ids(catalogo.filter((u) => u.cultivo === ''));

  test('sin cultivo: solo los generales (RN-05)', () => {
    expect(ids(aplicables(catalogo, { cultivo: '', etapa: '' }))).toEqual(generales);
  });

  test('hortalizas: solo los generales', () => {
    expect(ids(aplicables(catalogo, { cultivo: 'hortalizas', etapa: 'floracion' }))).toEqual(
      generales,
    );
  });

  test('café: generales más los de café sin etapa', () => {
    const lista = ids(aplicables(catalogo, { cultivo: 'cafe', etapa: 'cosecha' }));
    expect(lista).toEqual(
      [
        ...generales,
        'tmin_cafe_preventiva',
        'tmax_cafe_preventiva',
        'tmax_cafe_critica',
        'humedad_cafe_preventiva',
      ].sort(),
    );
  });

  test('maíz en floración: incluye su sequía y su calor, no los de otra etapa', () => {
    const lista = ids(aplicables(catalogo, { cultivo: 'maiz', etapa: 'floracion' }));
    expect(lista).toContain('sequia_maiz_floracion_preventiva');
    expect(lista).toContain('tmax_maiz_floracion_critica');
    expect(lista).not.toContain('tmax_maiz_vegetativo_preventiva');
    expect(lista).not.toContain('tmax_maiz_llenado_critica');
  });

  test('frijol en llenado: su sequía de llenado, no la de floración', () => {
    const lista = ids(aplicables(catalogo, { cultivo: 'frijol', etapa: 'llenado' }));
    expect(lista).toContain('sequia_frijol_llenado_critica');
    expect(lista).not.toContain('sequia_frijol_floracion_critica');
    expect(lista).toContain('tmin_frijol_preventiva');
  });

  test('un umbral no vigente nunca aplica', () => {
    const conApagado = catalogo.map((u) =>
      u.umbralId === 'lluvia_general_preventiva' ? { ...u, vigente: false } : u,
    );
    expect(ids(aplicables(conApagado, { cultivo: '' }))).not.toContain(
      'lluvia_general_preventiva',
    );
  });
});

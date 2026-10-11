'use strict';

const { extremosDelDia } = require('../src/adquisicion');

describe('mínima y máxima del día (HU-13, D-53)', () => {
  test('el primer dato del día es mínima y máxima', () => {
    expect(extremosDelDia({}, 18.5)).toEqual({ temperaturaMinima: 18.5, temperaturaMaxima: 18.5 });
  });

  test('se amplían con cada observación nueva', () => {
    const guardado = { temperaturaMinima: 14, temperaturaMaxima: 24, temperatura: 20 };
    expect(extremosDelDia(guardado, 26)).toEqual({ temperaturaMinima: 14, temperaturaMaxima: 26 });
    expect(extremosDelDia(guardado, 11)).toEqual({ temperaturaMinima: 11, temperaturaMaxima: 24 });
  });

  test('cuenta la temperatura que registró una consulta de la app', () => {
    expect(extremosDelDia({ temperatura: 9 }, 15)).toEqual({ temperaturaMinima: 9, temperaturaMaxima: 15 });
  });

  test('ignora valores que no son números', () => {
    expect(extremosDelDia({ temperaturaMinima: null, temperatura: 'x' }, 20)).toEqual({
      temperaturaMinima: 20,
      temperaturaMaxima: 20,
    });
  });
});

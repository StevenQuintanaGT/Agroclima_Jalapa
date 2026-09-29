'use strict';

const umbrales = require('../seed/umbrales.json');
const { validarUmbral, validarCatalogo } = require('../src/umbrales_semilla');

describe('Semilla de umbrales (Tabla 31)', () => {
  test('el catálogo cumple la Tabla 70 y no repite ids', () => {
    expect(validarCatalogo(umbrales)).toEqual([]);
  });

  test('trae los 24 umbrales de UMBRALES.md', () => {
    expect(umbrales).toHaveLength(24);
  });

  test('la helada general es crítica a 0 °C o menos', () => {
    const helada = umbrales.find((u) => u.umbralId === 'tmin_general_critica');
    expect(helada).toMatchObject({
      variable: 'temperaturaMinima',
      operador: 'menorIgual',
      valor: 0,
      nivel: 'critica',
      cultivo: '',
    });
  });

  test('el calor crítico en café exige 3 días seguidos', () => {
    const calor = umbrales.find((u) => u.umbralId === 'tmax_cafe_critica');
    expect(calor.duracionDias).toBe(3);
  });
});

describe('validarUmbral', () => {
  const valido = {
    umbralId: 'x',
    tipoRiesgo: 'lluviaIntensa',
    variable: 'precipitacionHora',
    operador: 'mayor',
    valor: 15,
    nivel: 'preventiva',
    fuente: 'Monjo (2010)',
    vigente: true,
  };

  test('acepta un umbral correcto', () => {
    expect(validarUmbral(valido)).toEqual([]);
  });

  test('rechaza valores fuera de las enumeraciones', () => {
    expect(validarUmbral({ ...valido, nivel: 'alta' })).toContain(
      'nivel inválido: alta',
    );
    expect(validarUmbral({ ...valido, cultivo: 'frutales' })).toContain(
      'cultivo inválido: frutales',
    );
  });

  test('rechaza duración no entera', () => {
    expect(validarUmbral({ ...valido, duracionDias: 0 })).toContain(
      'duracionDias debe ser entero ≥ 1',
    );
  });
});

'use strict';

const { contarFranjasTerminadas, preverFranjas } = require('../src/lluvia_del_dia');
const { idDiario } = require('../src/fechas');

// Inicios de franja (segundos UTC) del 3 de octubre en hora de Guatemala.
const s = (horaGt) => String(Date.UTC(2026, 9, 3, 6 + horaGt) / 1000);
const a = (horaGt) => new Date(Date.UTC(2026, 9, 3, 6 + horaGt));

describe('lluvia del día (D-40, opción A)', () => {
  test('suma solo las franjas previstas que ya terminaron', () => {
    const cuenta = contarFranjasTerminadas(
      { precipitacion: 1, lluviaPrevista: { [s(9)]: 2.5, [s(12)]: 4, [s(15)]: 6 } },
      a(15), // 15:00: terminaron 9–12 y 12–15
    );
    expect(cuenta.precipitacion).toBe(7.5);
    expect(cuenta.franjasContadas).toEqual([s(12), s(9)].sort());
    expect(cuenta.lluviaPrevista).toEqual({ [s(15)]: 6 });
  });

  test('no cuenta dos veces una franja', () => {
    const primera = contarFranjasTerminadas({ lluviaPrevista: { [s(9)]: 3 } }, a(12));
    const segunda = contarFranjasTerminadas(
      { ...primera, lluviaPrevista: { ...primera.lluviaPrevista, [s(9)]: 3 } },
      a(15),
    );
    expect(segunda.precipitacion).toBe(3);
  });

  test('sin nada guardado empieza en cero', () => {
    expect(contarFranjasTerminadas(undefined, a(12))).toEqual({
      precipitacion: 0,
      lluviaPrevista: {},
      franjasContadas: [],
    });
  });

  test('el pronóstico nuevo reemplaza al viejo y solo prevé el día pedido', () => {
    const franjas = [
      { fechaHora: a(12), lluvia3h: 5 },
      { fechaHora: a(21), lluvia3h: 1 },
      { fechaHora: a(24), lluvia3h: 9 }, // ya es 4 de octubre
    ];
    const prevista = preverFranjas({ [s(12)]: 2, [s(9)]: 1 }, franjas, '20261003', idDiario, [
      s(9),
    ]);
    expect(prevista).toEqual({ [s(12)]: 5, [s(21)]: 1, [s(9)]: 1 });
  });

  test('no vuelve a prever una franja ya sumada', () => {
    const prevista = preverFranjas({}, [{ fechaHora: a(9), lluvia3h: 3 }], '20261003', idDiario, [
      s(9),
    ]);
    expect(prevista).toEqual({});
  });
});

import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/modelos/parcela.dart';
import 'package:agroclima_jalapa/pantallas/parcelas/registro_parcela_vm.dart';
import 'package:agroclima_jalapa/servicios/busqueda_lugares_servicio.dart';
import 'package:agroclima_jalapa/servicios/parcelas_servicio.dart';
import 'package:agroclima_jalapa/servicios/ubicacion_servicio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../apoyo/limites.dart';

class _ParcelasFalsas extends Mock implements ParcelasServicio {}

class _UbicacionFalsa extends Mock implements UbicacionServicio {}

class _BusquedaFalsa extends Mock implements BusquedaLugaresServicio {}

final _original = Parcela(
  parcelaId: 'p1',
  usuarioId: 'u1',
  nombre: 'El Guayabal',
  municipio: Municipio.jalapa,
  cultivo: Cultivo.maiz,
  etapa: Etapa.floracion,
  latitud: cabeceraJalapa.lat,
  longitud: cabeceraJalapa.lon,
  altitud: 1380,
  area: 2,
  celdaClima: '14.65_-90.00',
);

void main() {
  setUpAll(() => registerFallbackValue(_original));

  late _ParcelasFalsas parcelas;
  final limites = limitesReales();

  Future<RegistroParcelaVm> crearVm({
    int? pasoInicial,
    List<String> usados = const ['El Guayabal', 'La Joya'],
    Parcela? original,
  }) async {
    when(() => parcelas.validacion).thenReturn(limites);
    when(() => parcelas.nombresUsados()).thenAnswer((_) async => usados);
    final vm = RegistroParcelaVm(
      parcelas: parcelas,
      ubicacion: _UbicacionFalsa(),
      busqueda: _BusquedaFalsa(),
      original: original ?? _original,
      pasoInicial: pasoInicial,
    );
    await Future<void>.delayed(Duration.zero);
    return vm;
  }

  setUp(() => parcelas = _ParcelasFalsas());

  test('arranca en la revisión con los datos de la parcela', () async {
    final vm = await crearVm();
    expect(vm.esEdicion, isTrue);
    expect(vm.paso, 4);
    expect(vm.nombre, 'El Guayabal');
    expect(vm.municipio, Municipio.jalapa);
    expect(vm.cultivo, Cultivo.maiz);
    expect(vm.etapa, Etapa.floracion);
    expect(vm.puntoPuesto, isTrue);
    expect(vm.altitudTexto, '1380');
    expect(vm.areaTexto, '2');
  });

  test(
    'una parcela sin sembrar se carga como "Todavía no he sembrado"',
    () async {
      final vm = await crearVm(
        original: Parcela(
          parcelaId: 'p2',
          usuarioId: 'u1',
          nombre: 'Potrero',
          municipio: Municipio.jalapa,
          latitud: cabeceraJalapa.lat,
          longitud: cabeceraJalapa.lon,
          celdaClima: '',
        ),
      );
      expect(vm.sinSembrar, isTrue);
    },
  );

  test('su propio nombre no cuenta como repetido; el de otra sí', () async {
    final vm = await crearVm(pasoInicial: 1);
    expect(vm.siguiente(), isTrue);
    expect(vm.paso, 4);
    vm
      ..cambiarPaso(1)
      ..cambiarNombre('la joya');
    expect(vm.siguiente(), isFalse);
    expect(vm.errorNombre, Textos.errorNombreParcelaRepetido);
  });

  test('"Cambiar" lleva al paso y "Siguiente" vuelve a la revisión', () async {
    final vm = await crearVm();
    vm
      ..cambiarPaso(2)
      ..elegirEtapa(Etapa.llenado);
    expect(vm.siguiente(), isTrue);
    expect(vm.paso, 4);
    expect(vm.etapa, Etapa.llenado);
  });

  test('"atrás" desde un paso vuelve a la revisión y desde ahí sale', () async {
    final vm = await crearVm(pasoInicial: 3);
    expect(vm.atras(), isTrue);
    expect(vm.paso, 4);
    expect(vm.atras(), isFalse);
  });

  test('otro municipio pide poner el punto de nuevo (RN-02)', () async {
    final vm = await crearVm(pasoInicial: 1);
    vm.elegirMunicipio(Municipio.monjas);
    expect(vm.puntoPuesto, isFalse);
    expect(vm.siguiente(), isTrue);
    expect(vm.paso, 3, reason: 'falta el punto en Monjas');
    vm.moverPin(cabeceraMonjas.lat, cabeceraMonjas.lon);
    expect(vm.siguiente(), isTrue);
    expect(vm.paso, 4);
    expect(vm.municipio, Municipio.monjas);
  });

  test('guardar actualiza la parcela original, no crea otra', () async {
    when(
      () => parcelas.actualizar(
        original: any(named: 'original'),
        nombre: any(named: 'nombre'),
        latitud: any(named: 'latitud'),
        longitud: any(named: 'longitud'),
        cultivo: any(named: 'cultivo'),
        etapa: any(named: 'etapa'),
        altitud: any(named: 'altitud'),
        area: any(named: 'area'),
        unidadArea: any(named: 'unidadArea'),
      ),
    ).thenAnswer((_) async => false);
    final vm = await crearVm();
    expect(await vm.guardar(), ResultadoGuardado.guardada);
    verify(
      () => parcelas.actualizar(
        original: _original,
        nombre: 'El Guayabal',
        latitud: cabeceraJalapa.lat,
        longitud: cabeceraJalapa.lon,
        cultivo: Cultivo.maiz,
        etapa: Etapa.floracion,
        altitud: 1380,
        area: 2,
        unidadArea: 'manzana',
      ),
    ).called(1);
    verifyNever(
      () => parcelas.registrar(
        nombre: any(named: 'nombre'),
        latitud: any(named: 'latitud'),
        longitud: any(named: 'longitud'),
      ),
    );
  });

  test('sin señal queda pendiente y lo avisa', () async {
    when(
      () => parcelas.actualizar(
        original: any(named: 'original'),
        nombre: any(named: 'nombre'),
        latitud: any(named: 'latitud'),
        longitud: any(named: 'longitud'),
        cultivo: any(named: 'cultivo'),
        etapa: any(named: 'etapa'),
        altitud: any(named: 'altitud'),
        area: any(named: 'area'),
        unidadArea: any(named: 'unidadArea'),
      ),
    ).thenAnswer((_) async => true);
    final vm = await crearVm();
    expect(await vm.guardar(), ResultadoGuardado.guardadaSinSenal);
  });
}

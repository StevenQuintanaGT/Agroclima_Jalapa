import 'package:agroclima_jalapa/config/textos.dart';
import 'package:agroclima_jalapa/modelos/enums.dart';
import 'package:agroclima_jalapa/pantallas/parcelas/registro_parcela_vm.dart';
import 'package:agroclima_jalapa/repositorios/parcelas_repositorio.dart';
import 'package:agroclima_jalapa/servicios/busqueda_lugares_servicio.dart';
import 'package:agroclima_jalapa/servicios/parcelas_servicio.dart';
import 'package:agroclima_jalapa/servicios/ubicacion_servicio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../apoyo/limites.dart';

class _ParcelasFalsas extends Mock implements ParcelasServicio {}

class _UbicacionFalsa extends Mock implements UbicacionServicio {}

class _BusquedaFalsa extends Mock implements BusquedaLugaresServicio {}

void main() {
  group('altura del GPS', pruebasAlturaGps);

  late _ParcelasFalsas parcelas;
  late _UbicacionFalsa ubicacion;
  late _BusquedaFalsa busqueda;
  final limites = limitesReales();

  RegistroParcelaVm crearVm({List<String> usados = const []}) {
    when(() => parcelas.validacion).thenReturn(limites);
    when(() => parcelas.nombresUsados()).thenAnswer((_) async => usados);
    return RegistroParcelaVm(
      parcelas: parcelas,
      ubicacion: ubicacion,
      busqueda: busqueda,
    );
  }

  /// Llega al paso indicado con datos válidos.
  Future<RegistroParcelaVm> vmEnPaso(int paso) async {
    final vm = crearVm();
    await Future<void>.delayed(Duration.zero);
    vm
      ..cambiarNombre('El Guayabal')
      ..elegirMunicipio(Municipio.jalapa);
    if (paso > 1) vm.siguiente();
    if (paso > 2) {
      vm
        ..elegirCultivo(Cultivo.maiz)
        ..elegirEtapa(Etapa.floracion)
        ..siguiente();
    }
    if (paso > 3) {
      vm
        ..moverPin(cabeceraJalapa.lat, cabeceraJalapa.lon)
        ..siguiente();
    }
    return vm;
  }

  setUp(() {
    parcelas = _ParcelasFalsas();
    ubicacion = _UbicacionFalsa();
    busqueda = _BusquedaFalsa();
  });

  group('paso 1 · nombre y municipio', () {
    test('sin nombre ni municipio no avanza y lo dice', () async {
      final vm = crearVm();
      expect(vm.siguiente(), isFalse);
      expect(vm.paso, 1);
      expect(vm.errorNombre, Textos.errorNombreParcelaVacio);
      expect(vm.faltaMunicipio, isTrue);
    });

    test('nombre repetido no avanza (VA-02)', () async {
      final vm = crearVm(usados: ['El Guayabal']);
      await Future<void>.delayed(Duration.zero);
      vm
        ..cambiarNombre('el guayabal')
        ..elegirMunicipio(Municipio.jalapa);
      expect(vm.siguiente(), isFalse);
      expect(vm.errorNombre, Textos.errorNombreParcelaRepetido);
    });

    test('al elegir municipio el mapa se centra en él', () async {
      final vm = crearVm()..elegirMunicipio(Municipio.mataquescuintla);
      expect(
        limites.municipioDe(vm.latitud, vm.longitud),
        Municipio.mataquescuintla,
      );
    });
  });

  group('paso 2 · cultivo y etapa', () {
    test('con cultivo hace falta la etapa', () async {
      final vm = await vmEnPaso(2);
      vm.elegirCultivo(Cultivo.cafe);
      expect(vm.siguiente(), isFalse);
      expect(vm.faltaEtapa, isTrue);
    });

    test('"Todavía no he sembrado" avanza sin cultivo ni etapa', () async {
      final vm = await vmEnPaso(2);
      vm
        ..elegirCultivo(Cultivo.cafe)
        ..elegirEtapa(Etapa.cosecha)
        ..elegirSinSembrar();
      expect(vm.cultivo, isNull);
      expect(vm.etapa, isNull);
      expect(vm.siguiente(), isTrue);
      expect(vm.paso, 3);
    });
  });

  group('paso 3 · mapa (HU-03)', () {
    test('hay que poner el pin: el centro del municipio no basta', () async {
      final vm = await vmEnPaso(3);
      expect(vm.siguiente(), isFalse);
      expect(vm.faltaPunto, isTrue);
    });

    test('punto fuera de Jalapa: avisa y no deja seguir (VA-01)', () async {
      final vm = await vmEnPaso(3);
      vm.moverPin(ciudadGuatemala.lat, ciudadGuatemala.lon);
      expect(vm.fueraDeJalapa, isTrue);
      expect(vm.avisoPunto, Textos.errorFueraDeJalapa);
      expect(vm.siguiente(), isFalse);
    });

    test('punto en otro municipio: avisa y usa el real', () async {
      final vm = await vmEnPaso(3);
      vm.moverPin(cabeceraMonjas.lat, cabeceraMonjas.lon);
      expect(vm.municipio, Municipio.monjas);
      expect(vm.avisoPunto, Textos.avisoOtroMunicipio('Monjas'));
      expect(vm.siguiente(), isTrue);
    });

    test('muestra las coordenadas con 4 decimales', () async {
      final vm = await vmEnPaso(3);
      vm.moverPin(14.633912, -89.988876);
      expect(vm.coordenadasTexto, '14.6339, -89.9889');
    });

    test('área 0 o con letras es inválida (VA-03)', () async {
      final vm = await vmEnPaso(3);
      vm.moverPin(cabeceraJalapa.lat, cabeceraJalapa.lon);
      vm.cambiarArea('0');
      expect(vm.errorArea, Textos.errorArea);
      expect(vm.siguiente(), isFalse);
      vm.cambiarArea('dos');
      expect(vm.errorArea, Textos.errorArea);
      vm.cambiarArea('2,5');
      expect(vm.errorArea, isNull);
      expect(vm.area, 2.5);
      expect(vm.siguiente(), isTrue);
    });

    test('buscar un lugar mueve el pin', () async {
      final vm = await vmEnPaso(3);
      when(() => busqueda.buscar('Monjas')).thenAnswer(
        (_) async =>
            (latitud: cabeceraMonjas.lat, longitud: cabeceraMonjas.lon),
      );
      await vm.buscarLugar('Monjas');
      expect(vm.puntoPuesto, isTrue);
      expect(vm.municipio, Municipio.monjas);
    });

    test('lugar no encontrado: pide mover el pin', () async {
      final vm = await vmEnPaso(3);
      when(() => busqueda.buscar(any())).thenAnswer((_) async => null);
      await vm.buscarLugar('Aldea que no existe');
      expect(vm.puntoPuesto, isFalse);
      expect(vm.mensajeUbicacion, Textos.sinResultados);
    });
  });

  group('paso 3 · "Usar mi ubicación" (HU-04)', () {
    test('pone el pin y la altura del GPS', () async {
      final vm = await vmEnPaso(3);
      when(() => ubicacion.posicionActual()).thenAnswer(
        (_) async => UbicacionEncontrada(
          latitud: cabeceraJalapa.lat,
          longitud: cabeceraJalapa.lon,
          altitud: 1362,
        ),
      );
      await vm.usarMiUbicacion();
      expect(vm.puntoPuesto, isTrue);
      expect(vm.altitud, 1362);
      expect(vm.ubicando, isFalse);
    });

    test('sin permiso: lo explica y se puede seguir con el mapa', () async {
      final vm = await vmEnPaso(3);
      when(() => ubicacion.posicionActual())
          .thenAnswer((_) async => const UbicacionSinPermiso());
      await vm.usarMiUbicacion();
      expect(vm.mensajeUbicacion, Textos.sinPermisoUbicacion);
      vm.moverPin(cabeceraJalapa.lat, cabeceraJalapa.lon);
      expect(vm.siguiente(), isTrue);
    });

    test('ubicación apagada o sin GPS: mensaje llano', () async {
      final vm = await vmEnPaso(3);
      when(() => ubicacion.posicionActual())
          .thenAnswer((_) async => const UbicacionApagada());
      await vm.usarMiUbicacion();
      expect(vm.mensajeUbicacion, Textos.ubicacionApagada);
      when(() => ubicacion.posicionActual())
          .thenAnswer((_) async => const UbicacionNoDisponible());
      await vm.usarMiUbicacion();
      expect(vm.mensajeUbicacion, Textos.sinUbicacion);
    });
  });

  group('paso 4 · revisión y guardado', () {
    test('"Cambiar" lleva al paso y vuelve a la revisión', () async {
      final vm = await vmEnPaso(4);
      expect(vm.paso, 4);
      vm.cambiarPaso(1);
      expect(vm.paso, 1);
      vm.cambiarNombre('La Joya');
      expect(vm.siguiente(), isTrue);
      expect(vm.paso, 4);
    });

    void guardarResponde(Future<ParcelaGuardada> Function() respuesta) {
      when(
        () => parcelas.registrar(
          nombre: any(named: 'nombre'),
          latitud: any(named: 'latitud'),
          longitud: any(named: 'longitud'),
          cultivo: any(named: 'cultivo'),
          etapa: any(named: 'etapa'),
          altitud: any(named: 'altitud'),
          area: any(named: 'area'),
          unidadArea: any(named: 'unidadArea'),
        ),
      ).thenAnswer((_) => respuesta());
    }

    test('guarda con los datos de los 4 pasos', () async {
      guardarResponde(
        () async => const ParcelaGuardada(parcelaId: 'p1', pendiente: false),
      );
      final vm = await vmEnPaso(4);
      expect(await vm.guardar(), ResultadoGuardado.guardada);
      verify(
        () => parcelas.registrar(
          nombre: 'El Guayabal',
          latitud: cabeceraJalapa.lat,
          longitud: cabeceraJalapa.lon,
          cultivo: Cultivo.maiz,
          etapa: Etapa.floracion,
          altitud: null,
          area: null,
          unidadArea: 'manzana',
        ),
      ).called(1);
    });

    test('sin señal queda guardada y lo dice (RNF-16)', () async {
      guardarResponde(
        () async => const ParcelaGuardada(parcelaId: 'p1', pendiente: true),
      );
      final vm = await vmEnPaso(4);
      expect(await vm.guardar(), ResultadoGuardado.guardadaSinSenal);
    });

    test('nombre repetido al guardar: vuelve al paso 1 con el error', () async {
      guardarResponde(
        () async => throw const ErrorParcela(MotivoErrorParcela.nombreRepetido),
      );
      final vm = await vmEnPaso(4);
      expect(await vm.guardar(), ResultadoGuardado.error);
      expect(vm.paso, 1);
      expect(vm.errorGeneral, Textos.errorNombreParcelaRepetido);
    });
  });

  test('"Atrás" retrocede y en el paso 1 permite salir', () async {
    final vm = await vmEnPaso(3);
    expect(vm.atras(), isTrue);
    expect(vm.paso, 2);
    vm.atras();
    expect(vm.atras(), isFalse);
  });
}

void pruebasAlturaGps() {
  test('la altura del GPS se borra si el pin se mueve a otro lugar', () async {
    final parcelas = _ParcelasFalsas();
    final ubicacion = _UbicacionFalsa();
    when(() => parcelas.validacion).thenReturn(limitesReales());
    when(() => parcelas.nombresUsados()).thenAnswer((_) async => const []);
    when(() => ubicacion.posicionActual()).thenAnswer(
      (_) async => UbicacionEncontrada(
        latitud: cabeceraJalapa.lat,
        longitud: cabeceraJalapa.lon,
        altitud: 1362,
      ),
    );
    final vm = RegistroParcelaVm(
      parcelas: parcelas,
      ubicacion: ubicacion,
      busqueda: _BusquedaFalsa(),
    );
    await vm.usarMiUbicacion();
    expect(vm.altitud, 1362);
    vm.moverPin(cabeceraMonjas.lat, cabeceraMonjas.lon);
    expect(vm.altitud, isNull);

    // La que escribe el productor se respeta.
    vm
      ..cambiarAltitud('1400')
      ..moverPin(cabeceraJalapa.lat, cabeceraJalapa.lon);
    expect(vm.altitud, 1400);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:carros/bd.dart';

void main() {
  group('BaseDeDatos', () {
    late BaseDeDatos baseDeDatos;

    setUp(() async {
      sqfliteFfiInit();
      baseDeDatos = BaseDeDatos();
      await baseDeDatos.creacionbd();
    });

    test('Prueba de agregar carro', () async {
      await baseDeDatos.addcar('ABC123', 'Toyota', 'Camry', 2022);
      final data = await baseDeDatos.getData();
      expect(data, isNotEmpty);
      expect(data[0]['MATRICULA'], equals('ABC123'));
    });

    test('Prueba de editar carro', () async {
      await baseDeDatos.addcar('ABC123', 'Toyota', 'Camry', 2022);
      await baseDeDatos.editarCarro('ABC123', 'XYZ789', 'Honda', 'Civic', 2023);
      final data = await baseDeDatos.getData();
      expect(data, isNotEmpty);
      expect(data[0]['MATRICULA'], equals('XYZ789'));
      expect(data[0]['MARCA'], equals('Honda'));
      expect(data[0]['MODELO'], equals('Civic'));
      expect(data[0]['ANIO'], equals(2023));
    });

    test('Prueba de eliminar carro', () async {
      await baseDeDatos.addcar('ABC123', 'Toyota', 'Camry', 2022);
      await baseDeDatos.eliminarCarro('ABC123');
      final data = await baseDeDatos.getData();
      expect(data, isEmpty);
    });

    test('Prueba de creación de base de datos', () async {
      final data = await baseDeDatos.getData();
      expect(data, isEmpty);
    });

    // Agrega más pruebas según sea necesario

    tearDown(() async {
      // Agrega cualquier lógica de limpieza necesaria aquí.
      await baseDeDatos.eliminarCarro(
          'XYZ789'); // Limpia el carro agregado en la prueba de editar
    });
  });
}

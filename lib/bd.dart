import 'dart:async';

import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

late Database db;

class BaseDeDatos {
  late final StreamController<List<Map<String, dynamic>>> _dataStreamController;

  BaseDeDatos() {
    _dataStreamController = StreamController<List<Map<String, dynamic>>>();

    creacionbd().then((_) {
      obtenerCarros();
      getDataCategoria();
    });
  }

  Future<void> creacionbd() async {
    sqfliteFfiInit();

    var fabricaBaseDatos = databaseFactory;
    String rutaBaseDatos =
        '${await fabricaBaseDatos.getDatabasesPath()}/base.db';

    db = await fabricaBaseDatos.openDatabase(rutaBaseDatos,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE CARROS (
                ID INTEGER PRIMARY KEY AUTOINCREMENT,
                MATRICULA TEXT(7),
                MARCA TEXT(20),
                MODELO TEXT(20),
                ANIO INT(4)
              )
            ''');
            await db.execute('''
              CREATE TABLE CATEGORIAS (
                ID INTEGER PRIMARY KEY AUTOINCREMENT,
                NOMBRE TEXT(45)
              )
            ''');
            await db.execute('''
              CREATE TABLE GASTOS (
                ID INTEGER PRIMARY KEY AUTOINCREMENT,
                MATRICULA_CARRO TEXT(7),
                NOMBRE_CATEGORIA TEXT(20),
                MONTO INT(6),
                DESCRIPCION TEXT(255),  -- Agregado el campo "DESCRIPCION"
                FECHA TEXT,
                FOREIGN KEY (MATRICULA_CARRO) REFERENCES CARROS(MATRICULA),
                FOREIGN KEY (NOMBRE_CATEGORIA) REFERENCES CATEGORIAS(NOMBRE)
              )
            ''');
          },
        ));
  }

  Future<void> obtenerCategorias() async {
    List<Map<String, dynamic>> categorias = await getDataCategoria();
    _dataStreamController.add(categorias);
  }

  Future<bool> categoriaExiste(String nombreCategoria) async {
    final List<Map<String, dynamic>> categorias = await db
        .query('CATEGORIAS', where: 'NOMBRE = ?', whereArgs: [nombreCategoria]);
    return categorias.isNotEmpty;
  }

  /*Future<void> obtenerCategorias() async {
    _dataStreamController.add(await getDataCategoria());
  }*/

  Future<void> obtenerCarros() async {
    _dataStreamController.add(await getData());
  }

  Future<List<Map<String, dynamic>>> getData() async {
    return await db.query('CARROS');
  }

  Future<void> addcar(
      String matricula, String marca, String modelo, int anio) async {
    await db.insert(
        'CARROS',
        {
          'MATRICULA': matricula,
          'MARCA': marca,
          'MODELO': modelo,
          'ANIO': anio
        },
        conflictAlgorithm: ConflictAlgorithm.replace);

    _dataStreamController.add(await getData());
  }

  Stream<List<Map<String, dynamic>>> getDataStream() {
    return _dataStreamController.stream;
  }

  Future<void> eliminarCarro(String matricula) async {
    await db.delete('CARROS', where: 'MATRICULA = ?', whereArgs: [matricula]);
    _dataStreamController.add(await getData());
  }

  Future<void> editarCarro(
    String matriculaOriginal,
    String nuevaMatricula,
    String nuevaMarca,
    String nuevoModelo,
    int nuevoAnio,
  ) async {
    await db.update(
      'CARROS',
      {
        'MATRICULA': nuevaMatricula,
        'MARCA': nuevaMarca,
        'MODELO': nuevoModelo,
        'ANIO': nuevoAnio,
      },
      where: 'MATRICULA = ?',
      whereArgs: [matriculaOriginal],
    );

    _dataStreamController.add(await getData());
  }

  Future<List<Map<String, dynamic>>> getDataCategoria() async {
    return await db.query('CATEGORIAS');
  }

  Future<void> agregarCategoria(String nombreCategoria) async {
    await db.insert(
      'CATEGORIAS',
      {'NOMBRE': nombreCategoria},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _dataStreamController.add(await getDataCategoria());
  }

  Future<List<Map<String, dynamic>>> getDataMatriculas() async {
    // Cambia la implementación según sea necesario
    return await db.query('CARROS', columns: ['MATRICULA']);
  }

  Future<void> eliminarCategoria(String nombreCategoria) async {
    await db.delete('CATEGORIAS',
        where: 'NOMBRE = ?', whereArgs: [nombreCategoria]);
    _dataStreamController.add(await getDataCategoria());
  }

  Future<void> editarCategoria(
      String nombreCategoriaOriginal, String nuevoNombreCategoria) async {
    await db.update(
      'CATEGORIAS',
      {'NOMBRE': nuevoNombreCategoria},
      where: 'NOMBRE = ?',
      whereArgs: [nombreCategoriaOriginal],
    );

    _dataStreamController.add(await getDataCategoria());
  }

  /* Gastos */

  Future<List<Map<String, dynamic>>> getDataGastos() async {
    return await db.query('GASTOS');
  }

  Future<void> addGasto(String matriculaCarro, String nombreCategoria,
      int monto, String descripcion) async {
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    await db.insert(
      'GASTOS',
      {
        'MATRICULA_CARRO': matriculaCarro,
        'NOMBRE_CATEGORIA': nombreCategoria,
        'MONTO': monto,
        'DESCRIPCION': descripcion,
        'FECHA': formattedDate,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _dataStreamController.add(await getDataGastos());
    _dataStreamController.add(await getData());
  }

  Future<void> eliminarGasto(Map<String, dynamic> gasto) async {
    await db.delete('GASTOS', where: 'ID = ?', whereArgs: [gasto['ID']]);
    _dataStreamController.add(await getDataGastos());
    _dataStreamController.add(await getData());
  }

  Future<void> editarGasto(
    Map<String, dynamic> gastoOriginal,
    String nuevaMatriculaCarro,
    String nuevaCategoria,
    int nuevoMonto,
    String nuevaDescripcion,
  ) async {
    await db.update(
      'GASTOS',
      {
        'MATRICULA_CARRO': nuevaMatriculaCarro,
        'NOMBRE_CATEGORIA': nuevaCategoria,
        'MONTO': nuevoMonto,
        'DESCRIPCION': nuevaDescripcion,
      },
      where: 'ID = ?',
      whereArgs: [gastoOriginal['ID']],
    );

    _dataStreamController.add(await getDataGastos());
  }

  Future<List<Map<String, dynamic>>> getGastos() async {
    return await db.query('GASTOS', orderBy: 'FECHA DESC');
  }

  void dispose() {
    _dataStreamController.close();
  }
}

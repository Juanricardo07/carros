import 'dart:async';

import 'package:flutter/material.dart';
import 'bd.dart';

abstract class MyBlocEvent {}

class FetchDataEvent extends MyBlocEvent {}

class CargarGastosEvent extends MyBlocEvent {}

class AgregarcarroEvent extends MyBlocEvent {
  final String matricula;
  final String marca;
  final String modelo;
  final String anio;

  AgregarcarroEvent(this.matricula, this.marca, this.modelo, this.anio);
}

class EliminarCarroEvent extends MyBlocEvent {
  final String matricula;

  EliminarCarroEvent({required this.matricula});
}

class EditarCarroEvent extends MyBlocEvent {
  final String matriculaOriginal;
  final String nuevaMatricula;
  final String nuevaMarca;
  final String nuevoModelo;
  final String nuevoAnio;

  EditarCarroEvent(
      {required this.matriculaOriginal,
      required this.nuevaMatricula,
      required this.nuevaMarca,
      required this.nuevoModelo,
      required this.nuevoAnio});
}

class AgregarCategoriaEvent extends MyBlocEvent {
  final String nombreCategoria;

  AgregarCategoriaEvent(this.nombreCategoria);
}

class EliminarCategoriaEvent extends MyBlocEvent {
  final String nombreCategoria;

  EliminarCategoriaEvent(this.nombreCategoria);
}

class EditarCategoriaEvent extends MyBlocEvent {
  String categoriaOriginal;
  String nuevoNombreCategoria;
  EditarCategoriaEvent({
    required this.categoriaOriginal,
    required this.nuevoNombreCategoria,
  });
}

class AgregarGastoEvent extends MyBlocEvent {
  final String matriculaCarro;
  final String nombreCategoria;
  final int monto;
  final String descripcion;
  final String fecha;

  AgregarGastoEvent(
      {required this.fecha,
      required this.matriculaCarro,
      required this.nombreCategoria,
      required this.monto,
      required this.descripcion});
}

class MostrarSnackbarEvent extends MyBlocEvent {
  final String message;

  MostrarSnackbarEvent(this.message);
}

class CargarMatriculasEvent extends MyBlocEvent {}

class CargarCategoriasEvent extends MyBlocEvent {}

class EliminarGastoEvent extends MyBlocEvent {
  final Map<String, dynamic> gasto;

  EliminarGastoEvent(this.gasto);
}

class EditarGastoEvent extends MyBlocEvent {
  final Map<String, dynamic> gastoOriginal;
  final String nuevaMatriculaCarro;
  final String nuevaCategoria;
  final int nuevoMonto;
  final String nuevaDescripcion;

  EditarGastoEvent({
    required this.gastoOriginal,
    required this.nuevaMatriculaCarro,
    required this.nuevaCategoria,
    required this.nuevoMonto,
    required this.nuevaDescripcion,
  });
}

class FiltrarGastosPorFechaEvent extends MyBlocEvent {
  final DateTime fecha;

  FiltrarGastosPorFechaEvent(this.fecha);
}

class MyBlocState {}

class EstadoInicial extends MyBlocState {}

class CargarEstado extends MyBlocState {
  final List<String> dataList;

  CargarEstado(this.dataList);

  @override
  String toString() {
    return 'CargarEstado(dataList: $dataList)';
  }
}

class DatosCargados extends MyBlocState {}

class CategoriasEliminadas extends MyBlocState {
  final List<String> newDataList;

  CategoriasEliminadas(this.newDataList);
}

class GastosCargados extends MyBlocState {}

class Mybloc with ChangeNotifier {
  bool _isDataStreamListening = false;
  bool get isDataStreamListening => _isDataStreamListening;

  final _categoriasController = StreamController<List<String>>.broadcast();
  final _matriculasController = StreamController<List<String>>.broadcast();
  final _gastosController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final _categoriasNotifier = ValueNotifier<List<String>>([]);
  final _matriculasNotifier = ValueNotifier<List<String>>([]);

  ValueNotifier<List<String>> get categoriasNotifier => _categoriasNotifier;
  ValueNotifier<List<String>> get matriculasNotifier => _matriculasNotifier;

  Stream<List<Map<String, dynamic>>> get gastosStream =>
      _gastosController.stream;
  Stream<List<String>> get categoriasStream => _categoriasController.stream;
  Stream<List<String>> get matriculasStream => _matriculasController.stream;

  void setIsDataStreamListening(bool value) {
    _isDataStreamListening = value;
  }

  MyBlocState? _currentState;

  final BaseDeDatos _dataRepository;

  Mybloc(this._dataRepository) {
    cargarDatosIniciales();
    initializeBloc();
  }

  void initializeBloc() async {
    _currentState = DatosCargados();
    notifyListeners();
  }

  Future<void> cargarDatosIniciales() async {
    await cargarMatriculas();
    await cargarCategorias();
    await cargarGastos();
  }

  MyBlocState? get currentState => _currentState;

  Future<void> mapEventToState(MyBlocEvent event) async {
    if (event is FetchDataEvent || event is DatosCargados) {
      List<Map<String, dynamic>> dataList = await _dataRepository.getData();

      List<String> stringList = dataList.map((data) {
        String matricula = data['MATRICULA'].toString();
        String marca = data['MARCA'].toString();
        String modelo = data['MODELO'].toString();
        String anio = data['ANIO'].toString();
        return '$matricula $marca $modelo $anio';
      }).toList();

      List<String> uniqueMarcaList = [];
      Set<String> existingMarcas = {};

      for (String marca in stringList) {
        if (!existingMarcas.contains(marca)) {
          uniqueMarcaList.add(marca);
          existingMarcas.add(marca);
        }
      }

      _currentState = CargarEstado(stringList);
      notifyListeners();
    } else if (event is AgregarcarroEvent) {
      int anio = int.parse(event.anio);
      await _dataRepository.addcar(
          event.matricula, event.marca, event.modelo, anio);
      _currentState = DatosCargados();
      notifyListeners();
    } else if (event is EliminarCarroEvent) {
      await _dataRepository.eliminarCarro(event.matricula);
      _currentState = DatosCargados();
      notifyListeners();
    } else if (event is EditarCarroEvent) {
      int nuevoAnio = int.parse(event.nuevoAnio);
      await _dataRepository.editarCarro(
        event.matriculaOriginal,
        event.nuevaMatricula,
        event.nuevaMarca,
        event.nuevoModelo,
        nuevoAnio,
      );
      notifyListeners();
      _currentState = DatosCargados();
    } else if (event is AgregarCategoriaEvent) {
      List<Map<String, dynamic>> categoriasMapList =
          await _dataRepository.getDataCategoria();
      bool categoriaExistente = categoriasMapList.any((categoria) =>
          categoria['NOMBRE'].toString().toLowerCase() ==
          event.nombreCategoria.toLowerCase());

      if (!categoriaExistente) {
        await _dataRepository.agregarCategoria(event.nombreCategoria);
        cargarCategorias();
      } else {}
    } else if (event is EditarCategoriaEvent) {
      List<Map<String, dynamic>> categoriasMapList =
          await _dataRepository.getDataCategoria();
      bool nuevaCategoriaExistente = categoriasMapList.any((categoria) =>
          categoria['NOMBRE'].toString().toLowerCase() ==
          event.nuevoNombreCategoria.toLowerCase());

      if (!nuevaCategoriaExistente) {
        await _dataRepository.editarCategoria(
          event.categoriaOriginal,
          event.nuevoNombreCategoria,
        );
        cargarCategorias();
      } else {}
    } else if (event is EliminarCategoriaEvent) {
      await _dataRepository.eliminarCategoria(event.nombreCategoria);
      cargarCategorias();
    } else if (event is AgregarGastoEvent) {
      await _dataRepository.addGasto(event.matriculaCarro,
          event.nombreCategoria, event.monto, event.descripcion);
      cargarGastos();
    } else if (event is EditarGastoEvent) {
      await _dataRepository.editarGasto(
          event.gastoOriginal,
          event.nuevaMatriculaCarro,
          event.nuevaCategoria,
          event.nuevoMonto,
          event.nuevaDescripcion);
      cargarGastos();
    } else if (event is EliminarGastoEvent) {
      await _dataRepository.eliminarGasto(event.gasto);
      cargarGastos();
    } else if (event is CargarMatriculasEvent) {
      await cargarMatriculas();
    } else if (event is CargarCategoriasEvent) {
      await cargarCategorias();
    } else if (event is CargarGastosEvent) {
      await cargarGastos();
    } else if (event is FiltrarGastosPorFechaEvent) {
      List<Map<String, dynamic>> gastosFiltrados =
          await _dataRepository.getDataGastos();
      gastosFiltrados = gastosFiltrados.where((gasto) {
        DateTime fechaGasto = DateTime.parse(gasto['FECHA']);
        return fechaGasto.isAtSameMomentAs(event.fecha);
      }).toList();
      _gastosController.add(gastosFiltrados);
    }
  }

  Future<void> cargarCategorias() async {
    List<Map<String, dynamic>> categoriasMapList =
        await _dataRepository.getDataCategoria();
    List<String> categorias = categoriasMapList
        .map((categoria) => categoria['NOMBRE'].toString())
        .toList();

    _categoriasController.add(categorias);
  }

  Future<List<String>> listarCategorias() async {
    List<Map<String, dynamic>> categoriasMapList =
        await _dataRepository.getDataCategoria();
    List<String> categorias = categoriasMapList
        .map((categoria) => categoria['NOMBRE'].toString())
        .toList();

    _categoriasController.add(categorias);
    return categorias;
  }

  Future<void> cargarMatriculas() async {
    List<Map<String, dynamic>> matriculasMapList =
        await _dataRepository.getDataMatriculas();
    List<String> matriculas = matriculasMapList
        .map((matricula) => matricula['MATRICULA'].toString())
        .toList();

    _matriculasController.add(matriculas);
  }

  Future<void> cargarGastos() async {
    List<Map<String, dynamic>> gastosMapList =
        await _dataRepository.getDataGastos();
    _gastosController.add(gastosMapList);
    notifyListeners();
  }

  /* @override
  void dispose() {
    _categoriasController.close();
    _matriculasController.close();
    _gastosController.close();
    super.dispose();
  }*/
}

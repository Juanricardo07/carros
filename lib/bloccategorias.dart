import 'dart:async';
import 'bd.dart';

abstract class CategoriaBlocEvent {}

class CargarCategoriasEvent extends CategoriaBlocEvent {}

class AgregarCategoriaEvent extends CategoriaBlocEvent {
  final String nombreCategoria;

  AgregarCategoriaEvent(this.nombreCategoria);
}

class EliminarCategoriaEvent extends CategoriaBlocEvent {
  final String nombreCategoria;

  EliminarCategoriaEvent(this.nombreCategoria);
}

class EditarCategoriaEvent extends CategoriaBlocEvent {
  final String nombreCategoriaOriginal;
  final String nuevoNombreCategoria;

  EditarCategoriaEvent(this.nombreCategoriaOriginal, this.nuevoNombreCategoria);
}

abstract class CategoriaBlocState {}

class CategoriaEstadoInicial extends CategoriaBlocState {}

class CategoriaDatosCargadosState extends CategoriaBlocState {
  final List<String> categoriasList;

  CategoriaDatosCargadosState(this.categoriasList);
}

class CategoriaBloc {
  CategoriaBlocState? _currentState;

  final _blocController = StreamController<CategoriaBlocState>();
  final BaseDeDatos _dataRepository;

  CategoriaBloc(this._dataRepository);

  CategoriaBlocState? get currentState => _currentState;

  Stream<CategoriaBlocState> get blocStream => _blocController.stream;

  Future<void> mapEventToState(CategoriaBlocEvent event) async {
    if (event is CargarCategoriasEvent) {
      List<Map<String, dynamic>> categoriasData =
          await _dataRepository.getDataCategoria();
      List<String> categoriasList = categoriasData.map((data) {
        return data['NOMBRE'].toString();
      }).toList();

      _currentState = CategoriaDatosCargadosState(categoriasList);
      _blocController.add(CategoriaDatosCargadosState(categoriasList));
    } else if (event is AgregarCategoriaEvent) {
      await _dataRepository.agregarCategoria(event.nombreCategoria);
      _blocController.add(CategoriaDatosCargadosState(
          [])); // Puedes cargar datos actualizados si es necesario
    } else if (event is EliminarCategoriaEvent) {
      await _dataRepository.eliminarCategoria(event.nombreCategoria);
      _blocController.add(CategoriaDatosCargadosState(
          [])); // Puedes cargar datos actualizados si es necesario
    } else if (event is EditarCategoriaEvent) {
      await _dataRepository.editarCategoria(
          event.nombreCategoriaOriginal, event.nuevoNombreCategoria);
      _blocController.add(CategoriaDatosCargadosState(
          [])); // Puedes cargar datos actualizados si es necesario
    }
  }

  void dispose() {
    _blocController.close();
  }
}

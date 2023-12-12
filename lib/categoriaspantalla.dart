import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:carros/bloc.dart';
import 'package:carros/bd.dart';

class GastosPantalla extends StatefulWidget {
  final BaseDeDatos baseDeDatos;

  const GastosPantalla({
    Key? key,
    required this.baseDeDatos,
  }) : super(key: key);
  @override
  // ignore: library_private_types_in_public_api
  _GastosPantallaState createState() => _GastosPantallaState();
}

class _GastosPantallaState extends State<GastosPantalla> {
  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    await context.read<Mybloc>().cargarCategorias();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: GlobalKey<ScaffoldState>(),
      appBar: AppBar(
        title: const Text('Categorias'),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<List<String>>(
        stream: context.watch<Mybloc>().categoriasStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final categoria = snapshot.data![index];
                return Card(
                  color: const Color.fromARGB(255, 247, 187, 168),
                  elevation: 3,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(categoria),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _editarCategoria(context, categoria);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _eliminarCategoria(context, categoria);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: Text('No hay categorías disponibles.'),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarAgregarCategoriaModal(context);
        },
        backgroundColor: const Color.fromARGB(255, 241, 161, 137),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarAgregarCategoriaModal(BuildContext context) {
    final TextEditingController categoriaController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Agrega Categorias',
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                  TextField(
                    controller: categoriaController,
                    keyboardType: TextInputType.text,
                    maxLength: 30,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                    ],
                    decoration: const InputDecoration(
                        labelText: 'Nombre de la Categoría',
                        labelStyle: TextStyle(color: Colors.deepOrange),
                        focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.deepOrange))),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      var mibloc = context.read<Mybloc>();
                      await _cargarCategorias();
                      if (categoriaController.text.isEmpty) {
                        showCamposVaciosAlert();
                      } else if (await widget.baseDeDatos
                          .categoriaExiste(categoriaController.text)) {
                        showCategoriaExistenteAlert();
                      } else {
                        mibloc.mapEventToState(
                          AgregarCategoriaEvent(categoriaController.text),
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text(
                      'Agregar Categoría',
                      style: TextStyle(color: Colors.deepOrange),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void showCategoriaExistenteAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Categoría Existente'),
          content: const Text('La categoría ya existe.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarErrorDialog(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(mensaje),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void showCamposVaciosAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Campos Vacíos'),
          content: const Text('Por favor, complete todos los campos.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarCategoria(BuildContext context, String categoria) {
    context.read<Mybloc>().mapEventToState(EliminarCategoriaEvent(categoria));
  }

  void _editarCategoria(BuildContext context, String categoria) {
    TextEditingController editController =
        TextEditingController(text: categoria);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Categoría'),
          content: TextField(
            controller: editController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
            ],
            decoration: const InputDecoration(
                labelText: 'Nuevo nombre de la categoría'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.deepOrange),
              ),
            ),
            TextButton(
              onPressed: () async {
                var miblocc = context.read<Mybloc>();
                if (editController.text.isEmpty) {
                  _mostrarErrorDialog(context, 'El campo no puede estar vacío');
                } else if (await widget.baseDeDatos
                    .categoriaExiste(editController.text)) {
                  _mostrarErrorDialog(context, 'La categoría ya existe');
                } else {
                  final nuevoNombreCategoria = editController.text;
                  miblocc.mapEventToState(EditarCategoriaEvent(
                    categoriaOriginal: categoria,
                    nuevoNombreCategoria: nuevoNombreCategoria,
                  ));
                }
                Navigator.of(context).pop();
              },
              child: const Text(
                'Guardar',
                style: TextStyle(color: Colors.deepOrange),
              ),
            ),
          ],
        );
      },
    );
  }
}

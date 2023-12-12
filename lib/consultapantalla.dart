import 'package:carros/bd.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:carros/bloc.dart';

class ConsultasPantalla extends StatefulWidget {
  final BaseDeDatos baseDeDatos;

  const ConsultasPantalla({
    Key? key,
    required this.baseDeDatos,
  }) : super(key: key);

  @override
  ConsultasPantallaState createState() => ConsultasPantallaState();
}

class ConsultasPantallaState extends State<ConsultasPantalla> {
  List<String> categorias = [];
  List<String> matriculas = [];
  String selectedMatricula = '';
  String selectedCategoria = '';
  String? selectedCategoriaFilter;
  bool hasMontoFilter = false;
  int? minMontoFilter;
  int? maxMontoFilter;
  BuildContext? myBuildContext;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
    _cargarMatriculas();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    await context.read<Mybloc>().mapEventToState(CargarGastosEvent());
  }

  Future<void> _cargarCategorias() async {
    final myBloc = context.read<Mybloc>();
    await myBloc.mapEventToState(CargarCategoriasEvent());

    myBloc.categoriasStream.listen((categoriasList) {
      setState(() {
        categorias = categoriasList;
        selectedCategoria =
            categoriasList.isNotEmpty ? categoriasList.first : '';
      });
    });
  }

  Future<void> _cargarMatriculas() async {
    final myBloc = context.read<Mybloc>();
    await myBloc.mapEventToState(CargarMatriculasEvent());

    myBloc.matriculasStream.listen((matriculasList) {
      setState(() {
        matriculas = matriculasList;
        selectedMatricula =
            matriculasList.isNotEmpty ? matriculasList.first : '';
      });
    });
  }

  void _mostrarFiltroMontoDialog(BuildContext context) {
    final TextEditingController minMontoController = TextEditingController();
    final TextEditingController maxMontoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filtrar por Monto'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minMontoController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Monto mínimo',
                  labelStyle: TextStyle(color: Colors.deepOrange),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepOrange),
                  ),
                ),
              ),
              TextField(
                controller: maxMontoController,
                keyboardType: TextInputType.number,
                maxLength: 10,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Monto máximo',
                  labelStyle: TextStyle(color: Colors.deepOrange),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepOrange),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final minMonto = int.tryParse(minMontoController.text);
                final maxMonto = int.tryParse(maxMontoController.text);

                if (minMonto == null && maxMonto == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Ingresa al menos un valor de monto.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red, // Cambia el color aquí
                    ),
                  );
                } else {
                  setState(() {
                    hasMontoFilter = true;
                    minMontoFilter = minMonto;
                    maxMontoFilter = maxMonto;
                  });

                  Navigator.of(context).pop();
                }
              },
              child: const Text('Filtrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    myBuildContext = context;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos'),
        backgroundColor: Colors.deepOrange,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _mostrarFiltroMontoDialog(context);
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: context.watch<Mybloc>().gastosStream,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            List<Map<String, dynamic>> filteredGastos = [...snapshot.data!];

            if (hasMontoFilter) {
              filteredGastos = filteredGastos.where((gasto) {
                final monto = gasto['MONTO'] as int;
                return (minMontoFilter == null || monto >= minMontoFilter!) &&
                    (maxMontoFilter == null || monto <= maxMontoFilter!);
              }).toList();
            }

            return ListView.builder(
              itemCount: filteredGastos.length,
              itemBuilder: (context, index) {
                final gasto = filteredGastos[index];
                return Card(
                  elevation: 3,
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Matrícula: ${gasto['MATRICULA_CARRO']}'),
                        Text('Categoría: ${gasto['NOMBRE_CATEGORIA']}'),
                        Text('Monto: ${gasto['MONTO']}'),
                        Text('Descripción: ${gasto['DESCRIPCION']}'),
                        Text('Fecha: ${gasto['FECHA']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _editarGasto(context, gasto);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _eliminarGasto(context, gasto);
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
              child: Text('No hay gastos disponibles.'),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarAgregarGastoModal(context);
        },
        backgroundColor: const Color.fromARGB(255, 241, 161, 137),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarAgregarGastoModal(BuildContext context) {
    final Future<void> loadDataFuture = Future.wait([
      context.read<Mybloc>().cargarMatriculas(),
      context.read<Mybloc>().cargarCategorias(),
    ]);

    final TextEditingController montoController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<void>(
          future: loadDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error cargando datos'));
            } else {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Matricula',
                                style: TextStyle(color: Colors.deepOrange)),
                            DropdownButton<String>(
                              value: selectedMatricula,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedMatricula = newValue!;
                                });
                              },
                              items: matriculas.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Categoria',
                                style: TextStyle(color: Colors.deepOrange)),
                            DropdownButton<String>(
                              value: selectedCategoria,
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedCategoria = newValue!;
                                });
                              },
                              items: categorias.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: montoController,
                          maxLength: 10,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Monto',
                            labelStyle: TextStyle(color: Colors.deepOrange),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.deepOrange),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descripcionController,
                          decoration: const InputDecoration(
                            labelText: 'Descripción',
                            labelStyle: TextStyle(color: Colors.deepOrange),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.deepOrange),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            final now = DateTime.now();
                            final String formattedDate =
                                '${now.year}-${now.month}-${now.day}';
                            context.read<Mybloc>().mapEventToState(
                                  AgregarGastoEvent(
                                    matriculaCarro: selectedMatricula,
                                    nombreCategoria: selectedCategoria,
                                    monto:
                                        int.tryParse(montoController.text) ?? 0,
                                    descripcion: descripcionController.text,
                                    fecha: formattedDate,
                                  ),
                                );
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Agregar Gasto',
                            style: TextStyle(color: Colors.deepOrange),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  void _eliminarGasto(BuildContext context, Map<String, dynamic> gasto) {
    context.read<Mybloc>().mapEventToState(EliminarGastoEvent(gasto));

    _cargarMatriculas();
    _cargarCategorias();
  }

  void _editarGasto(BuildContext context, Map<String, dynamic> gasto) {
    TextEditingController matriculaController =
        TextEditingController(text: gasto['MATRICULA_CARRO']);
    TextEditingController categoriaController =
        TextEditingController(text: gasto['NOMBRE_CATEGORIA']);
    TextEditingController montoController =
        TextEditingController(text: gasto['MONTO'].toString());
    TextEditingController descripcionController =
        TextEditingController(text: gasto['DESCRIPCION'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Gasto'),
          content: Column(
            children: [
              TextField(
                controller: montoController,
                maxLength: 10,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Nuevo Monto',
                  labelStyle: TextStyle(color: Colors.deepOrange),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepOrange),
                  ),
                ),
              ),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Nueva Descripción',
                  labelStyle: TextStyle(color: Colors.deepOrange),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.deepOrange),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                context.read<Mybloc>().mapEventToState(
                      EditarGastoEvent(
                        gastoOriginal: gasto,
                        nuevaMatriculaCarro: matriculaController.text,
                        nuevaCategoria: categoriaController.text,
                        nuevoMonto: int.tryParse(montoController.text) ?? 0,
                        nuevaDescripcion: descripcionController.text,
                      ),
                    );
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }
}

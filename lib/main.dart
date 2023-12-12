import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:carros/bd.dart';
import 'package:carros/bloc.dart';
import 'package:provider/provider.dart';
import 'categoriaspantalla.dart';
import 'consultapantalla.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  BaseDeDatos basededatos = BaseDeDatos();
  await basededatos.creacionbd();
  Mybloc mybloc = Mybloc(basededatos);

  await mybloc.cargarDatosIniciales();

  runApp(
    ChangeNotifierProvider.value(
      value: mybloc,
      child: MainApp(
        baseDeDatos: basededatos,
        mybloc: mybloc,
      ),
    ),
  );
}

class MainApp extends StatelessWidget {
  final BaseDeDatos baseDeDatos;
  final Mybloc mybloc;
  const MainApp({
    Key? key,
    required this.baseDeDatos,
    required this.mybloc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      home: MyHomePage(
        baseDeDatos: baseDeDatos,
        bloc: Mybloc(baseDeDatos),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final Mybloc bloc;
  final BaseDeDatos baseDeDatos;

  const MyHomePage({
    Key? key,
    required this.baseDeDatos,
    required this.bloc,
  }) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState(baseDeDatos: baseDeDatos);
}

class MyHomePageState extends State<MyHomePage> {
  final _matriculaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  late final Mybloc _bloc;
  late final BaseDeDatos baseDeDatos;

  String? selectedMarca;
  String? selectedMatricula;
  int? selectedId;

  List<String> marcasList = [];
  List<String> matriculasList = [];
  List<String> modelosList = [];
  List<String> aniosList = [];
  List<int> idList = [];

  int _currentIndex = 0;
  MyHomePageState({required this.baseDeDatos});

  @override
  void initState() {
    super.initState();
    _bloc = Provider.of<Mybloc>(context, listen: false);

    if (!_bloc.isDataStreamListening) {
      _bloc.mapEventToState(FetchDataEvent());
      _bloc.mapEventToState(CargarGastosEvent());
      _bloc.setIsDataStreamListening(true);
    }

    widget.baseDeDatos.getDataStream().listen((dataList) {
      marcasList = dataList.map((data) => data['MARCA'].toString()).toList();
      modelosList = dataList.map((data) => data['MODELO'].toString()).toList();
      aniosList = dataList.map((data) => data['ANIO'].toString()).toList();
      idList = dataList.map((data) => data['ID'] as int).toList();
      matriculasList =
          dataList.map((data) => data['MATRICULA'].toString()).toSet().toList();
      selectedId = null;
      _bloc.mapEventToState(CargarGastosEvent());
    });
  }

  void _showEditarCarroModal({
    required String matricula,
    required String marca,
    required String modelo,
    required String anio,
  }) {
    _matriculaController.text = matricula;
    _marcaController.text = marca;
    _modeloController.text = modelo;
    _anioController.text = anio;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Carro'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _matriculaController,
                  keyboardType: TextInputType.text,
                  maxLength: 7,
                  decoration: const InputDecoration(
                    labelText: 'Matricula',
                  ),
                ),
                TextField(
                  controller: _marcaController,
                  keyboardType: TextInputType.text,
                  maxLength: 20,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z ]')), // Solo letras y espacios
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                  ),
                ),
                TextField(
                  controller: _modeloController,
                  keyboardType: TextInputType.text,
                  maxLength: 20,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z ]')), // Solo letras y espacios
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Modelo',
                  ),
                ),
                TextField(
                  controller: _anioController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Año',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (_matriculaController.text.isEmpty ||
                    _marcaController.text.isEmpty ||
                    _modeloController.text.isEmpty ||
                    _anioController.text.isEmpty) {
                  showCamposVaciosAlert();
                } else if (matriculasList.contains(_matriculaController.text) &&
                    _matriculaController.text != selectedMatricula) {
                  showMatriculaExistenteAlert();
                } else {
                  _bloc.mapEventToState(
                    EditarCarroEvent(
                      matriculaOriginal: selectedMatricula!,
                      nuevaMatricula: _matriculaController.text,
                      nuevaMarca: _marcaController.text,
                      nuevoModelo: _modeloController.text,
                      nuevoAnio: _anioController.text,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar Cambios'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
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

  void showMatriculaExistenteAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Matrícula Existente'),
          content: const Text('La matrícula ya existe.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Vehiculos'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _matriculaController,
              keyboardType: TextInputType.text,
              maxLength: 7,
              decoration: const InputDecoration(
                  labelText: 'Matricula',
                  labelStyle: TextStyle(color: Colors.deepOrange),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepOrange))),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _marcaController,
              keyboardType: TextInputType.text,
              maxLength: 20,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Z ]')), // Solo letras y espacios
              ],
              decoration: const InputDecoration(
                  labelText: 'Marca',
                  labelStyle: TextStyle(color: Colors.deepOrange),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepOrange))),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _modeloController,
              keyboardType: TextInputType.text,
              maxLength: 20,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(
                    RegExp(r'[a-zA-Z ]')), // Solo letras y espacios
              ],
              decoration: const InputDecoration(
                  labelText: 'Modelo',
                  labelStyle: TextStyle(color: Colors.deepOrange),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepOrange))),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _anioController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                  labelText: 'Año',
                  labelStyle: TextStyle(color: Colors.deepOrange),
                  focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.deepOrange))),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                if (_matriculaController.text.isEmpty ||
                    _marcaController.text.isEmpty ||
                    _modeloController.text.isEmpty ||
                    _anioController.text.isEmpty) {
                  showCamposVaciosAlert();
                } else if (matriculasList.contains(_matriculaController.text)) {
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
                            'La matrícula ya existe.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  // La matrícula no existe, agregar el carro
                  _bloc.mapEventToState(AgregarcarroEvent(
                    _matriculaController.text,
                    _marcaController.text,
                    _modeloController.text,
                    _anioController.text,
                  ));
                }
              },
              style:
                  ElevatedButton.styleFrom(foregroundColor: Colors.deepOrange),
              child: const Text('Agregar Carro'),
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: widget.baseDeDatos.getDataStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<String> carList = snapshot.data!.map((data) {
                    String matricula = data['MATRICULA'].toString();
                    String marca = data['MARCA'].toString();
                    String modelo = data['MODELO'].toString();
                    String anio = data['ANIO'].toString();
                    return '$matricula $marca $modelo $anio';
                  }).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: carList.map((car) => Text(car)).toList(),
                  );
                } else if (snapshot.hasError) {
                  return const Text(
                      'Error al cargar los datos en tiempo real.');
                } else {
                  return const Text('Cargando datos...');
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.grey,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });

          if (_currentIndex == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => GastosPantalla(
                        baseDeDatos: widget.baseDeDatos,
                      )),
            );
          } else if (_currentIndex == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ConsultasPantalla(
                        baseDeDatos: widget.baseDeDatos,
                      )),
            );
          }
        },
        items: const [
          /* BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Vehiculos',
          ),*/
          BottomNavigationBarItem(
            icon: Icon(Icons.money),
            label: 'Categorias',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Gastos',
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: () {
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
                            ListView.builder(
                              shrinkWrap: true,
                              itemCount: matriculasList.length,
                              itemBuilder: (context, index) {
                                final matricula = matriculasList[index];
                                final marca = marcasList[index];
                                return Card(
                                  child: ListTile(
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(matriculasList[index]),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            _showEditarCarroModal(
                                              matricula: matriculasList[index],
                                              marca: marcasList[index],
                                              modelo: modelosList[index],
                                              anio: aniosList[index],
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () {
                                            _bloc.mapEventToState(
                                              EliminarCarroEvent(
                                                matricula: matricula,
                                              ),
                                            );
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      setState(() {
                                        selectedMatricula =
                                            matriculasList[index];
                                        selectedMarca = marca[index];
                                      });
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            backgroundColor: const Color.fromARGB(255, 241, 161, 137),
            tooltip: 'Eliminar',
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}

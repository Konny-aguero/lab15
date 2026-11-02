import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'data/database_helper.dart';
import 'services/hardware_service.dart';
import 'services/sync_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FieldTechApp());
}

class FieldTechApp extends StatelessWidget {
  const FieldTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FieldTech Móvil',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0284C7),
          brightness: Brightness.light,
        ),
      ),
      home: const IncidenciasScreen(),
    );
  }
}

class IncidenciasScreen extends StatefulWidget {
  const IncidenciasScreen({super.key});

  @override
  State<IncidenciasScreen> createState() => _IncidenciasScreenState();
}

class _IncidenciasScreenState extends State<IncidenciasScreen> {
  final SyncService _syncService = SyncService(
    backendUrl: const String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'http://10.59.59.60:8080',
    ),
  );

  List<Map<String, dynamic>> _incidencias = [];
  bool _cargando = false;
  int _filtro = -1;
  int _consulta = 0;

  @override
  void initState() {
    super.initState();
    _cargarIncidenciasLocales();
  }

  Future<void> _cargarIncidenciasLocales() async {
    final consulta = ++_consulta;
    final datos = await DatabaseHelper.instance.obtenerTodas(
      sincronizado: _filtro == -1 ? null : _filtro,
    );
    if (!mounted || consulta != _consulta) return;
    setState(() => _incidencias = datos);
  }

  Future<void> _sincronizar() async {
    setState(() => _cargando = true);
    final total = await _syncService.ejecutarSincronizacion('TEC-CR-001');
    await _cargarIncidenciasLocales();
    if (!mounted) return;
    setState(() => _cargando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            total > 0
                ? '¡Sincronización exitosa! ($total registros enviados).'
                : 'No hay registros pendientes o el servidor no respondió.',
          ),
          backgroundColor: total > 0 ? Colors.green[700] : Colors.orange[800],
        ),
      );
    }
  }

  void _abrirFormularioModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) =>
          NuevaIncidenciaModal(onGuardado: _cargarIncidenciasLocales),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FieldTech Inspecciones'),
        actions: [
          IconButton(
            icon: _cargando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sincronizar con Servidor',
            onPressed: _cargando ? null : _sincronizar,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: -1, label: Text('Todas')),
                ButtonSegment(value: 0, label: Text('Offline')),
                ButtonSegment(value: 1, label: Text('Sincronizadas')),
              ],
              selected: {_filtro},
              onSelectionChanged: (seleccion) {
                setState(() => _filtro = seleccion.first);
                _cargarIncidenciasLocales();
              },
            ),
          ),
          Expanded(
            child: _incidencias.isEmpty
                ? const Center(
                    child: Text(
                      'No hay inspecciones registradas.\nPresione + para crear una.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: _incidencias.length,
                    itemBuilder: (ctx, index) {
                      final item = _incidencias[index];
                      final bool sincronizado = item['is_synced'] == 1;
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: sincronizado
                                ? Colors.green[100]
                                : Colors.amber[100],
                            child: Icon(
                              sincronizado ? Icons.cloud_done : Icons.cloud_off,
                              color: sincronizado
                                  ? Colors.green[800]
                                  : Colors.amber[900],
                            ),
                          ),
                          title: Text(
                            item['titulo'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item['categoria']} | Lat: ${item['latitud']}, Lon: ${item['longitud']}',
                          ),
                          trailing: Text(
                            sincronizado ? 'En Servidor' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: sincronizado
                                  ? Colors.green[700]
                                  : Colors.amber[900],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormularioModal,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Nueva Incidencia'),
      ),
    );
  }
}

class NuevaIncidenciaModal extends StatefulWidget {
  final VoidCallback onGuardado;
  const NuevaIncidenciaModal({super.key, required this.onGuardado});

  @override
  State<NuevaIncidenciaModal> createState() => _NuevaIncidenciaModalState();
}

class _NuevaIncidenciaModalState extends State<NuevaIncidenciaModal> {
  final _tituloController = TextEditingController();
  final _descController = TextEditingController();
  final HardwareService _hardware = HardwareService();

  String _categoria = 'INFRAESTRUCTURA';
  Position? _posicion;
  File? _foto;
  bool _obteniendoGps = false;
  bool _guardando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _capturarGPS() async {
    setState(() => _obteniendoGps = true);
    try {
      final pos = await _hardware.capturarUbicacionGPS();
      if (mounted) setState(() => _posicion = pos);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _obteniendoGps = false);
    }
  }

  Future<void> _capturarCamara() async {
    try {
      final imagen = await _hardware.tomarFotografia();
      if (mounted && imagen != null) setState(() => _foto = imagen);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _guardarEnSQLite() async {
    if (_tituloController.text.trim().isEmpty || _posicion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debe ingresar un título y capturar las coordenadas GPS.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final row = {
      'titulo': _tituloController.text.trim(),
      'descripcion': _descController.text.trim(),
      'categoria': _categoria,
      'latitud': _posicion!.latitude,
      'longitud': _posicion!.longitude,
      'foto_path': _foto?.path,
      'is_synced': 0,
      'fecha_creacion': DateTime.now().toIso8601String(),
    };

    setState(() => _guardando = true);
    try {
      await DatabaseHelper.instance.insertar(row);
      widget.onGuardado();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Registrar Incidencia en Campo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tituloController,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Título de la Incidencia',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descController,
              maxLength: 500,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción técnica',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _categoria,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(
                  value: 'INFRAESTRUCTURA',
                  child: Text('Infraestructura'),
                ),
                DropdownMenuItem(
                  value: 'RED_ACCESO',
                  child: Text('Red de Acceso'),
                ),
                DropdownMenuItem(
                  value: 'TORRE_RADIO',
                  child: Text('Torre de Radio'),
                ),
              ],
              onChanged: (v) => setState(() => _categoria = v!),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _obteniendoGps ? null : _capturarGPS,
                    icon: _obteniendoGps
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(
                      _posicion != null
                          ? 'GPS: ${_posicion!.latitude.toStringAsFixed(3)}, ${_posicion!.longitude.toStringAsFixed(3)}'
                          : 'Obtener GPS',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  onPressed: _capturarCamara,
                  icon: const Icon(Icons.camera_alt),
                  tooltip: 'Tomar Fotografía',
                ),
              ],
            ),
            if (_foto != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(_foto!, height: 120, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _guardando ? null : _guardarEnSQLite,
              child: const Text('Guardar Localmente (Offline)'),
            ),
          ],
        ),
      ),
    );
  }
}

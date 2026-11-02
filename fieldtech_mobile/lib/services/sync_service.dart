import 'dart:io';

import 'package:http/http.dart' as http;

import '../data/database_helper.dart';

class SyncService {
  final String backendUrl;
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  SyncService({required this.backendUrl});

  Future<int> ejecutarSincronizacion(String codigoTecnico) async {
    final pendientes = await dbHelper.obtenerPendientes();
    int enviadasConExito = 0;
    final client = http.Client();
    try {
      for (final inc in pendientes) {
        try {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('$backendUrl/api/v1/incidencias'),
          );
          request.fields.addAll({
            'titulo': inc['titulo'] as String,
            'descripcion': inc['descripcion'] as String,
            'categoria': inc['categoria'] as String,
            'latitud': inc['latitud'].toString(),
            'longitud': inc['longitud'].toString(),
            'tecnicoCodigo': codigoTecnico,
          });
          final rutaFoto = inc['foto_path'] as String?;
          if (rutaFoto != null) {
            if (!await File(rutaFoto).exists()) break;
            request.files.add(
              await http.MultipartFile.fromPath('foto', rutaFoto),
            );
          }
          final response =
              await client.send(request).timeout(const Duration(seconds: 15));
          await response.stream.drain<void>().timeout(
                const Duration(seconds: 15),
              );
          if (response.statusCode != 200 && response.statusCode != 201) break;
          await dbHelper.marcarSincronizado(inc['id'] as int);
          enviadasConExito++;
        } catch (_) {
          break;
        }
      }
    } finally {
      client.close();
    }
    return enviadasConExito;
  }
}

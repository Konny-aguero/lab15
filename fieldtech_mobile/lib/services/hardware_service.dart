import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

class HardwareService {
  final ImagePicker _picker = ImagePicker();

  Future<Position> capturarUbicacionGPS() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      throw Exception('El sensor GPS del teléfono está desactivado.');
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        throw Exception('El usuario denegó el acceso al GPS.');
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      throw Exception('Permisos GPS denegados permanentemente en el sistema.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 12),
    );
  }

  Future<File?> tomarFotografia() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1200,
      imageQuality: 80,
    );

    if (imagen == null) return null;
    return File(imagen.path);
  }
}

package com.fieldtech.controller;

import com.fieldtech.business.IncidenciaService;
import com.fieldtech.domain.Incidencia;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.util.List;

@RestController
@RequestMapping("/api/v1/incidencias")
@CrossOrigin(origins = "*")
public class IncidenciaController {

    private final IncidenciaService service;

    public IncidenciaController(IncidenciaService service) {
        this.service = service;
    }

    @GetMapping
    public ResponseEntity<List<Incidencia>> listar() {
        return ResponseEntity.ok(service.listarTodas());
    }

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Incidencia> crearIncidenciaConFoto(
            @RequestParam("titulo") String titulo,
            @RequestParam("descripcion") String descripcion,
            @RequestParam("categoria") String categoria,
            @RequestParam("latitud") Double latitud,
            @RequestParam("longitud") Double longitud,
            @RequestParam("tecnicoCodigo") String tecnicoCodigo,
            @RequestParam(value = "foto", required = false) MultipartFile foto
    ) {
        Incidencia guardada = service.registrar(
                titulo, descripcion, categoria, latitud, longitud, tecnicoCodigo, foto
        );
        return ResponseEntity.status(HttpStatus.CREATED).body(guardada);
    }
}

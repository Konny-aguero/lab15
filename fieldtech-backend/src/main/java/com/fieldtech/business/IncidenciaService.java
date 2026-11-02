package com.fieldtech.business;

import com.fieldtech.data.IncidenciaRepository;
import com.fieldtech.domain.Incidencia;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Service
public class IncidenciaService {

    private final IncidenciaRepository repository;

    public IncidenciaService(IncidenciaRepository repository) {
        this.repository = repository;
    }

    public List<Incidencia> listarTodas() {
        return repository.findAll();
    }

    public Incidencia registrar(String titulo, String descripcion,
                                String categoria, Double latitud,
                                Double longitud, String tecnicoCodigo,
                                MultipartFile foto) {
        Incidencia inc = new Incidencia();
        inc.setTitulo(titulo);
        inc.setDescripcion(descripcion);
        inc.setCategoria(categoria);
        inc.setLatitud(latitud);
        inc.setLongitud(longitud);
        inc.setTecnicoCodigo(tecnicoCodigo);
        inc.setEstado("REGISTRADA");
        inc.setFechaReporte(LocalDateTime.now());

        if (foto != null && !foto.isEmpty()) {
            String nombreArchivo = UUID.randomUUID() + "_" + foto.getOriginalFilename();
            inc.setFotoUrl("uploads/evidencias/" + nombreArchivo);
        } else {
            inc.setFotoUrl(null);
        }

        return repository.save(inc);
    }
}

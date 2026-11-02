package com.fieldtech.data;

import com.fieldtech.domain.Incidencia;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface IncidenciaRepository extends JpaRepository<Incidencia, Long> {
    List<Incidencia> findByTecnicoCodigoOrderByFechaReporteDesc(String codigo);

}

/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Esp Nulo:          SELECT fun_update_tipo_especializacion(NULL, 'Cardio');
   2.  ID Esp Negativo:      SELECT fun_update_tipo_especializacion(-1, 'Cardio');
   3.  Nombre Vacío:         SELECT fun_update_tipo_especializacion(1, '');
   4.  Nombre Espacios:      SELECT fun_update_tipo_especializacion(1, '   ');
   5.  SQL Inj (Nom):        SELECT fun_update_tipo_especializacion(1, '''; DROP TABLE tab_espec; --');
   6.  ID Inexistente (999): SELECT fun_update_tipo_especializacion(99999, 'Cardio');
   7.  Soft Delet (ID 2):    SELECT fun_update_tipo_especializacion(2, 'Cardio');
   8.  Nombre NULL:          SELECT fun_update_tipo_especializacion(1, NULL);
   9.  ID Cero:              SELECT fun_update_tipo_especializacion(0, 'Cardio');
   10. CASO EXITOSO:         SELECT fun_update_tipo_especializacion(1, 'Cardiología Pediátrica');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_tipo_especializacion  (jid_especializacion tab_tipo_especializacion.id_especializacion%TYPE,
                                                            jnom_espec tab_tipo_especializacion.nom_espec%TYPE)
                                                            RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_especializacion IS NULL OR jid_especializacion <= 0 THEN
            RAISE NOTICE 'Error: ID de especialización inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_tipo_especializacion WHERE id_especializacion = jid_especializacion;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Especialización con ID % no encontrada.', jid_especializacion;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: La Especialización con ID % se encuentra eliminada. No se puede actualizar.', jid_especializacion;
            RETURN FALSE;
        END IF;

    -- Validar Nombre
        IF jnom_espec IS NULL OR TRIM(jnom_espec) = '' THEN 
            RAISE NOTICE 'Error: El nombre de la especialización no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
        UPDATE tab_tipo_especializacion 
        SET nom_espec = jnom_espec 
        WHERE id_especializacion = jid_especializacion;
        
        RAISE NOTICE 'Especialización actualizada exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

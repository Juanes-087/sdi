/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Estado Nulo:       SELECT fun_update_estado_fact(NULL, 'Pagada');
   2.  ID Estado Negos:      SELECT fun_update_estado_fact(-1, 'Pagada');
   3.  ID Fuera Rango (>4):  SELECT fun_update_estado_fact(5, 'Pagada');
   4.  Nom Vacío:            SELECT fun_update_estado_fact(1, '');
   5.  Nom Largo (>15):      SELECT fun_update_estado_fact(1, 'EstadoExtraordinariamenteLargo');
   6.  SQL Inj (Nom):        SELECT fun_update_estado_fact(1, '''; DELETE FROM tab_estado_fact; --');
   7.  Soft Delet (ID 4):    SELECT fun_update_estado_fact(4, 'Pagada');
   8.  Nom NULL:             SELECT fun_update_estado_fact(1, NULL);
   9.  ID Cero:              SELECT fun_update_estado_fact(0, 'Pagada');
   10. CASO EXITOSO:         SELECT fun_update_estado_fact(1, 'Pagada OK');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_estado_fact   (jid_estado_fact tab_estado_fact.id_estado_fact%TYPE,
                                                    jnom_estado_fact tab_estado_fact.nom_estado_fact%TYPE)
                                                    RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_estado_fact IS NULL OR jid_estado_fact <= 0 THEN
            RAISE NOTICE 'Error: ID de estado inválido.';
            RETURN FALSE;
        END IF;
        
        -- Validar Rango Específico (Regla de negocio existente en DB)
        IF jid_estado_fact > 4 THEN 
            RAISE NOTICE 'Error: ID de estado inválido (Máximo permitido es 4).'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_estado_fact WHERE id_estado_fact = jid_estado_fact;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Estado de factura con ID % no encontrado.', jid_estado_fact;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Estado de factura con ID % se encuentra eliminado. No se puede actualizar.', jid_estado_fact;
            RETURN FALSE;
        END IF;

    -- Validar Nombre
        IF jnom_estado_fact IS NULL OR TRIM(jnom_estado_fact) = '' THEN 
            RAISE NOTICE 'Error: El nombre del estado no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;
        IF LENGTH(jnom_estado_fact) > 15 THEN 
            RAISE NOTICE 'Error: El nombre del estado excede los 15 caracteres.'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
        UPDATE tab_estado_fact 
        SET nom_estado_fact = jnom_estado_fact 
        WHERE id_estado_fact = jid_estado_fact;
        
        RAISE NOTICE 'Estado de factura actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

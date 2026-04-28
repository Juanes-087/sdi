/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Kardex Nulo:       SELECT fun_update_kardex_mat_prima(NULL, 1, 1, 10, NOW(), 'Obs');
   2.  ID Kardex Neg:        SELECT fun_update_kardex_mat_prima(-1, 1, 1, 10, NOW(), 'Obs');
   3.  MP Nulo:              SELECT fun_update_kardex_mat_prima(1, NULL, 1, 10, NOW(), 'Obs');
   4.  MP Inexistente:       SELECT fun_update_kardex_mat_prima(1, 99999, 1, 10, NOW(), 'Obs');
   5.  Tipo Mov Inv (5):     SELECT fun_update_kardex_mat_prima(1, 1, 5, 10, NOW(), 'Obs');
   6.  Cantidad Negativa:    SELECT fun_update_kardex_mat_prima(1, 1, 1, -10, NOW(), 'Obs');
   7.  Fecha Nula:           SELECT fun_update_kardex_mat_prima(1, 1, 1, 10, NULL, 'Obs');
   8.  ID Inexistente (999): SELECT fun_update_kardex_mat_prima(99999, 1, 1, 10, NOW(), 'Obs');
   9.  Soft Deleted (2):     SELECT fun_update_kardex_mat_prima(2, 1, 1, 10, NOW(), 'Obs');
   10. CASO EXITOSO:         SELECT fun_update_kardex_mat_prima(1, 1, 1, 50, CURRENT_TIMESTAMP, 'Corrección Inventario');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_kardex_mat_prima  (jid_kardex_mat_prima tab_kardex_mat_prima.id_kardex_mat_prima%TYPE,
                                                        jid_materia_prima tab_kardex_mat_prima.id_materia_prima%TYPE,
                                                        jtipo_movimiento tab_kardex_mat_prima.tipo_movimiento%TYPE,
                                                        jcantidad tab_kardex_mat_prima.cantidad%TYPE,
                                                        jfecha_movimiento tab_kardex_mat_prima.fecha_movimiento%TYPE,
                                                        jobservaciones tab_kardex_mat_prima.observaciones%TYPE)
                                                        RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_kardex_mat_prima IS NULL OR jid_kardex_mat_prima <= 0 THEN 
            RAISE NOTICE 'Error: ID Kardex inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_kardex_mat_prima WHERE id_kardex_mat_prima = jid_kardex_mat_prima;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Kardex MP con ID % no encontrado.', jid_kardex_mat_prima;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Kardex MP con ID % se encuentra eliminado. No se puede actualizar.', jid_kardex_mat_prima;
            RETURN FALSE;
        END IF;

    -- Validar FK Materia Prima
        IF jid_materia_prima IS NULL OR jid_materia_prima <= 0 THEN 
            RAISE NOTICE 'Error: ID Materia Prima inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_materias_primas WHERE id_mat_prima = jid_materia_prima;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Materia Prima no existe o inactiva.'; 
            RETURN FALSE; 
        END IF;

    -- Validaciones Logicas
        IF jtipo_movimiento <= 0 OR jtipo_movimiento > 4 THEN 
            RAISE NOTICE 'Error: Tipo de movimiento inválido (1-4).'; 
            RETURN FALSE; 
        END IF;

        IF jcantidad <= 0 THEN 
            RAISE NOTICE 'Error: La cantidad debe ser positiva.'; 
            RETURN FALSE; 
        END IF;

        IF jfecha_movimiento IS NULL THEN 
            RAISE NOTICE 'Error: La fecha de movimiento no puede ser nula.'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
        UPDATE tab_kardex_mat_prima SET
            id_materia_prima = jid_materia_prima,
            tipo_movimiento = jtipo_movimiento,
            cantidad = jcantidad,
            fecha_movimiento = jfecha_movimiento,
            observaciones = jobservaciones
        WHERE id_kardex_mat_prima = jid_kardex_mat_prima;
        
        RAISE NOTICE 'Kardex MP actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

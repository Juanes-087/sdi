/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Mov Nulo:          SELECT fun_update_mov_bodega(NULL, 1, 1, NOW(), NULL);
   2.  ID Mov Negativo:      SELECT fun_update_mov_bodega(-1, 1, 1, NOW(), NULL);
   3.  ID Prov Nulo:         SELECT fun_update_mov_bodega(1, NULL, 1, NOW(), NULL);
   4.  ID MP Nulo:           SELECT fun_update_mov_bodega(1, 1, NULL, NOW(), NULL);
   5.  Rel P-M Inex:         SELECT fun_update_mov_bodega(1, 999, 999, NOW(), NULL);
   6.  Fecha Ingreso Nula:   SELECT fun_update_mov_bodega(1, 1, 1, NULL, NULL);
   7.  Fecha Salida < Ing:   SELECT fun_update_mov_bodega(1, 1, 1, '2024-12-31', '2024-01-01');
   8.  ID Mov Inex:          SELECT fun_update_mov_bodega(99999, 1, 1, NOW(), NULL);
   9.  Soft Deleted Rel:     SELECT fun_update_mov_bodega(1, 1, 1, NOW(), NULL); -- Assuming Rel is SD
   10. CASO EXITOSO:         SELECT fun_update_mov_bodega(1, 1, 1, CURRENT_TIMESTAMP, NULL);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_mov_bodega (jid_movimiento tab_bodega.id_movimiento%TYPE,
                                                 jid_prov tab_bodega.id_prov%TYPE,
                                                 jid_mat_prima tab_bodega.id_mat_prima%TYPE,
                                                 jfec_ingreso tab_bodega.fec_ingreso%TYPE,
                                                 jfec_salida tab_bodega.fec_salida%TYPE)
                                                 RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_movimiento IS NULL OR jid_movimiento <= 0 THEN 
            RAISE NOTICE 'Error: ID Movimiento inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_bodega WHERE id_movimiento = jid_movimiento;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Movimiento en Bodega con ID % no encontrado.', jid_movimiento;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Movimiento con ID % se encuentra eliminado. No se puede actualizar.', jid_movimiento;
            RETURN FALSE;
        END IF;

    -- Validar FK Compuesta (Mat Prima - Prov)
        IF jid_prov IS NULL OR jid_prov <= 0 THEN 
            RAISE NOTICE 'Error: ID Proveedor inválido.'; 
            RETURN FALSE; 
        END IF;

        IF jid_mat_prima IS NULL OR jid_mat_prima <= 0 THEN 
            RAISE NOTICE 'Error: ID Materia Prima inválido.'; 
            RETURN FALSE; 
        END IF;
        
        SELECT ind_vivo INTO j_ind_vivo_fk 
        FROM tab_mat_primas_prov 
        WHERE id_prov = jid_prov AND id_mat_prima = jid_mat_prima;

        IF j_ind_vivo_fk IS NULL THEN
            RAISE NOTICE 'Error: La relación Materia Prima - Proveedor no existe.';
            RETURN FALSE;
        END IF;

        IF j_ind_vivo_fk = FALSE THEN
            RAISE NOTICE 'Error: La relación Materia Prima - Proveedor está inactiva.';
            RETURN FALSE;
        END IF;

    -- Validar Fechas
        IF jfec_ingreso IS NULL THEN 
            RAISE NOTICE 'Error: Fecha de ingreso no puede ser nula.'; 
            RETURN FALSE; 
        END IF;

        IF jfec_salida IS NOT NULL AND jfec_salida < jfec_ingreso THEN
            RAISE NOTICE 'Error: La fecha de salida no puede ser anterior a la de ingreso.'; 
            RETURN FALSE;
        END IF;

    -- Actualizar
        UPDATE tab_bodega SET
            id_prov = jid_prov,
            id_mat_prima = jid_mat_prima,
            fec_ingreso = jfec_ingreso,
            fec_salida = jfec_salida
        WHERE id_movimiento = jid_movimiento;
        
        RAISE NOTICE 'Movimiento de bodega actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

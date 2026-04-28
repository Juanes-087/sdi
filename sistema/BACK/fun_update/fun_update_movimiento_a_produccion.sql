/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Prod Nulo:         SELECT fun_update_mov_producc(NULL, 1, NOW());
   2.  ID Prod Negativo:     SELECT fun_update_mov_producc(-1, 1, NOW());
   3.  ID Mov Nulo:          SELECT fun_update_mov_producc(1, NULL, NOW());
   4.  ID Mov Negativo:      SELECT fun_update_mov_producc(1, -5, NOW());
   5.  Fecha Nula:           SELECT fun_update_mov_producc(1, 1, NULL);
   6.  ID Prod Inexistente:  SELECT fun_update_mov_producc(99999, 1, NOW());
   7.  ID Mov Inexistente:   SELECT fun_update_mov_producc(1, 99999, NOW());
   8.  Soft Deleted Prod:    SELECT fun_update_mov_producc(2, 1, NOW());
   9.  Soft Deleted Mov:     SELECT fun_update_mov_producc(1, 2, NOW());
   10. CASO EXITOSO:         SELECT fun_update_mov_producc(1, 1, CURRENT_TIMESTAMP);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_mov_producc   (jid_producc tab_producc.id_producc%TYPE,
                                                    jid_movimiento tab_producc.id_movimiento%TYPE,
                                                    jfec_ingreso tab_producc.fec_ingreso%TYPE)
                                                    RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_producc IS NULL OR jid_producc <= 0 THEN 
            RAISE NOTICE 'Error: ID Producción inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_producc WHERE id_producc = jid_producc;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Registro de producción con ID % no encontrado.', jid_producc;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El registro de producción con ID % se encuentra eliminado. No se puede actualizar.', jid_producc;
            RETURN FALSE;
        END IF;

    -- Validar FK Movimiento Bodega
        IF jid_movimiento IS NULL OR jid_movimiento <= 0 THEN 
            RAISE NOTICE 'Error: ID Movimiento Bodega inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_bodega WHERE id_movimiento = jid_movimiento;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: El movimiento de bodega origen no existe o está inactivo.'; 
            RETURN FALSE; 
        END IF;

    -- Validar Fecha
        IF jfec_ingreso IS NULL THEN 
            RAISE NOTICE 'Error: La fecha de ingreso no puede ser nula.'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
        UPDATE tab_producc SET
            id_movimiento = jid_movimiento,
            fec_ingreso = jfec_ingreso
        WHERE id_producc = jid_producc;
        
        RAISE NOTICE 'Movimiento a producción actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

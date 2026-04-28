/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Mov Nulo:          SELECT fun_delete_mov_bodega(NULL);
   2.  ID Mov Negativo:      SELECT fun_delete_mov_bodega(-1);
   3.  ID Mov Cero:          SELECT fun_delete_mov_bodega(0);
   4.  ID Inexistente:       SELECT fun_delete_mov_bodega(99999);
   5.  Ya eliminado:         SELECT fun_delete_mov_bodega(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_mov_bodega(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_mov_bodega(2147483647);
   8.  Min Int Value:        SELECT fun_delete_mov_bodega(-2147483648);
   9.  Float Cast:           SELECT fun_delete_mov_bodega(1.01::INT);
   10. CASO EXITOSO:         SELECT fun_delete_mov_bodega(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_mov_bodega(jid_movimiento tab_bodega.id_movimiento%TYPE)
                                                 RETURNS BOOLEAN AS
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_movimiento IS NULL THEN
            RAISE NOTICE 'Error: ID de movimiento nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_movimiento <= 0 THEN
            RAISE NOTICE 'Error: ID de movimiento inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_bodega WHERE id_movimiento = jid_movimiento;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Movimiento en bodega con ID % no encontrado.', jid_movimiento;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El Movimiento en bodega con ID % ya fue eliminado anteriormente.', jid_movimiento;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_bodega SET   user_delete = CURRENT_USER,
                                fec_delete = CURRENT_TIMESTAMP,
                                ind_vivo = FALSE
                                Where id_movimiento = jid_movimiento;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el Movimiento en bodega con ID %.', jid_movimiento;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Movimiento en bodega con ID % eliminado exitosamente.', jid_movimiento;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
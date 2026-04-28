/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Mov Nulo:          SELECT fun_delete_mov_producc(NULL);
   2.  ID Mov Negativo:      SELECT fun_delete_mov_producc(-1);
   3.  ID Mov Cero:          SELECT fun_delete_mov_producc(0);
   4.  ID Inexistente:       SELECT fun_delete_mov_producc(99999);
   5.  Ya eliminado:         SELECT fun_delete_mov_producc(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_mov_producc(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_mov_producc(2147483647);
   8.  Min Int Value:        SELECT fun_delete_mov_producc(-2147483648);
   9.  Float Cast:           SELECT fun_delete_mov_producc(1.99::INT);
   10. CASO EXITOSO:         SELECT fun_delete_mov_producc(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_mov_producc(jid_producc tab_producc.id_producc%TYPE)
                                                  RETURNS BOOLEAN AS
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_producc IS NULL THEN
            RAISE NOTICE 'Error: ID de movimiento nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_producc <= 0 THEN
            RAISE NOTICE 'Error: ID de movimiento inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_producc WHERE id_producc = jid_producc;

    -- 1. Verificar existencia física (Si es NULL, no encontró el registro)
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Movimiento a producción con ID % no encontrado físicamente.', jid_producc;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico (Si es FALSE, ya estaba borrado)
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El Movimiento a producción con ID % ya fue eliminado anteriormente.', jid_producc;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_producc SET  user_delete = CURRENT_USER,
                                fec_delete = CURRENT_TIMESTAMP,
                                ind_vivo = FALSE
                                Where id_producc = jid_producc;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el Movimiento a producción con ID %.', jid_producc;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Movimiento a producción con ID % eliminado exitosamente.', jid_producc;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Hist Nulo:         SELECT fun_delete_historico_mat_prima(NULL);
   2.  ID Hist Negativo:     SELECT fun_delete_historico_mat_prima(-1);
   3.  ID Hist Cero:         SELECT fun_delete_historico_mat_prima(0);
   4.  ID Inexistente:       SELECT fun_delete_historico_mat_prima(99999);
   5.  Ya eliminado:         SELECT fun_delete_historico_mat_prima(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_historico_mat_prima(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_historico_mat_prima(2147483647);
   8.  Min Int Value:        SELECT fun_delete_historico_mat_prima(-2147483648);
   9.  SQL Inj Sim:          SELECT fun_delete_historico_mat_prima(1 OR 1=1);
   10. CASO EXITOSO:         SELECT fun_delete_historico_mat_prima(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_historico_mat_prima(jid_historico tab_historico_mat_prima.id_historico%TYPE) 
                                                          RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_historico IS NULL THEN
            RAISE NOTICE 'Error: El ID del histórico es obligatorio.';
            RETURN FALSE;
        END IF;

        IF jid_historico <= 0 THEN
            RAISE NOTICE 'Error: El ID del histórico debe ser mayor a 0.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_historico_mat_prima WHERE id_historico = jid_historico;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Histórico con ID % no encontrado.', jid_historico;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El histórico con ID % ya fue eliminado anteriormente.', jid_historico;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_historico_mat_prima SET user_delete = CURRENT_USER,
                                           fec_delete = CURRENT_TIMESTAMP,
                                           ind_vivo = FALSE
                                           Where id_historico = jid_historico;

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el histórico con ID %.', jid_historico;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Histórico con ID % eliminado exitosamente.', jid_historico;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;

/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Mat Nulo:          SELECT fun_delete_materias_primas(NULL);
   2.  ID Mat Negativo:      SELECT fun_delete_materias_primas(-1);
   3.  ID Mat Cero:          SELECT fun_delete_materias_primas(0);
   4.  ID Inexistente:       SELECT fun_delete_materias_primas(99999);
   5.  Ya eliminado:         SELECT fun_delete_materias_primas(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_materias_primas(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_materias_primas(2147483647);
   8.  Min Int Value:        SELECT fun_delete_materias_primas(-2147483648);
   9.  Float Cast:           SELECT fun_delete_materias_primas(1.2::INT);
   10. CASO EXITOSO:         SELECT fun_delete_materias_primas(1);
   -----------------------------------------------------------------------------
*/
DROP FUNCTION IF EXISTS fun_delete_mat_prim(tab_materias_primas.id_mat_prima%TYPE);
CREATE OR REPLACE FUNCTION fun_delete_materias_primas(jid_mat_prima tab_materias_primas.id_mat_prima%TYPE) 
                                               RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_mat_prima IS NULL THEN
            RAISE NOTICE 'Error: ID de materia prima nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_mat_prima <= 0 THEN
            RAISE NOTICE 'Error: ID de materia prima inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_materias_primas WHERE id_mat_prima = jid_mat_prima;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Materia prima con ID % no encontrada.', jid_mat_prima;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: La Materia prima con ID % ya fue eliminada anteriormente.', jid_mat_prima;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_materias_primas SET user_delete = CURRENT_USER,
                                       fec_delete = CURRENT_TIMESTAMP,
                                       ind_vivo = FALSE
                                       Where id_mat_prima = jid_mat_prima;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar la Materia prima con ID %.', jid_mat_prima;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Materia prima con ID % eliminada exitosamente.', jid_mat_prima;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
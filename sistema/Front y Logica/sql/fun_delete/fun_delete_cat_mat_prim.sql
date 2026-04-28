/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Cat Nulo:          SELECT fun_delete_cat_mat_prim(NULL);
   2.  ID Cat Negativo:      SELECT fun_delete_cat_mat_prim(-1);
   3.  ID Cat Cero:          SELECT fun_delete_cat_mat_prim(0);
   4.  ID Inexistente:       SELECT fun_delete_cat_mat_prim(99999);
   5.  Ya eliminado:         SELECT fun_delete_cat_mat_prim(2); -- Asumiendo ID 2 eliminado
   6.  Con Hijos (Error):    SELECT fun_delete_cat_mat_prim(3); -- Si tiene materias asociadas
   7.  Max Int Value:        SELECT fun_delete_cat_mat_prim(2147483647);
   8.  Null Cast:            SELECT fun_delete_cat_mat_prim(NULL::INT);
   9.  Min Int Value:        SELECT fun_delete_cat_mat_prim(-2147483648);
   10. CASO EXITOSO:         SELECT fun_delete_cat_mat_prim(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_cat_mat_prim(jid_cat_mat tab_cat_mat_prim.id_cat_mat%TYPE) 
                                                   RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_cat_mat IS NULL THEN
            RAISE NOTICE 'Error: El ID de la categoría es obligatorio.';
            RETURN FALSE;
        END IF;

        IF jid_cat_mat <= 0 THEN
            RAISE NOTICE 'Error: El ID de la categoría debe ser mayor a 0.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_cat_mat_prim WHERE id_cat_mat = jid_cat_mat;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Categoría con ID % no encontrada.', jid_cat_mat;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: La categoría con ID % ya fue eliminada anteriormente.', jid_cat_mat;
            RETURN FALSE;
        END IF;

    -- 3. Verificar Hijos (Integridad Referencial)
        IF EXISTS (Select 1 From tab_materias_primas Where id_cat_mat = jid_cat_mat AND ind_vivo = TRUE) THEN
            RAISE NOTICE 'Error: No se puede eliminar, existen materias primas asociadas a esta categoría (ID %).', jid_cat_mat;
            RETURN FALSE;
        END IF;

    -- 4. Hacer el soft delete
        UPDATE tab_cat_mat_prim SET user_delete = CURRENT_USER,
                                    fec_delete = CURRENT_TIMESTAMP,
                                    ind_vivo = FALSE
                                    Where id_cat_mat = jid_cat_mat;

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar la categoría con ID %.', jid_cat_mat;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Categoría con ID % eliminada exitosamente.', jid_cat_mat;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;

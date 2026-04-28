/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Cat Nulo:          SELECT fun_update_cat_mat_prim(NULL, 'Materiales');
   2.  ID Cat Negativo:      SELECT fun_update_cat_mat_prim(-10, 'Materiales');
   3.  Nombre Vacío:         SELECT fun_update_cat_mat_prim(1, '');
   4.  Nombre Solo Espacios: SELECT fun_update_cat_mat_prim(1, '     ');
   5.  SQL Inj (Comment):    SELECT fun_update_cat_mat_prim(1, 'Metal'); --');
   6.  SQL Inj (Drop):       SELECT fun_update_cat_mat_prim(1, '''; DROP TABLE tab_cat_mat_prim; --');
   7.  ID Inexistente (999): SELECT fun_update_cat_mat_prim(99999, 'Materiales');
   8.  Soft Deleted (ID 2):  SELECT fun_update_cat_mat_prim(2, 'Materiales');
   9.  Nombre NULL:          SELECT fun_update_cat_mat_prim(1, NULL);
   10. CASO EXITOSO:         SELECT fun_update_cat_mat_prim(1, 'Polímeros Avanzados');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_cat_mat_prim  (jid_cat_mat tab_cat_mat_prim.id_cat_mat%TYPE,
                                                    jnom_categoria tab_cat_mat_prim.nom_categoria%TYPE)
                                                    RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_cat_mat IS NULL OR jid_cat_mat <= 0 THEN
            RAISE NOTICE 'Error: ID de categoría inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_cat_mat_prim WHERE id_cat_mat = jid_cat_mat;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Categoría con ID % no encontrada.', jid_cat_mat;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: La Categoría con ID % se encuentra eliminada. No se puede actualizar.', jid_cat_mat;
            RETURN FALSE;
        END IF;
        
    -- Validar Nombre
        IF jnom_categoria IS NULL OR TRIM(jnom_categoria) = '' THEN
            RAISE NOTICE 'Error: El nombre de la categoría no puede estar vacío.';
            RETURN FALSE;
        END IF;

    -- Actualizar
        UPDATE tab_cat_mat_prim 
        SET nom_categoria = jnom_categoria 
        WHERE id_cat_mat = jid_cat_mat;
        
        RAISE NOTICE 'Categoría actualizada exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

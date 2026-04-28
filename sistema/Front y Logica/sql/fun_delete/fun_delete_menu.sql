/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Menu Nulo:         SELECT fun_delete_menu(NULL);
   2.  ID Menu Negativo:     SELECT fun_delete_menu(-1);
   3.  ID Menu Cero:         SELECT fun_delete_menu(0);
   4.  ID Inexistente:       SELECT fun_delete_menu(99999);
   5.  Ya eliminado:         SELECT fun_delete_menu(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_menu(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_menu(2147483647);
   8.  Min Int Value:        SELECT fun_delete_menu(-2147483648);
   9.  SQL Inyection:        SELECT fun_delete_menu(1 OR 1=1);
   10. CASO EXITOSO:         SELECT fun_delete_menu(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_menu(jid_menu tab_menu.id_menu%TYPE) 
                                           RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_menu IS NULL THEN
            RAISE NOTICE 'Error: ID de menú nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_menu <= 0 THEN
            RAISE NOTICE 'Error: ID de menú inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_menu WHERE id_menu = jid_menu;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Menú con ID % no encontrado.', jid_menu;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El Menú con ID % ya fue eliminado anteriormente.', jid_menu;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_menu SET    user_delete = CURRENT_USER,
                                fec_delete = CURRENT_TIMESTAMP,
                                ind_vivo = FALSE
                                Where id_menu = jid_menu;

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el menú con ID %.', jid_menu;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Menú con ID % eliminado exitosamente.', jid_menu;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
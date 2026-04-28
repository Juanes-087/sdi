/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID User Nulo:         SELECT fun_delete_menu_user(NULL, 1);
   2.  ID Menu Nulo:         SELECT fun_delete_menu_user(1, NULL);
   3.  ID User Negativo:     SELECT fun_delete_menu_user(-1, 1);
   4.  ID Menu Negativo:     SELECT fun_delete_menu_user(1, -1);
   5.  ID User Cero:         SELECT fun_delete_menu_user(0, 1);
   6.  ID Menu Cero:         SELECT fun_delete_menu_user(1, 0);
   7.  Ambos Nulos:          SELECT fun_delete_menu_user(NULL, NULL);
   8.  Rel Inexistente:      SELECT fun_delete_menu_user(99999, 99999);
   9.  Ya eliminado:         SELECT fun_delete_menu_user(2, 1);
   10. CASO EXITOSO:         SELECT fun_delete_menu_user(1, 1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_menu_user(jid_user tab_users_menu.id_user%TYPE,
                                                jid_menu tab_users_menu.id_menu%TYPE) 
                                                RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_user IS NULL OR jid_menu IS NULL THEN
            RAISE NOTICE 'Error: IDs nulos.';
            RETURN FALSE;
        END IF;
        
        IF jid_user <= 0 OR jid_menu <= 0 THEN
            RAISE NOTICE 'Error: IDs inválidos.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo 
        FROM tab_users_menu 
        Where id_user = jid_user AND id_menu = jid_menu;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Relación Menú-usuario no encontrada.';
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: La Relación Menú-usuario ya fue eliminada anteriormente.';
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_users_menu SET     user_delete = CURRENT_USER,
                                      fec_delete = CURRENT_TIMESTAMP,
                                      ind_vivo = FALSE
                                      Where id_user = jid_user
                                      AND id_menu = jid_menu;

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar la Relación menú-usuario.';
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Relación Menú-usuario eliminada exitosamente.';
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
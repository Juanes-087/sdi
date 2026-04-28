/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID User Nulo:         SELECT fun_update_users_menu(NULL, 1, 'Prog');
   2.  ID User Negativo:     SELECT fun_update_users_menu(-1, 1, 'Prog');
   3.  ID Menu Nulo:         SELECT fun_update_users_menu(1, NULL, 'Prog');
   4.  ID Menu Negativo:     SELECT fun_update_users_menu(1, -5, 'Prog');
   5.  Prog Vacío:           SELECT fun_update_users_menu(1, 1, '');
   6.  Prog Espacios:        SELECT fun_update_users_menu(1, 1, '   ');
   7.  SQL Inj (Prog):       SELECT fun_update_users_menu(1, 1, '''; DROP TABLE tab_users_menu; --');
   8.  Rel Inexistente:      SELECT fun_update_users_menu(99999, 1, 'Prog');
   9.  Soft Deleted Rel:     SELECT fun_update_users_menu(2, 1, 'Prog');
   10. CASO EXITOSO:         SELECT fun_update_users_menu(1, 1, 'Acceso Total Supervisado');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_users_menu(jid_user tab_users_menu.id_user%TYPE,
                                                 jid_menu tab_users_menu.id_menu%TYPE,
                                                 jnom_prog tab_users_menu.nom_prog%TYPE)
                                                 RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validar IDs
        IF jid_user IS NULL OR jid_user <= 0 THEN 
            RAISE NOTICE 'Error: ID de usuario inválido.'; 
            RETURN FALSE; 
        END IF;

        IF jid_menu IS NULL OR jid_menu <= 0 THEN 
            RAISE NOTICE 'Error: ID de menú inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado (Composite Key)
        SELECT ind_vivo INTO j_ind_vivo 
        FROM tab_users_menu 
        WHERE id_user = jid_user AND id_menu = jid_menu;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Asignación de Usuario-Menú no encontrada.';
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: La Asignación de Usuario-Menú se encuentra eliminada. No se puede actualizar.';
            RETURN FALSE;
        END IF;

    -- Validar Nombre Programa
        IF jnom_prog IS NULL OR TRIM(jnom_prog) = '' THEN 
            RAISE NOTICE 'Error: El nombre del programa no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
        UPDATE tab_users_menu 
        SET nom_prog = jnom_prog 
        WHERE id_user = jid_user AND id_menu = jid_menu;
        
        RAISE NOTICE 'Asignación Usuario-Menú actualizada exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

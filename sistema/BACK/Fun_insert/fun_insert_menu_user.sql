CREATE OR REPLACE FUNCTION fun_insert_menu_user (jid_user tab_users_menu.id_user%TYPE,
                                                 jid_menu tab_users_menu.id_menu%TYPE,
                                                 jnom_prog tab_users_menu.nom_prog%TYPE) 
                                                 RETURNS BOOLEAN AS
$$
    DECLARE j_check_val INTEGER;

BEGIN
    -- Validaciones Parametros
        IF jid_user IS NULL OR jid_user <= 0 THEN 
            RAISE NOTICE 'Error: ID Usuario inválido.'; 
            RETURN FALSE; 
        END IF;

        IF jid_menu IS NULL OR jid_menu <= 0 THEN 
            RAISE NOTICE 'Error: ID Menú inválido.'; 
            RETURN FALSE; 
        END IF;

        IF jnom_prog IS NULL OR TRIM(jnom_prog) = '' THEN
            RAISE NOTICE 'Error: Nombre del programa vacío.';
            RETURN FALSE;
        END IF;

    -- Validar Existencia
        SELECT 1 INTO j_check_val FROM tab_users WHERE id_user = jid_user LIMIT 1;
        
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: Usuario no existe.';
            RETURN FALSE;
        END IF;

        SELECT 1 INTO j_check_val FROM tab_menu WHERE id_menu = jid_menu LIMIT 1;
        
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: Menú no existe.';
            RETURN FALSE;
        END IF;

    -- Insertar Relación
        INSERT INTO tab_users_menu (id_user, id_menu, nom_prog) 
        VALUES (jid_user, jid_menu, TRIM(jnom_prog));

        RAISE NOTICE 'Permiso Menú-Usuario registrado.';
        RETURN TRUE;

EXCEPTION
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Este usuario ya tiene acceso a ese menú.'; 
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error inesperado: %', SQLERRM; 
        RETURN FALSE;
END;
$$ 
LANGUAGE plpgsql;

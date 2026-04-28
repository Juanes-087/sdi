/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID User Nulo:         SELECT fun_update_users(NULL, 'User', 'Pass', 300, 'm@m.com');
   2.  ID User Negativo:     SELECT fun_update_users(-1, 'User', 'Pass', 300, 'm@m.com');
   3.  Nombre Vacío:         SELECT fun_update_users(1, '', 'Pass', 300, 'm@m.com');
   4.  Pass Vacía:           SELECT fun_update_users(1, 'User', '', 300, 'm@m.com');
   5.  Pass Corta (<6):      SELECT fun_update_users(1, 'User', '123', 300, 'm@m.com');
   6.  Email Inválido:       SELECT fun_update_users(1, 'User', 'Pass', 300, 'badmail');
   7.  Teléfono Nulo:        SELECT fun_update_users(1, 'User', 'Pass', NULL, 'm@m.com');
   8.  ID Inexistente:       SELECT fun_update_users(99999, 'User', 'Pass', 300, 'm@m.com');
   9.  Soft Deleted:         SELECT fun_update_users(2, 'User', 'Pass', 300, 'm@m.com');
   10. CASO EXITOSO:         SELECT fun_update_users(1, 'AdminMaster', 'NewStrongPass123', 3209998877, 'admin.master@empresa.com');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_users (jid_user tab_users.id_user%TYPE,
                                            jnom_user tab_users.nom_user%TYPE,
                                            jpass_user tab_users.pass_user%TYPE,
                                            jtel_user tab_users.tel_user%TYPE,
                                            jmail_user tab_users.mail_user%TYPE)
                                            RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            existe_duplicado BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_user IS NULL OR jid_user <= 0 THEN
            RAISE NOTICE 'Error: ID de usuario inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_users WHERE id_user = jid_user;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Usuario con ID % no encontrado.', jid_user;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Usuario con ID % se encuentra eliminado. No se puede actualizar.', jid_user;
            RETURN FALSE;
        END IF;

    -- Validar Nombre
        IF jnom_user IS NULL OR TRIM(jnom_user) = '' THEN 
            RAISE NOTICE 'Error: El nombre de usuario no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;
    -- Verificar duplicado nombre
        SELECT EXISTS(SELECT 1 FROM tab_users WHERE nom_user = jnom_user AND id_user != jid_user AND ind_vivo=TRUE) INTO existe_duplicado;
        IF existe_duplicado THEN 
            RAISE NOTICE 'Error: El nombre de usuario "%" ya está registrado por otro usuario.', jnom_user; 
            RETURN FALSE; 
        END IF;

    -- Validar Password
        IF jpass_user IS NULL OR TRIM(jpass_user) = '' THEN 
            RAISE NOTICE 'Error: La contraseña no puede estar vacía.'; 
            RETURN FALSE; 
        END IF;
        IF LENGTH(jpass_user) < 6 THEN 
            RAISE NOTICE 'Error: La contraseña es muy corta (mínimo 6 caracteres).'; 
            RETURN FALSE; 
        END IF;

    -- Validar Password
        IF jpass_user !~ '^(?=.*[A-Z])(?=.*[0-9])' THEN 
            RAISE NOTICE 'Error: Contraseña debe tener Mayúscula y Número.'; 
            RETURN FALSE; 
        END IF;

    -- Validar Telefono
        IF jtel_user IS NULL OR jtel_user !~ '^[0-9]{7,10}$' THEN 
            RAISE NOTICE 'Error: Teléfono inválido (debe tener entre 7 y 10 dígitos numéricos).'; 
            RETURN FALSE; 
        END IF;
    -- Verificar duplicado telefono
        SELECT EXISTS(SELECT 1 FROM tab_users WHERE tel_user = jtel_user AND id_user != jid_user AND ind_vivo=TRUE) INTO existe_duplicado;
        IF existe_duplicado THEN 
            RAISE NOTICE 'Error: El teléfono de usuario ya está registrado.'; 
            RETURN FALSE; 
        END IF;

    -- Validar Email
        IF jmail_user IS NULL OR TRIM(jmail_user) = '' THEN 
            RAISE NOTICE 'Error: El email no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;
        IF jmail_user !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN 
            RAISE NOTICE 'Error: Formato de email inválido.'; 
            RETURN FALSE; 
        END IF;
    -- Verificar duplicado email
        SELECT EXISTS(SELECT 1 FROM tab_users WHERE mail_user = jmail_user AND id_user != jid_user AND ind_vivo=TRUE) INTO existe_duplicado;
        IF existe_duplicado THEN 
            RAISE NOTICE 'Error: El email ya está registrado.'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
        UPDATE tab_users SET 
            nom_user = jnom_user, 
            pass_user = jpass_user, 
            tel_user = jtel_user, 
            mail_user = jmail_user 
        WHERE id_user = jid_user;
        
        RAISE NOTICE 'Usuario actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

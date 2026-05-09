--Select fun_insert_user('Juanes', 'Pass123', '3102278149', 'hola12@gmail.com')

drop function if exists fun_insert_user;

CREATE OR REPLACE FUNCTION fun_insert_user  (jnom_user tab_users.nom_user%TYPE,
                                            jpass_user tab_users.pass_user%TYPE,
                                            jtel_user tab_users.tel_user%TYPE,
                                            jmail_user tab_users.mail_user%TYPE) 
                                            RETURNS BOOLEAN AS 
$$
    DECLARE jid tab_users.id_user%TYPE;
            j_check_val INTEGER; -- Variable auxiliar para validaciones

BEGIN
    -- Validar nulos y formato
    -- Nombre
        IF jnom_user IS NULL OR jnom_user = '' THEN
            RAISE EXCEPTION 'Error: El nombre no puede estar vacío';
        END IF;     

    -- Contraseña
        IF jpass_user IS NULL OR jpass_user = '' THEN
            RAISE EXCEPTION 'Error: La contraseña debe tener al menos 6 caracteres';
        END IF;

        IF LENGTH(jpass_user) < 6 THEN
            RAISE EXCEPTION 'Error: La contraseña debe tener al menos 6 caracteres';
        END IF;

        IF jpass_user !~ '^(?=.*[A-Z])(?=.*[0-9])' THEN
            RAISE EXCEPTION 'Error: La contraseña debe tener al menos 1 mayúscula y 1 número';
        END IF;

    -- Teléfono
        IF jtel_user IS NULL OR TRIM(jtel_user) = '' THEN
            RAISE EXCEPTION 'Error: El teléfono no puede estar vacío';
        END IF;
        
        IF jtel_user !~ '^[0-9]{7,10}$' THEN
             RAISE EXCEPTION 'Error: El teléfono debe tener entre 7 y 10 dígitos numéricos.';
        END IF;

    -- Email    
        IF jmail_user IS NULL THEN
            RAISE EXCEPTION 'Error: Email inválido';
        END IF;
                
        IF jmail_user !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
            RAISE EXCEPTION 'Error: Formato de email inválido';
        END IF;
            
    -- Verificar unicidad manualmente
        SELECT 1 INTO j_check_val From tab_users Where nom_user = jnom_user LIMIT 1;
        IF Found THEN
            RAISE EXCEPTION 'Error: Ya existe un usuario con este nombre';
        END IF;

        SELECT 1 INTO j_check_val From tab_users Where tel_user = jtel_user LIMIT 1;
        IF Found THEN
            RAISE EXCEPTION 'Error: Ya existe un usuario con este teléfono';
        END IF;
            
        SELECT 1 INTO j_check_val From tab_users Where mail_user = jmail_user LIMIT 1;
        IF Found THEN
            RAISE EXCEPTION 'Error: Ya existe un usuario con este email';
        END IF;

    -- Autoincrementado del id_user
        Select COALESCE(MAX(id_user), 0) + 1 INTO jid 
        From tab_users;
    
    -- Insertar el nuevo usuario
        INSERT INTO tab_users (id_user, nom_user, pass_user, tel_user, mail_user, user_insert, fec_insert, ind_vivo) 
        VALUES (jid, jnom_user, jpass_user, jtel_user, jmail_user, 
                COALESCE(current_setting('specialized.app_user', true), CURRENT_USER),
                CURRENT_TIMESTAMP, TRUE);
    
        RETURN TRUE;

EXCEPTION
    WHEN check_violation THEN
        RAISE EXCEPTION 'Error: Datos inválidos (Violación de restricción Check en BD). Verifique longitud de teléfono o emails.';
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Error: Datos duplicados (Usuario/Email/Teléfono).';
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error inesperado: %', SQLERRM;
END;
$$ 
LANGUAGE plpgsql;
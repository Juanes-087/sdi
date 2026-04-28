--Select fun_insert_user('Juanes', 'Pass123', '3102278149', 'hola12@gmail.com')
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
            RAISE NOTICE 'Error: El nombre no puede estar vacío';
            RETURN FALSE;
        END IF;     

    -- Contraseña
        IF jpass_user IS NULL OR jpass_user = '' THEN
            RAISE NOTICE 'Error: La contraseña debe tener al menos 6 caracteres';
            RETURN FALSE;
        END IF;

        IF LENGTH(jpass_user) < 6 THEN
            RAISE NOTICE 'Error: La contraseña debe tener al menos 6 caracteres';
            RETURN FALSE;
        END IF;

        IF jpass_user !~ '^(?=.*[A-Z])(?=.*[0-9])' THEN
            RAISE NOTICE 'Error: La contraseña debe tener al menos 1 mayúscula y 1 número';
            RETURN FALSE;
        END IF;

    -- Teléfono
        IF jtel_user IS NULL OR TRIM(jtel_user) = '' THEN
            RAISE NOTICE 'Error: El teléfono no puede estar vacío';
            RETURN FALSE;
        END IF;
        
        IF jtel_user !~ '^[0-9]{7,10}$' THEN
             RAISE NOTICE 'Error: El teléfono debe tener entre 7 y 10 dígitos numéricos.';
             RETURN FALSE;
        END IF;

    -- Email    
        IF jmail_user IS NULL THEN
            RAISE NOTICE 'Error: Email inválido';
            RETURN FALSE;
        END IF;
                
        IF jmail_user !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN
            RAISE NOTICE 'Error: Formato de email inválido';
            RETURN FALSE;
        END IF;
            
    -- Verificar unicidad manualmente
        SELECT 1 INTO j_check_val From tab_users Where nom_user = jnom_user LIMIT 1;
        IF Found THEN
            RAISE NOTICE 'Error: Ya existe un usuario con este nombre';
            RETURN FALSE;
        END IF;

        SELECT 1 INTO j_check_val From tab_users Where tel_user = jtel_user LIMIT 1;
        IF Found THEN
            RAISE NOTICE 'Error: Ya existe un usuario con este teléfono';
            RETURN FALSE;
        END IF;
            
        SELECT 1 INTO j_check_val From tab_users Where mail_user = jmail_user LIMIT 1;
        IF Found THEN
            RAISE NOTICE 'Error: Ya existe un usuario con este email';
            RETURN FALSE;
        END IF;

    -- Autoincrementado del id_user
        Select COALESCE(MAX(id_user), 0) + 1 INTO jid 
        From tab_users;
    
    -- Insertar el nuevo usuario
        INSERT INTO tab_users (id_user, nom_user, pass_user, tel_user, mail_user) 
        VALUES (jid, jnom_user, jpass_user, jtel_user, jmail_user);
    
        RAISE NOTICE 'Usuario % creado exitosamente', jid;
        RETURN TRUE;

EXCEPTION
    WHEN check_violation THEN
        RAISE NOTICE 'Error: Datos inválidos (Violación de restricción Check en BD). Verifique longitud de teléfono o emails.';
        RETURN FALSE;
    WHEN unique_violation THEN
        RAISE NOTICE 'Error: Datos duplicados (Usuario/Email/Teléfono).';
        RETURN FALSE;
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$ 
LANGUAGE plpgsql;
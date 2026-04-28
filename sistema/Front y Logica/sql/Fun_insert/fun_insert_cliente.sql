/*
    -----------------------------------------------------------------------------
    PRUEBAS DE VALIDACIÓN (EJECUTAR PARA VERIFICAR)
    -----------------------------------------------------------------------------
    1. Insertar Cliente SIN Usuario (Solo Cliente):
       SELECT fun_insert_cliente(1, 1, 'Juan', NULL, 'Perez', 'Lopez', '1001', 3001234567, 'Calle 123', 'Ingeniero');

    2. Insertar Cliente CON Usuario (Crea usuario y vincula):
       SELECT fun_insert_cliente(1, 1, 'Maria', 'Jose', 'Gomez', 'Diaz', '1002', 3009876543, 'Cra 456', 'Abogada', 'maria.g', 'Pass123', 'maria@mail.com');

    3. Validar Documento Duplicado (Debe fallar):
       SELECT fun_insert_cliente(1, 1, 'Juan', NULL, 'Perez', 'Lopez', '1001', 3001234567, 'Calle 123', 'Ingeniero');

    4. Validar Ciudad Inexistente (Debe fallar):
       SELECT fun_insert_cliente(1, 9999, 'Test', NULL, 'User', 'Test', '1003', 3000000000, 'Dir', 'Prof');
    -----------------------------------------------------------------------------
*/
Drop function if exists fun_insert_cliente;
CREATE OR REPLACE FUNCTION fun_insert_cliente   (jid_docum tab_clientes.id_documento%TYPE,
                                                jid_ciudad tab_clientes.id_ciudad%TYPE,
                                                jind_genero tab_clientes.ind_genero%TYPE,
                                                jprim_nom tab_clientes.prim_nom%TYPE,
                                                jsegun_nom tab_clientes.segun_nom%TYPE,
                                                jprim_apell tab_clientes.prim_apell%TYPE,
                                                jsegun_apell tab_clientes.segun_apell%TYPE,
                                                jnum_doc tab_clientes.num_documento%TYPE,
                                                jtel tab_clientes.tel_cliente%TYPE,
                                                jdir tab_clientes.dir_cliente%TYPE,
                                                jprofesion tab_clientes.ind_profesion%TYPE)
                                                RETURNS BOOLEAN AS
$$
    DECLARE 
        jid_nuevo tab_clientes.id_cliente%TYPE;
        j_check_val INTEGER;
        
    BEGIN
        -- 1. VALIDACIONES DE INTEGRIDAD (IDs)
        IF jid_docum IS NULL OR jid_docum <= 0 THEN 
            RAISE NOTICE 'Error: Tipo de Documento inválido.'; 
            RETURN FALSE; 
        END IF;
        
        IF jid_ciudad IS NULL OR jid_ciudad <= 0 THEN 
            RAISE NOTICE 'Error: Ciudad inválida.'; 
            RETURN FALSE; 
        END IF;

        IF jind_genero NOT IN (1, 2, 3) THEN 
            RAISE NOTICE 'Error: Género inválido (Permitido: 1, 2, 3).'; 
            RETURN FALSE; 
        END IF;
        
        -- 2. VALIDACIONES DE TEXTO
        -- Primer Nombre
        IF jprim_nom IS NULL OR TRIM(jprim_nom) = '' THEN 
            RAISE NOTICE 'Error: El Primer Nombre no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;
        
        IF LENGTH(TRIM(jprim_nom)) < 3 THEN 
            RAISE NOTICE 'Error: El Primer Nombre es muy corto (Mínimo 3 caracteres).'; 
            RETURN FALSE; 
        END IF;
        
         IF LENGTH(TRIM(jprim_nom)) > 30 THEN 
            RAISE NOTICE 'Error: El Primer Nombre es muy largo (Máximo 30 caracteres).'; 
            RETURN FALSE; 
        END IF;

        IF jprim_nom !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
            RAISE NOTICE 'Error: El Primer Nombre contiene caracteres prohibidos.';
            RETURN FALSE; 
        END IF;

        -- Segundo Nombre (Opcional pero validado si existe)
        IF jsegun_nom IS NOT NULL AND TRIM(jsegun_nom) <> '' THEN
            IF LENGTH(TRIM(jsegun_nom)) < 3 THEN 
                    RAISE NOTICE 'Error: El Segundo Nombre es muy corto.'; 
                    RETURN FALSE; 
            END IF;
            IF jsegun_nom !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
                    RAISE NOTICE 'Error: El Segundo Nombre contiene caracteres inválidos.'; 
                    RETURN FALSE; 
            END IF;
        END IF;

        -- Primer Apellido
        IF jprim_apell IS NULL OR TRIM(jprim_apell) = '' THEN 
            RAISE NOTICE 'Error: El Primer Apellido no puede estar vacío.'; 
            RETURN FALSE;
        END IF;

        IF LENGTH(TRIM(jprim_apell)) < 3 THEN 
            RAISE NOTICE 'Error: El Primer Apellido es muy corto.'; 
            RETURN FALSE;
        END IF;

        IF jprim_apell !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
            RAISE NOTICE 'Error: El Primer Apellido contiene caracteres prohibidos.'; 
            RETURN FALSE; 
        END IF;

        -- 3. VALIDACIÓN DOCUMENTO (Anti-inyección y Formato)
        IF jnum_doc IS NULL OR TRIM(jnum_doc) = '' THEN 
            RAISE NOTICE 'Error: El número de documento no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnum_doc)) < 5 THEN 
            RAISE NOTICE 'Error: El número de documento es muy corto.'; 
            RETURN FALSE; 
        END IF;

        IF jnum_doc !~ '^[a-zA-Z0-9-]+$' THEN 
            RAISE NOTICE 'Error: El número de documento contiene caracteres inválidos.'; 
            RETURN FALSE; 
        END IF;

        -- 4. VALIDACIÓN TELÉFONO
        IF jtel IS NULL OR TRIM(jtel) = '' THEN 
            RAISE NOTICE 'Error: El teléfono no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;

        IF jtel !~ '^[0-9]{7,10}$' THEN 
            RAISE NOTICE 'Error: El teléfono debe tener entre 7 y 10 dígitos numéricos.'; 
            RETURN FALSE; 
        END IF;

        -- 5. VALIDACIÓN DIRECCIÓN Y PROFESIÓN
        IF jdir IS NULL OR LENGTH(TRIM(jdir)) < 5 THEN 
            RAISE NOTICE 'Error: Dirección inválida o muy corta.'; 
            RETURN FALSE; 
        END IF;
        
        IF jprofesion IS NULL OR LENGTH(TRIM(jprofesion)) < 3 THEN 
            RAISE NOTICE 'Error: Profesión inválida o muy corta.'; 
            RETURN FALSE; 
        END IF;
        
        IF jprofesion !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s.]+$' THEN 
            RAISE NOTICE 'Error: La profesión contiene caracteres prohibidos.'; 
            RETURN FALSE; 
        END IF;

        -- Validar existencia FKs (Ciudad)
        SELECT 1 INTO j_check_val FROM tab_ciudades WHERE id_ciudad = jid_ciudad AND ind_vivo = TRUE LIMIT 1;
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: La ciudad especificada no existe o está inactiva.';
            RETURN FALSE;
        END IF;

        -- Validar existencia FKs (Tipo Documento)
        SELECT 1 INTO j_check_val FROM tab_tipo_documentos WHERE id_documento = jid_docum AND ind_vivo = TRUE LIMIT 1;
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: El tipo de documento especificado no existe o está inactivo.';
            RETURN FALSE;
        END IF;



        -- INSERCIÓN CLIENTE
        SELECT COALESCE(MAX(id_cliente), 0) + 1 INTO jid_nuevo FROM tab_clientes WHERE id_cliente < 99000;
        
        INSERT INTO tab_clientes (
                id_cliente, id_documento, id_ciudad, ind_genero,
                prim_nom, segun_nom, prim_apell, segun_apell, 
                num_documento, tel_cliente, dir_cliente, ind_profesion, val_puntos, ind_vivo)
        VALUES (
                jid_nuevo, jid_docum, jid_ciudad, jind_genero,
                TRIM(jprim_nom), TRIM(jsegun_nom), TRIM(jprim_apell), TRIM(jsegun_apell), 
                TRIM(jnum_doc), jtel, TRIM(jdir), TRIM(jprofesion), 0, TRUE);

        RAISE NOTICE 'Cliente % registrado exitosamente.', jid_nuevo; 
        RETURN TRUE;

EXCEPTION
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Datos duplicados (Documento/Usuario).'; 
        RETURN FALSE;
    WHEN foreign_key_violation THEN 
        RAISE NOTICE 'Error: Referencia inválida (Ciudad/Doc) en bases de datos.'; 
        RETURN FALSE;
    WHEN string_data_right_truncation THEN
        RAISE NOTICE 'Error: Datos demasiado largos para la columna.';
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error Crítico: %', SQLERRM;
        RETURN FALSE;
END;
$$ 
LANGUAGE plpgsql;
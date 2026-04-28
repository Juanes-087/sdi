/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Cliente Nulo:      SELECT fun_update_clientes(NULL, 1, 1, 1, 'Nom', 'S', 'Ap', 'S', '123', 300, 'Dir', 'Prof', 0);
   2.  ID Cliente Negativo:  SELECT fun_update_clientes(-1, 1, 1, 1, 'Nom', 'S', 'Ap', 'S', '123', 300, 'Dir', 'Prof', 0);
   3.  ID Doc Invalido:      SELECT fun_update_clientes(1, 1, 0, 1, 'Nom', 'S', 'Ap', 'S', '123', 300, 'Dir', 'Prof', 0);
   4.  ID Ciudad Invalido:   SELECT fun_update_clientes(1, 1, 1, -5, 'Nom', 'S', 'Ap', 'S', '123', 300, 'Dir', 'Prof', 0);
   5.  Nombre Vacío:         SELECT fun_update_clientes(1, 1, 1, 1, '', 'S', 'Ap', 'S', '123', 300, 'Dir', 'Prof', 0);
   6.  Apellido Vacío:       SELECT fun_update_clientes(1, 1, 1, 1, 'Nom', 'S', '', 'S', '123', 300, 'Dir', 'Prof', 0);
   7.  Num Doc Vacío:        SELECT fun_update_clientes(1, 1, 1, 1, 'Nom', 'S', 'Ap', 'S', '', 300, 'Dir', 'Prof', 0);
   8.  SQL Inj (Dir):        SELECT fun_update_clientes(1, 1, 1, 1, 'Nom', 'S', 'Ap', 'S', '123', 300, '''; DROP --', 'Prof', 0);
   9.  ID Inexistente (999): SELECT fun_update_clientes(99999, 1, 1, 1, 'Nom', 'S', 'Ap', 'S', '123', 300, 'Dir', 'Prof', 0);
   10. CASO EXITOSO:         SELECT fun_update_clientes(1, 1, 1, 1, 'Juan', 'David', 'Perez', 'Lopez', '100123', 3001234567, 'Calle 10 #20', 'Ingeniero', 50);
   -----------------------------------------------------------------------------
*/

drop function if exists fun_update_clientes();

CREATE OR REPLACE FUNCTION fun_update_clientes  (jid_cliente tab_clientes.id_cliente%TYPE,
                                                jid_documento tab_clientes.id_documento%TYPE,
                                                jid_ciudad tab_clientes.id_ciudad%TYPE,
                                                jind_genero tab_clientes.ind_genero%TYPE,
                                                jprim_nom tab_clientes.prim_nom%TYPE,
                                                jsegun_nom tab_clientes.segun_nom%TYPE,
                                                jprim_apell tab_clientes.prim_apell%TYPE,
                                                jsegun_apell tab_clientes.segun_apell%TYPE,
                                                jnum_documento tab_clientes.num_documento%TYPE,
                                                jtel_cliente tab_clientes.tel_cliente%TYPE,
                                                jdir_cliente tab_clientes.dir_cliente%TYPE,
                                                jind_profesion tab_clientes.ind_profesion%TYPE,
                                                jval_puntos tab_clientes.val_puntos%TYPE)
                                                RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_cliente IS NULL OR jid_cliente <= 0 THEN 
            RAISE NOTICE 'Error: ID Cliente inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_clientes WHERE id_cliente = jid_cliente;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Cliente con ID % no encontrado.', jid_cliente;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Cliente con ID % se encuentra eliminado. No se puede actualizar.', jid_cliente;
            RETURN FALSE;
        END IF;



    -- Validar FK Documento
        IF jid_documento IS NULL OR jid_documento <= 0 THEN 
            RAISE NOTICE 'Error: ID Tipo Documento inválido.'; 
            RETURN FALSE; 
        END IF;
        
        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_tipo_documentos WHERE id_documento = jid_documento;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Tipo de Documento referido no existe o está inactivo.'; 
            RETURN FALSE; 
        END IF;

    -- Validar FK Ciudad
        IF jid_ciudad IS NULL OR jid_ciudad <= 0 THEN 
            RAISE NOTICE 'Error: ID Ciudad inválido.'; 
            RETURN FALSE; 
        END IF;
        
        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_ciudades WHERE id_ciudad = jid_ciudad;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Ciudad referida no existe o está inactiva.'; 
            RETURN FALSE; 
        END IF;

        IF jind_genero NOT IN (1, 2, 3) THEN 
            RAISE NOTICE 'Error: Género inválido (Permitido: 1, 2, 3).'; 
            RETURN FALSE; 
        END IF;

    -- Datos Personales
        IF jprim_nom IS NULL OR TRIM(jprim_nom) = '' THEN 
            RAISE NOTICE 'Error: Primer nombre no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;

        IF jprim_nom !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
            RAISE NOTICE 'Error: El Primer Nombre contiene caracteres prohibidos.';
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jprim_nom)) < 3 OR LENGTH(TRIM(jprim_nom)) > 30 THEN 
            RAISE NOTICE 'Error: Primer nombre debe tener entre 3 y 30 caracteres.'; 
            RETURN FALSE; 
        END IF;

        IF jsegun_nom IS NOT NULL AND TRIM(jsegun_nom) <> '' THEN 
            IF jsegun_nom !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
                RAISE NOTICE 'Error: El Segundo Nombre contiene caracteres inválidos.'; 
                RETURN FALSE; 
            END IF;
            IF LENGTH(TRIM(jsegun_nom)) < 3 OR LENGTH(TRIM(jsegun_nom)) > 30 THEN 
                RAISE NOTICE 'Error: Segundo nombre debe tener entre 3 y 30 caracteres.'; 
                RETURN FALSE; 
            END IF;
        END IF;

        IF jprim_apell IS NULL OR TRIM(jprim_apell) = '' THEN 
            RAISE NOTICE 'Error: Primer apellido no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;

        IF jprim_apell !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
            RAISE NOTICE 'Error: El Primer Apellido contiene caracteres prohibidos.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jprim_apell)) < 3 OR LENGTH(TRIM(jprim_apell)) > 30 THEN 
            RAISE NOTICE 'Error: Primer apellido debe tener entre 3 y 30 caracteres.'; 
            RETURN FALSE; 
        END IF;

        IF jsegun_apell IS NOT NULL AND TRIM(jsegun_apell) <> '' THEN 
            IF jsegun_apell !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
                RAISE NOTICE 'Error: El Segundo Apellido contiene caracteres inválidos.'; 
                RETURN FALSE; 
            END IF;
            IF LENGTH(TRIM(jsegun_apell)) < 3 OR LENGTH(TRIM(jsegun_apell)) > 30 THEN 
                RAISE NOTICE 'Error: Segundo apellido debe tener entre 3 y 30 caracteres.'; 
                RETURN FALSE; 
            END IF;
        END IF;
        -- Strings
        IF jnum_documento IS NULL OR TRIM(jnum_documento) = '' THEN 
            RAISE NOTICE 'Error: Número documento vacío.'; 
            RETURN FALSE; 
        END IF;

        IF jnum_documento !~ '^[a-zA-Z0-9-]+$' THEN 
            RAISE NOTICE 'Error: El número de documento contiene caracteres inválidos.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnum_documento)) < 5 OR LENGTH(TRIM(jnum_documento)) > 20 THEN 
            RAISE NOTICE 'Error: Número de documento debe tener entre 5 y 20 caracteres.'; 
            RETURN FALSE; 
        END IF;

        IF jdir_cliente IS NULL OR TRIM(jdir_cliente) = '' THEN 
            RAISE NOTICE 'Error: Dirección vacía.'; 
            RETURN FALSE; 
        END IF;

        IF jind_profesion IS NULL OR TRIM(jind_profesion) = '' THEN 
            RAISE NOTICE 'Error: Profesión vacía.'; 
            RETURN FALSE; 
        END IF;

        IF jind_profesion !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s.]+$' THEN 
            RAISE NOTICE 'Error: La profesión contiene caracteres prohibidos.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jind_profesion)) < 3 THEN 
            RAISE NOTICE 'Error: Profesión es muy corta.'; 
            RETURN FALSE; 
        END IF;

    -- Validar Numericos
        IF jtel_cliente IS NULL OR jtel_cliente !~ '^[0-9]{7,10}$' THEN 
            RAISE NOTICE 'Error: Teléfono inválido (debe tener entre 7 y 10 dígitos numéricos).'; 
            RETURN FALSE; 
        END IF;

        IF jval_puntos IS NULL OR jval_puntos < 0 THEN 
            RAISE NOTICE 'Error: Puntos inválidos (negativos).'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
        UPDATE tab_clientes SET
            id_documento = jid_documento,
            id_ciudad = jid_ciudad,
            ind_genero = jind_genero,
            prim_nom = jprim_nom,
            segun_nom = COALESCE(TRIM(jsegun_nom), ''),
            prim_apell = jprim_apell,
            segun_apell = COALESCE(TRIM(jsegun_apell), ''),
            num_documento = jnum_documento,
            tel_cliente = jtel_cliente,
            dir_cliente = jdir_cliente,
            ind_profesion = jind_profesion,
            val_puntos = jval_puntos
        WHERE id_cliente = jid_cliente;

        RAISE NOTICE 'Cliente actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

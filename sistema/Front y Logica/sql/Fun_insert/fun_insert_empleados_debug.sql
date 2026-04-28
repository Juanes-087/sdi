CREATE OR REPLACE FUNCTION fun_insert_empleados (jid_docum tab_empleados.id_documento%TYPE, 
                                                jid_ciudad tab_empleados.id_ciudad%TYPE,   
                                                jid_cargo tab_empleados.id_cargo%TYPE,      
                                                jid_tipo_san tab_empleados.id_tipo_sangre%TYPE, 
                                                jid_genero tab_empleados.id_genero%TYPE,
                                                jnum_doc tab_empleados.num_documento%TYPE,
                                                jprim_nom tab_empleados.prim_nom%TYPE,
                                                jsegun_nom tab_empleados.segun_nom%TYPE,
                                                jprim_apell tab_empleados.prim_apell%TYPE,
                                                jsegun_apell tab_empleados.segun_apell%TYPE,
                                                jmail tab_empleados.mail_empleado%TYPE,
                                                jtel tab_empleados.tel_empleado%TYPE,
                                                jdir tab_empleados.dir_emple%TYPE,
                                                jfecha_contratn tab_empleados.ind_fecha_contratacion%TYPE,
                                                jsalario tab_empleados.ind_salario%TYPE DEFAULT 2000000,
                                                jpeso tab_empleados.ind_peso%TYPE DEFAULT 70.0,
                                                jaltura tab_empleados.ind_altura%TYPE DEFAULT 1.70,
                                                jult_fec_exam tab_empleados.ult_fec_exam%TYPE DEFAULT CURRENT_DATE,
                                                jobserv tab_empleados.observ%TYPE DEFAULT '',
                                                jid_banco tab_empleados.id_banco%TYPE DEFAULT 0,
                                                jnum_cuenta tab_empleados.num_cuenta%TYPE DEFAULT ''
)
RETURNS BOOLEAN AS
$$
    DECLARE 
        jid_nuevo tab_empleados.id_empleado%TYPE;
        j_ind_vivo_fk BOOLEAN;
        existe_duplicado BOOLEAN;
            
    BEGIN
    -- 1. VALIDACIONES DE INTEGRIDAD (IDs y FKs con ind_vivo)
        -- Documento
        IF jid_docum IS NULL OR jid_docum <= 0 THEN RAISE EXCEPTION 'Error: ID Documento inválido.'; 
            RETURN FALSE; 
        END IF;
        
        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_tipo_documentos WHERE id_documento = jid_docum;
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE EXCEPTION 'Error: Tipo Documento no existe o inactivo.'; 
            RETURN FALSE; 
        END IF;

        -- Ciudad
        IF jid_ciudad IS NULL OR jid_ciudad <= 0 THEN 
            RAISE EXCEPTION 'Error: ID Ciudad inválido.'; 
            RETURN FALSE; 
        END IF;
        
        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_ciudades WHERE id_ciudad = jid_ciudad;
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE EXCEPTION 'Error: Ciudad no existe o inactiva.'; 
            RETURN FALSE; 
        END IF;

        -- Cargo
        IF jid_cargo IS NULL OR jid_cargo <= 0 THEN
            RAISE EXCEPTION 'Error: ID Cargo inválido.'; 
            RETURN FALSE; 
        END IF;
        
        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_cargos WHERE id_cargo = jid_cargo;
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE EXCEPTION 'Error: Cargo no existe o inactivo.'; 
            RETURN FALSE; 
        END IF;

        -- Sangre
        IF jid_tipo_san IS NULL OR jid_tipo_san <= 0 THEN 
            RAISE EXCEPTION 'Error: ID Sangre inválido.'; 
            RETURN FALSE; 
        END IF;
        
        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_tipo_sangre WHERE id_tipo_sangre = jid_tipo_san;
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE EXCEPTION 'Error: Sangre no existe o inactiva.'; 
            RETURN FALSE; 
        END IF;

        -- Género
        IF jid_genero IS NULL OR jid_genero <= 0 THEN 
            RAISE EXCEPTION 'Error: ID Género inválido.'; 
            RETURN FALSE; 
        END IF;
        
        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_generos WHERE id_genero = jid_genero;
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE EXCEPTION 'Error: Género no existe o inactivo.'; 
            RETURN FALSE; 
        END IF;

        -- Banco
        IF jid_banco IS NULL OR jid_banco <= 0 THEN 
            RAISE EXCEPTION 'Error: ID Banco inválido.'; 
            RETURN FALSE; 
        END IF;

        IF jid_banco IS NOT NULL AND jid_banco > 0 THEN
            SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_bancos WHERE id_banco = jid_banco;
            IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
                RAISE EXCEPTION 'Error: El Banco seleccionado no existe o está inactivo.'; 
                RETURN FALSE; 
            END IF;
        END IF;

    -- 2. VALIDACIONES DE TEXTO (Regex y Longitud)
        -- Documento
        IF jnum_doc IS NULL OR TRIM(jnum_doc) = '' THEN 
            RAISE EXCEPTION 'Error: El número de documento es obligatorio.'; 
            RETURN FALSE; 
        END IF;
        
        IF jnum_doc !~ '^[a-zA-Z0-9-]+$' THEN 
            RAISE EXCEPTION 'Error: Documento con caracteres inválidos.'; 
            RETURN FALSE; 
        END IF;
        
        IF LENGTH(TRIM(jnum_doc)) < 5 OR LENGTH(TRIM(jnum_doc)) > 20 THEN 
            RAISE EXCEPTION 'Error: Documento debe tener entre 5 y 20 caracteres.'; 
            RETURN FALSE; 
        END IF;

        -- Nombres y Apellidos
        IF jprim_nom IS NULL OR TRIM(jprim_nom) = '' THEN 
            RAISE EXCEPTION 'Error: Primer nombre obligatorio.'; 
            RETURN FALSE; 
        END IF;
        
        IF jprim_nom !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
            RAISE EXCEPTION 'Error: Primer nombre contiene caracteres inválidos.'; 
            RETURN FALSE; 
        END IF;
        
        IF LENGTH(TRIM(jprim_nom)) < 3 OR LENGTH(TRIM(jprim_nom)) > 30 THEN 
            RAISE EXCEPTION 'Error: Primer nombre debe tener entre 3 y 30 caracteres.'; 
            RETURN FALSE; 
        END IF;

        IF jsegun_nom IS NOT NULL AND TRIM(jsegun_nom) <> '' THEN
            IF jsegun_nom !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
                RAISE EXCEPTION 'Error: Segundo nombre contiene caracteres inválidos.'; 
                RETURN FALSE; 
            END IF;

            IF LENGTH(TRIM(jsegun_nom)) < 3 OR LENGTH(TRIM(jsegun_nom)) > 30 THEN 
                RAISE EXCEPTION 'Error: Segundo nombre debe tener entre 3 y 30 caracteres.'; 
                RETURN FALSE; 
            END IF;
        END IF;

        IF jprim_apell IS NULL OR TRIM(jprim_apell) = '' THEN 
            RAISE EXCEPTION 'Error: Primer apellido obligatorio.'; 
            RETURN FALSE; 
        END IF;
        
        IF jprim_apell !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
            RAISE EXCEPTION 'Error: Primer apellido contiene caracteres inválidos.'; 
            RETURN FALSE; 
        END IF;
        
        IF LENGTH(TRIM(jprim_apell)) < 3 OR LENGTH(TRIM(jprim_apell)) > 30 THEN 
            RAISE EXCEPTION 'Error: Primer apellido debe tener entre 3 y 30 caracteres.'; 
            RETURN FALSE; 
        END IF;

        IF jsegun_apell IS NOT NULL AND TRIM(jsegun_apell) <> '' THEN
            IF jsegun_apell !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN
                RAISE EXCEPTION 'Error: Segundo apellido contiene caracteres inválidos.'; 
                RETURN FALSE; 
            END IF;

            IF LENGTH(TRIM(jsegun_apell)) < 3 OR LENGTH(TRIM(jsegun_apell)) > 30 THEN 
                RAISE EXCEPTION 'Error: Segundo apellido debe tener entre 3 y 30 caracteres.'; 
                RETURN FALSE; 
            END IF;
        END IF;

        -- Email
        IF jmail IS NOT NULL AND TRIM(jmail) <> '' THEN
            IF jmail !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN 
                RAISE EXCEPTION 'Error: Formato de email inválido.'; 
                RETURN FALSE; 
            END IF;
            IF LENGTH(TRIM(jmail)) > 255 THEN 
                RAISE EXCEPTION 'Error: Email excede 255 caracteres.'; 
                RETURN FALSE; 
            END IF;
        END IF;

        -- Teléfono
        IF jtel IS NULL OR LENGTH(jtel::TEXT) < 7 OR LENGTH(jtel::TEXT) > 10 THEN 
            RAISE EXCEPTION 'Error: Teléfono inválido (7-10 dígitos).'; 
            RETURN FALSE; 
        END IF;

        -- Dirección
        IF jdir IS NULL OR LENGTH(TRIM(jdir)) < 5 THEN 
            RAISE EXCEPTION 'Error: Dirección muy corta o nula.'; 
            RETURN FALSE; 
        END IF;

        -- Número de Cuenta
        IF jnum_cuenta IS NOT NULL AND TRIM(jnum_cuenta) <> '' THEN
            IF jnum_cuenta !~ '^[0-9]+$' THEN
                RAISE EXCEPTION 'Error: El número de cuenta solo debe contener números.';
                RETURN FALSE;
            END IF;
            IF LENGTH(TRIM(jnum_cuenta)) < 10 OR LENGTH(TRIM(jnum_cuenta)) > 20 THEN
                RAISE EXCEPTION 'Error: El número de cuenta debe tener entre 10 y 20 caracteres.';
                RETURN FALSE;
            END IF;
        END IF;

    -- 3. VALIDACIONES NUMÉRICAS Y FECHAS
        IF jsalario < 1400000.00 THEN 
            RAISE EXCEPTION 'Error: El salario debe ser >= 1.4M.'; 
            RETURN FALSE; 
        END IF;

        IF jpeso <= 40 OR jpeso >= 200 THEN 
            RAISE EXCEPTION 'Error: Peso inválido (40-200 kg).'; 
            RETURN FALSE; 
        END IF;
        
        IF jaltura <= 1.30 OR jaltura >= 2.50 THEN 
            RAISE EXCEPTION 'Error: Altura inválida (1.30m - 2.50m).'; 
            RETURN FALSE; 
        END IF;
        
        IF jfecha_contratn IS NULL OR jfecha_contratn > CURRENT_DATE THEN 
            RAISE EXCEPTION 'Error: Fecha contratación inválida o futura.'; 
            RETURN FALSE; 
        END IF;
        
        IF jult_fec_exam IS NOT NULL AND jult_fec_exam > CURRENT_DATE THEN 
            RAISE EXCEPTION 'Error: La fecha del examen no puede ser futura.'; 
            RETURN FALSE; 
        END IF;

    -- 4. UNICIDAD LOGICA
        SELECT EXISTS (SELECT 1 FROM tab_empleados WHERE id_documento = jid_docum AND num_documento = jnum_doc AND ind_vivo=TRUE) INTO existe_duplicado;
        IF existe_duplicado THEN RAISE EXCEPTION 'Error: Ya existe un empleado activo con ese documento.'; 
            RETURN FALSE; 
        END IF;

    -- 5. GENERAR ID E INSERTAR
        SELECT COALESCE(MAX(id_empleado), 0) + 1 INTO jid_nuevo FROM tab_empleados;

        INSERT INTO tab_empleados (
            id_empleado, id_documento, id_ciudad, id_cargo, id_tipo_sangre, id_genero,
            num_documento, prim_nom, segun_nom, prim_apell, segun_apell, 
            mail_empleado, tel_empleado, dir_emple, 
            ind_fecha_contratacion, ind_salario, ind_peso, ind_altura, 
            ult_fec_exam, observ, ind_vivo, user_insert, fec_insert,
            id_banco, num_cuenta
        ) 
        VALUES (
            jid_nuevo, jid_docum, jid_ciudad, jid_cargo, jid_tipo_san, jid_genero,
            TRIM(jnum_doc), TRIM(jprim_nom), TRIM(jsegun_nom), 
            TRIM(jprim_apell), TRIM(jsegun_apell), 
            TRIM(jmail), jtel, TRIM(jdir),
            jfecha_contratn, jsalario, jpeso, jaltura, 
            jult_fec_exam, TRIM(jobserv), TRUE, CURRENT_USER, NOW(),
            jid_banco, TRIM(jnum_cuenta)
        );

        RAISE EXCEPTION 'Empleado % registrado exitosamente.', jid_nuevo;
        RETURN TRUE;

    EXCEPTION
        WHEN unique_violation THEN 
            RAISE EXCEPTION 'Error: Documento o Correo duplicado.'; 
            RETURN FALSE;
        WHEN foreign_key_violation THEN 
            RAISE EXCEPTION 'Error: Referencia inexistente.'; 
            RETURN FALSE;
        WHEN OTHERS THEN 
            RAISE EXCEPTION 'Error crítico: %', SQLERRM; 
            RETURN FALSE;
    END;
$$ 
LANGUAGE plpgsql;


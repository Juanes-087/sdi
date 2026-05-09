Drop function if exists fun_insert_empleados;
CREATE OR REPLACE FUNCTION fun_insert_empleados (jid_docum tab_empleados.id_documento%TYPE, 
                                                jid_ciudad tab_empleados.id_ciudad%TYPE,   
                                                jid_cargo tab_empleados.id_cargo%TYPE,      
                                                jid_tipo_san tab_empleados.id_tipo_sangre%TYPE, 
                                                jind_genero tab_empleados.ind_genero%TYPE,
                                                jnum_doc tab_empleados.num_documento%TYPE,
                                                jprim_nom tab_empleados.prim_nom%TYPE,
                                                jsegun_nom tab_empleados.segun_nom%TYPE,
                                                jprim_apell tab_empleados.prim_apell%TYPE,
                                                jsegun_apell tab_empleados.segun_apell%TYPE,
                                                jmail tab_empleados.mail_empleado%TYPE,
                                                jtel tab_empleados.tel_empleado%TYPE,
                                                jdir tab_empleados.dir_emple%TYPE,
                                                jfecha_contratn tab_empleados.ind_fecha_contratacion%TYPE,
                                                jpeso tab_empleados.ind_peso%TYPE DEFAULT 70.0,
                                                jaltura tab_empleados.ind_altura%TYPE DEFAULT 1.70,
                                                jult_fec_exam tab_empleados.ult_fec_exam%TYPE DEFAULT CURRENT_DATE,
                                                jobserv tab_empleados.observ%TYPE DEFAULT 'N/A',
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
        IF jid_docum IS NULL OR jid_docum <= 0 THEN 
            RAISE EXCEPTION 'ID Documento inválido (Recibido: %).', jid_docum; 
        END IF;
        
        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_tipo_documentos WHERE id_documento = jid_docum;
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE EXCEPTION 'Tipo Documento no existe o inactivo (ID: %).', jid_docum; 
        END IF;

        -- Ciudad
        IF jid_ciudad IS NULL OR jid_ciudad <= 0 THEN 
            RAISE EXCEPTION 'ID Ciudad inválido (Recibido: %).', jid_ciudad; 
        END IF;
        
        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_ciudades WHERE id_ciudad = jid_ciudad;
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE EXCEPTION 'Ciudad no existe o inactiva (ID: %).', jid_ciudad; 
        END IF;

        -- Cargo
        IF jid_cargo IS NULL OR jid_cargo <= 0 THEN
            RAISE EXCEPTION 'ID Cargo inválido (Recibido: %).', jid_cargo; 
        END IF;
        
        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_cargos WHERE id_cargo = jid_cargo;
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE EXCEPTION 'Cargo no existe o inactivo (ID: %).', jid_cargo; 
        END IF;

        -- Sangre
        IF jid_tipo_san IS NULL OR jid_tipo_san <= 0 THEN 
            RAISE EXCEPTION 'ID Sangre inválido (Recibido: %).', jid_tipo_san; 
        END IF;
        
        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_tipo_sangre WHERE id_tipo_sangre = jid_tipo_san;
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE EXCEPTION 'Sangre no existe o inactiva (ID: %).', jid_tipo_san; 
        END IF;

        -- Género
        IF jind_genero NOT IN (1, 2, 3) THEN 
            RAISE EXCEPTION 'Género inválido (Recibido: %, Permitido: 1, 2, 3).', jind_genero; 
        END IF;

        -- Banco (Obligatorio por requerimiento)
        IF jid_banco IS NULL OR jid_banco <= 0 THEN 
            RAISE EXCEPTION 'ID Banco inválido (Recibido: %).', jid_banco; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_bancos WHERE id_banco = jid_banco;
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE EXCEPTION 'El Banco seleccionado no existe o está inactivo (ID: %).', jid_banco; 
        END IF;

    -- 2. VALIDACIONES DE TEXTO (Regex y Longitud)
        -- Documento
        IF jnum_doc IS NULL OR TRIM(jnum_doc) = '' THEN 
            RAISE EXCEPTION 'El número de documento es obligatorio.'; 
        END IF;
        
        IF jnum_doc !~ '^[a-zA-Z0-9-]+$' THEN 
            RAISE EXCEPTION 'Documento con caracteres inválidos: %', jnum_doc; 
        END IF;
        
        IF LENGTH(TRIM(jnum_doc)) < 5 OR LENGTH(TRIM(jnum_doc)) > 20 THEN 
            RAISE EXCEPTION 'Documento debe tener entre 5 y 20 caracteres (Recibido: %)', LENGTH(TRIM(jnum_doc)); 
        END IF;

        -- Nombres y Apellidos
        IF jprim_nom IS NULL OR TRIM(jprim_nom) = '' THEN 
            RAISE EXCEPTION 'Primer nombre obligatorio.'; 
        END IF;
        
        IF jprim_nom !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
            RAISE EXCEPTION 'Primer nombre contiene caracteres inválidos: %', jprim_nom; 
        END IF;
        
        IF LENGTH(TRIM(jprim_nom)) < 3 OR LENGTH(TRIM(jprim_nom)) > 30 THEN 
            RAISE EXCEPTION 'Primer nombre debe tener entre 3 y 30 caracteres (Recibido: %)', LENGTH(TRIM(jprim_nom)); 
        END IF;

        IF jsegun_nom IS NOT NULL AND TRIM(jsegun_nom) <> '' THEN
            IF jsegun_nom !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
                RAISE EXCEPTION 'Segundo nombre contiene caracteres inválidos: %', jsegun_nom; 
            END IF;

            IF LENGTH(TRIM(jsegun_nom)) < 3 OR LENGTH(TRIM(jsegun_nom)) > 30 THEN 
                RAISE EXCEPTION 'Segundo nombre debe tener entre 3 y 30 caracteres.'; 
            END IF;
        END IF;

        IF jprim_apell IS NULL OR TRIM(jprim_apell) = '' THEN 
            RAISE EXCEPTION 'Primer apellido obligatorio.'; 
        END IF;
        
        IF jprim_apell !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
            RAISE EXCEPTION 'Primer apellido contiene caracteres inválidos: %', jprim_apell; 
        END IF;
        
        IF LENGTH(TRIM(jprim_apell)) < 3 OR LENGTH(TRIM(jprim_apell)) > 30 THEN 
            RAISE EXCEPTION 'Primer apellido debe tener entre 3 y 30 caracteres.'; 
        END IF;

        IF jsegun_apell IS NOT NULL AND TRIM(jsegun_apell) <> '' THEN
            IF jsegun_apell !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN
                RAISE EXCEPTION 'Segundo apellido contiene caracteres inválidos.'; 
            END IF;

            IF LENGTH(TRIM(jsegun_apell)) < 3 OR LENGTH(TRIM(jsegun_apell)) > 30 THEN 
                RAISE EXCEPTION 'Segundo apellido debe tener entre 3 y 30 caracteres.'; 
            END IF;
        END IF;

        -- Email
        IF jmail IS NOT NULL AND TRIM(jmail) <> '' THEN
            IF jmail !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN 
                RAISE EXCEPTION 'Formato de email inválido: %', jmail; 
            END IF;
        END IF;

        -- Teléfono
        IF jtel IS NULL OR jtel !~ '^[0-9]{7,10}$' THEN 
            RAISE EXCEPTION 'Teléfono inválido: % (debe tener 7-10 dígitos numéricos).', jtel; 
        END IF;

        -- Dirección
        IF jdir IS NULL OR LENGTH(TRIM(jdir)) < 5 THEN 
            RAISE EXCEPTION 'Dirección insuficiente: %', jdir; 
        END IF;

        -- Cuenta Bancaria
        IF jnum_cuenta IS NULL OR jnum_cuenta !~ '^[0-9]{10,20}$' THEN
            RAISE EXCEPTION 'Número de cuenta inválido: % (debe tener entre 10 y 20 dígitos numéricos).', jnum_cuenta;
        END IF;

    -- 3. VALIDACIONES NUMÉRICAS Y FECHAS
        IF jpeso < 40 OR jpeso > 200 THEN 
            RAISE EXCEPTION 'Peso fuera de rango: % kg (Permitido: 40-200).', jpeso; 
        END IF;
        
        IF jaltura < 1.30 OR jaltura > 2.50 THEN 
            RAISE EXCEPTION 'Altura fuera de rango: % m (Permitido: 1.30-2.50).', jaltura; 
        END IF;
        
        IF jfecha_contratn IS NULL OR jfecha_contratn > CURRENT_DATE THEN 
            RAISE EXCEPTION 'Fecha contratación inválida: %', jfecha_contratn; 
        END IF;
        
        IF jult_fec_exam IS NOT NULL AND jult_fec_exam > CURRENT_DATE THEN 
            RAISE EXCEPTION 'Fecha examen futura: %', jult_fec_exam; 
        END IF;

    -- 4. UNICIDAD LOGICA
        SELECT EXISTS (SELECT 1 FROM tab_empleados WHERE id_documento = jid_docum AND num_documento = jnum_doc AND ind_vivo=TRUE) INTO existe_duplicado;
        IF existe_duplicado THEN 
            RAISE EXCEPTION 'Ya existe un empleado activo con documento %.', jnum_doc; 
        END IF;

    -- 5. GENERAR ID E INSERTAR
        SELECT COALESCE(MAX(id_empleado), 0) + 1 INTO jid_nuevo FROM tab_empleados;

        INSERT INTO tab_empleados (
            id_empleado, id_documento, id_ciudad, id_cargo, id_tipo_sangre, ind_genero,
            num_documento, prim_nom, segun_nom, prim_apell, segun_apell, 
            mail_empleado, tel_empleado, dir_emple, 
            ind_fecha_contratacion, ind_peso, ind_altura, 
            ult_fec_exam, observ, ind_vivo, user_insert, fec_insert,
            id_banco, num_cuenta
        ) 
        VALUES (
            jid_nuevo, jid_docum, jid_ciudad, jid_cargo, jid_tipo_san, jind_genero,
            TRIM(jnum_doc), TRIM(jprim_nom), TRIM(jsegun_nom), 
            TRIM(jprim_apell), TRIM(jsegun_apell), 
            TRIM(jmail), jtel, TRIM(jdir),
            jfecha_contratn, jpeso, jaltura, 
            jult_fec_exam, TRIM(jobserv), TRUE, CURRENT_USER, NOW(),
            jid_banco, TRIM(jnum_cuenta)
        );

        RETURN TRUE;

    EXCEPTION
        WHEN unique_violation THEN 
            RAISE EXCEPTION 'Error: Documento o Correo duplicado.'; 
        WHEN foreign_key_violation THEN 
            RAISE EXCEPTION 'Error: Referencia inexistente.'; 
        WHEN OTHERS THEN 
            RAISE EXCEPTION 'Error crítico en BD: %', SQLERRM; 
    END;
$$ 
LANGUAGE plpgsql;

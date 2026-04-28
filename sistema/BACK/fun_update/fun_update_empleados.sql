/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Empleado Nulo:     SELECT fun_update_empleados(NULL, 1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1.5e6, 70, 1.70, NOW(), 'Obs');
   2.  ID Empleado Negativo: SELECT fun_update_empleados(-1, 1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1.5e6, 70, 1.70, NOW(), 'Obs');
   3.  ID Doc Invalido:      SELECT fun_update_empleados(1, -1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1.5e6, 70, 1.70, NOW(), 'Obs');
   4.  Salario Bajo:         SELECT fun_update_empleados(1, 1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1000000, 70, 1.70, NOW(), 'Obs');
   5.  Peso Invalido (<40):  SELECT fun_update_empleados(1, 1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1.5e6, 20, 1.70, NOW(), 'Obs');
   6.  Email Invalido fmt:   SELECT fun_update_empleados(1, 1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'badmail', 300, NOW(), 1.5e6, 70, 1.70, NOW(), 'Obs');
   7.  Nombre Vacío:         SELECT fun_update_empleados(1, 1, 1, 1, 1, '123', '', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1.5e6, 70, 1.70, NOW(), 'Obs');
   8.  ID Inexistente (999): SELECT fun_update_empleados(99999, 1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1.5e6, 70, 1.70, NOW(), 'Obs');
   9.  Fecha Futura Examen:  SELECT fun_update_empleados(1, 1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1.5e6, 70, 1.70, '2030-01-01', 'Obs');
   10. CASO EXITOSO:         SELECT fun_update_empleados(1, 1, 1, 1, 1, '10203040', 'Juan', 'David', 'Perez', NULL, 'juan@empresa.com', 3105556677, CURRENT_DATE, 2500000, 75, 1.78, CURRENT_DATE, 'Promocion');
   -----------------------------------------------------------------------------
*/

drop function if exists fun_update_empleados;

CREATE OR REPLACE FUNCTION fun_update_empleados (jid_empleado tab_empleados.id_empleado%TYPE,
                                                jid_documento tab_empleados.id_documento%TYPE,
                                                jid_ciudad tab_empleados.id_ciudad%TYPE,
                                                jid_cargo tab_empleados.id_cargo%TYPE,
                                                jid_tipo_sangre tab_empleados.id_tipo_sangre%TYPE,
                                                jind_genero tab_empleados.ind_genero%TYPE,
                                                jnum_documento tab_empleados.num_documento%TYPE,
                                                jprim_nom tab_empleados.prim_nom%TYPE,
                                                jsegun_nom tab_empleados.segun_nom%TYPE,
                                                jprim_apell tab_empleados.prim_apell%TYPE,
                                                jsegun_apell tab_empleados.segun_apell%TYPE,
                                                jmail_empleado tab_empleados.mail_empleado%TYPE,
                                                jtel_empleado tab_empleados.tel_empleado%TYPE,
                                                jind_fecha_contratacion tab_empleados.ind_fecha_contratacion%TYPE,
                                                jind_peso tab_empleados.ind_peso%TYPE,
                                                jind_altura tab_empleados.ind_altura%TYPE,
                                                jult_fec_exam tab_empleados.ult_fec_exam%TYPE,
                                                jid_banco tab_empleados.id_banco%TYPE,
                                                jnum_cuenta tab_empleados.num_cuenta%TYPE,
                                                jobserv tab_empleados.observ%TYPE DEFAULT 'N/A')
                                                RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
            existe_duplicado BOOLEAN;
BEGIN
    -- Validar ID de empleado
        IF jid_empleado IS NULL OR jid_empleado <= 0 THEN
            RAISE NOTICE 'Error: ID de empleado inválido (Nulo o menor igual a 0).';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_empleados WHERE id_empleado = jid_empleado;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Empleado con ID % no encontrado.', jid_empleado;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Empleado con ID % se encuentra eliminado. No se puede actualizar.', jid_empleado;
            RETURN FALSE;
        END IF;

    -- Validar Claves Foráneas (No nulos y > 0)
        IF jid_documento IS NULL OR jid_documento <= 0 THEN 
            RAISE NOTICE 'Error: ID Tipo Documento inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_tipo_documentos WHERE id_documento = jid_documento;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Tipo de Documento no existe o inactivo.'; 
            RETURN FALSE; 
        END IF;

        IF jid_ciudad IS NULL OR jid_ciudad <= 0 THEN 
            RAISE NOTICE 'Error: ID Ciudad inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_ciudades WHERE id_ciudad = jid_ciudad;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Ciudad no existe o inactiva.'; 
            RETURN FALSE; 
        END IF;

        IF jid_cargo IS NULL OR jid_cargo <= 0 THEN 
            RAISE NOTICE 'Error: ID Cargo inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_cargos WHERE id_cargo = jid_cargo;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Cargo no existe o inactivo.'; 
            RETURN FALSE; 
        END IF;

        IF jid_tipo_sangre IS NULL OR jid_tipo_sangre <= 0 THEN 
            RAISE NOTICE 'Error: ID Tipo Sangre inválido.'; 
            RETURN FALSE; 
        END IF;
        
        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_tipo_sangre WHERE id_tipo_sangre = jid_tipo_sangre;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Tipo de Sangre no existe o inactivo.'; 
            RETURN FALSE; 
        END IF;

        IF jind_genero NOT IN (1, 2, 3) THEN 
            RAISE NOTICE 'Error: Género inválido (Permitido: 1, 2, 3).'; 
            RETURN FALSE; 
        END IF;

    -- Validar Banco
        IF jid_banco IS NULL OR jid_banco <= 0 THEN 
            RAISE NOTICE 'Error: ID Banco inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_bancos WHERE id_banco = jid_banco;
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: El Banco seleccionado no existe o está inactivo.'; 
            RETURN FALSE; 
        END IF;

    -- Validar Cadenas de Texto (Nulos, Vacíos y Longitud Excesiva)
    -- Num Documento
        IF jnum_documento IS NULL OR TRIM(jnum_documento) = '' THEN 
            RAISE NOTICE 'Error: Número de documento no puede estar vacío.'; 
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

    -- Email
        IF jmail_empleado IS NULL OR TRIM(jmail_empleado) = '' THEN 
            RAISE NOTICE 'Error: Email no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(jmail_empleado) > 255 THEN 
            RAISE NOTICE 'Error: Email excede 255 caracteres.'; 
            RETURN FALSE; 
        END IF;

        IF jmail_empleado !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN 
            RAISE NOTICE 'Error: Formato de email inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Teléfono
        IF jtel_empleado IS NULL OR jtel_empleado !~ '^[0-9]{7,10}$' THEN 
            RAISE NOTICE 'Error: Teléfono inválido (debe tener entre 7 y 10 dígitos numéricos).'; 
            RETURN FALSE; 
        END IF;

    -- Número de Cuenta
        IF jnum_cuenta IS NULL OR jnum_cuenta !~ '^[0-9]{10,20}$' THEN
            RAISE NOTICE 'Error: El número de cuenta es obligatorio y debe tener entre 10 y 20 dígitos numéricos.';
            RETURN FALSE;
        END IF;

    -- Peso (CHECK > 40 AND < 200)
        IF jind_peso IS NULL THEN 
            RAISE NOTICE 'Error: Peso nulo.'; 
            RETURN FALSE; 
        END IF;

        IF jind_peso <= 40 OR jind_peso >= 200 THEN 
            RAISE NOTICE 'Error: Peso inválido (40-200 kg).'; 
            RETURN FALSE; 
        END IF;

    -- Altura (CHECK > 1.30 AND < 2.50)
        IF jind_altura IS NULL THEN 
            RAISE NOTICE 'Error: Altura nula.'; 
            RETURN FALSE; 
        END IF;

        IF jind_altura <= 1.30 OR jind_altura >= 2.50 THEN 
            RAISE NOTICE 'Error: Altura inválida (1.30m - 2.50m).'; 
            RETURN FALSE; 
        END IF;

    -- Fechas
        IF jind_fecha_contratacion IS NULL THEN 
            RAISE NOTICE 'Error: Fecha contratación nula.'; 
            RETURN FALSE; 
        END IF;

        IF jult_fec_exam IS NULL THEN 
            RAISE NOTICE 'Error: Fecha examen nula.'; 
            RETURN FALSE; 
        END IF;

        IF jult_fec_exam > CURRENT_DATE THEN 
            RAISE NOTICE 'Error: La fecha del examen no puede ser futura.'; 
            RETURN FALSE; 
        END IF;

    -- Validar Unicidad Lógica
        SELECT EXISTS (SELECT 1 FROM tab_empleados WHERE id_documento = jid_documento AND num_documento = jnum_documento AND id_empleado != jid_empleado AND ind_vivo=TRUE) INTO existe_duplicado;
        
        IF existe_duplicado THEN 
            RAISE NOTICE 'Error: Ya existe otro empleado con ese documento.'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar Datos
        UPDATE tab_empleados
        SET id_documento = jid_documento,
            id_ciudad = jid_ciudad,
            id_cargo = jid_cargo,
            id_tipo_sangre = jid_tipo_sangre,
            ind_genero = jind_genero,
            num_documento = TRIM(jnum_documento),
            prim_nom = TRIM(jprim_nom),
            segun_nom = TRIM(jsegun_nom),
            prim_apell = TRIM(jprim_apell),
            segun_apell = TRIM(jsegun_apell),
            mail_empleado = TRIM(jmail_empleado),
            tel_empleado = jtel_empleado,
            ind_fecha_contratacion = jind_fecha_contratacion,
            ind_peso = jind_peso,
            ind_altura = jind_altura,
            ult_fec_exam = jult_fec_exam,
            observ = TRIM(jobserv),
            id_banco = jid_banco,
            num_cuenta = TRIM(jnum_cuenta)
        WHERE id_empleado = jid_empleado;

        RAISE NOTICE 'Empleado actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado en BD: %', SQLERRM;
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

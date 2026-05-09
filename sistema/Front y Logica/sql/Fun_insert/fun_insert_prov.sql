drop function if exists fun_insert_proveedor;

CREATE OR REPLACE FUNCTION fun_insert_proveedor (jid_docum tab_proveedores.id_documento%TYPE,
                                                jid_ciudad tab_proveedores.id_ciudad%TYPE,
                                                jnum_doc tab_proveedores.num_documento%TYPE,
                                                jnom_prov tab_proveedores.nom_prov%TYPE,
                                                jtel tab_proveedores.tel_prov%TYPE,
                                                jmail tab_proveedores.mail_prov%TYPE,
                                                jdir tab_proveedores.dir_prov%TYPE,
                                                jcalidad tab_proveedores.ind_calidad%TYPE)
                                                RETURNS BOOLEAN AS
$$
    DECLARE 
        jid_nuevo tab_proveedores.id_prov%TYPE;
        
    BEGIN
        -- 1. IDs
        IF jid_docum IS NULL OR jid_docum <= 0 THEN 
            RAISE EXCEPTION 'Error: Tipo de Documento inválido.'; 
        END IF;

        IF jid_ciudad IS NULL OR jid_ciudad <= 0 THEN 
            RAISE EXCEPTION 'Error: Ciudad inválida.'; 
        END IF;

        -- 2. NOMBRE EMPRESA
        IF jnom_prov IS NULL OR TRIM(jnom_prov) = '' THEN 
            RAISE EXCEPTION 'Error: Nombre del proveedor vacío.'; 
        END IF;

        IF LENGTH(TRIM(jnom_prov)) < 3 THEN 
            RAISE EXCEPTION 'Error: Nombre del proveedor muy corto (Mínimo 3 caracteres).'; 
        END IF;

        IF jnom_prov !~ '^[a-zA-Z0-9ñÑáéíóúÁÉÍÓÚ\s.,\-&()]+$' THEN 
            RAISE EXCEPTION 'Error: Nombre del proveedor contiene caracteres prohibidos.'; 
        END IF;

        -- 3. NIT / DOCUMENTO
        IF jnum_doc IS NULL OR TRIM(jnum_doc) = '' THEN 
            RAISE EXCEPTION 'Error: NIT o Documento vacío.'; 
        END IF;

        IF LENGTH(TRIM(jnum_doc)) < 5 THEN 
            RAISE EXCEPTION 'Error: NIT muy corto.'; 
        END IF;

        IF jnum_doc !~ '^[0-9\-\.]+$' THEN 
            RAISE EXCEPTION 'Error: NIT solo permite números, puntos y guiones.'; 
        END IF;

        -- 4. EMAIL
        IF jmail IS NULL OR TRIM(jmail) = '' THEN 
            RAISE EXCEPTION 'Error: Email vacío.'; 
        END IF;

        IF jmail !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN 
            RAISE EXCEPTION 'Error: Formato de Email inválido.'; 
        END IF;

        -- 5. TELÉFONO
        IF jtel IS NULL OR jtel !~ '^[0-9]{7,10}$' THEN 
            RAISE EXCEPTION 'Error: Teléfono inválido (debe tener entre 7 y 10 dígitos numéricos).'; 
        END IF;

        -- 6. CALIDAD (Opcional, pero si viene, validar)
        IF jcalidad IS NOT NULL AND TRIM(jcalidad) <> '' THEN
             IF LENGTH(TRIM(jcalidad)) < 4 THEN
                RAISE EXCEPTION 'Error: Descripción de calidad muy corta.'; 
             END IF;
             
             IF jcalidad !~ '^[a-zA-Z0-9ñÑáéíóúÁÉÍÓÚ\s.,;]+$' THEN 
                RAISE EXCEPTION 'Error: Descripción de calidad con caracteres especiales prohibidos.'; 
             END IF;
        END IF;

        -- Inserción 
        SELECT COALESCE(MAX(id_prov), 0) + 1 INTO jid_nuevo FROM tab_proveedores;
                
        INSERT INTO tab_proveedores (
                id_prov, id_documento, id_ciudad, num_documento, 
                nom_prov, tel_prov, mail_prov, dir_prov, ind_calidad,
                user_insert, fec_insert, ind_vivo) 
        VALUES (
                jid_nuevo, jid_docum, jid_ciudad, TRIM(jnum_doc), 
                TRIM(jnom_prov), jtel, TRIM(jmail), TRIM(jdir), COALESCE(TRIM(jcalidad), ''),
                COALESCE(current_setting('specialized.app_user', true), CURRENT_USER),
                CURRENT_TIMESTAMP, TRUE);

        RETURN TRUE;

EXCEPTION
    WHEN unique_violation THEN 
        RAISE EXCEPTION 'Error: Ya existe un proveedor con este NIT, Nombre, Email o Teléfono.'; 
    WHEN foreign_key_violation THEN 
        RAISE EXCEPTION 'Error: El ID de Ciudad o Tipo de Documento no existe.'; 
    WHEN string_data_right_truncation THEN
        RAISE EXCEPTION 'Error: Algunos datos exceden el tamaño permitido (NIT máx 20, Tel máx 10).';
    WHEN OTHERS THEN 
        RAISE EXCEPTION 'Error inesperado: %', SQLERRM;
END;
$$ 
LANGUAGE plpgsql;
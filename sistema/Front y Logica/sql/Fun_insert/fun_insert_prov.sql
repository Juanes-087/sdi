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
            RAISE NOTICE 'Error: Tipo de Documento inválido.'; 
            RETURN FALSE;
        END IF;

        IF jid_ciudad IS NULL OR jid_ciudad <= 0 THEN 
            RAISE NOTICE 'Error: Ciudad inválida.'; 
            RETURN FALSE;
        END IF;

        -- 2. NOMBRE EMPRESA
        IF jnom_prov IS NULL OR TRIM(jnom_prov) = '' THEN 
            RAISE NOTICE 'Error: Nombre del proveedor vacío.'; 
            RETURN FALSE;
        END IF;

        IF LENGTH(TRIM(jnom_prov)) < 3 THEN 
            RAISE NOTICE 'Error: Nombre del proveedor muy corto (Mínimo 3 caracteres).'; 
            RETURN FALSE;
        END IF;

        IF jnom_prov !~ '^[a-zA-Z0-9ñÑáéíóúÁÉÍÓÚ\s.,\-&()]+$' THEN 
            RAISE NOTICE 'Error: Nombre del proveedor contiene caracteres prohibidos.'; 
            RETURN FALSE;
        END IF;

        -- 3. NIT / DOCUMENTO
        IF jnum_doc IS NULL OR TRIM(jnum_doc) = '' THEN 
            RAISE NOTICE 'Error: NIT o Documento vacío.'; 
            RETURN FALSE;
        END IF;

        IF LENGTH(TRIM(jnum_doc)) < 5 THEN 
            RAISE NOTICE 'Error: NIT muy corto.'; 
            RETURN FALSE;
        END IF;

        IF jnum_doc !~ '^[0-9\-\.]+$' THEN 
            RAISE NOTICE 'Error: NIT solo permite números, puntos y guiones.'; 
            RETURN FALSE;
        END IF;

        -- 4. EMAIL
        IF jmail IS NULL OR TRIM(jmail) = '' THEN 
            RAISE NOTICE 'Error: Email vacío.'; 
            RETURN FALSE;
        END IF;

        IF jmail !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN 
            RAISE NOTICE 'Error: Formato de Email inválido.'; 
            RETURN FALSE;
        END IF;

        -- 5. TELÉFONO
        IF jtel IS NULL OR jtel !~ '^[0-9]{7,10}$' THEN 
            RAISE NOTICE 'Error: Teléfono inválido (debe tener entre 7 y 10 dígitos numéricos).'; 
            RETURN FALSE; 
        END IF;

        -- 6. CALIDAD (Opcional, pero si viene, validar)
        IF jcalidad IS NOT NULL AND TRIM(jcalidad) <> '' THEN
             IF LENGTH(TRIM(jcalidad)) < 4 THEN
                RAISE NOTICE 'Error: Descripción de calidad muy corta.'; 
                RETURN FALSE;
             END IF;
             
             IF jcalidad !~ '^[a-zA-Z0-9ñÑáéíóúÁÉÍÓÚ\s.,;]+$' THEN 
                RAISE NOTICE 'Error: Descripción de calidad con caracteres especiales prohibidos.'; 
                RETURN FALSE;
             END IF;
        END IF;

        -- Inserción 
        SELECT COALESCE(MAX(id_prov), 0) + 1 INTO jid_nuevo FROM tab_proveedores;
                
        INSERT INTO tab_proveedores (
                id_prov, id_documento, id_ciudad, num_documento, 
                nom_prov, tel_prov, mail_prov, dir_prov, ind_calidad) 
        VALUES (
                jid_nuevo, jid_docum, jid_ciudad, TRIM(jnum_doc), 
                TRIM(jnom_prov), jtel, TRIM(jmail), TRIM(jdir), COALESCE(TRIM(jcalidad), ''));

        RAISE NOTICE 'Proveedor % registrado exitosamente.', jid_nuevo; 
        RETURN TRUE;

EXCEPTION
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Ya existe un proveedor con este NIT, Nombre, Email o Teléfono.'; 
        RETURN FALSE;
    WHEN foreign_key_violation THEN 
        RAISE NOTICE 'Error: El ID de Ciudad o Tipo de Documento no existe.'; 
        RETURN FALSE;
    WHEN string_data_right_truncation THEN
        RAISE NOTICE 'Error: Algunos datos exceden el tamaño permitido de la columna.';
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$ 
LANGUAGE plpgsql;
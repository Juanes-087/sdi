CREATE OR REPLACE FUNCTION fun_insert_tipo_doc  (jnom_tipo tab_tipo_documentos.nom_tipo_docum%TYPE)
                                                RETURNS BOOLEAN AS
$$
    DECLARE 
        jid_nuevo tab_tipo_documentos.id_documento%TYPE;

    BEGIN
        -- Validaciones
        IF jnom_tipo IS NULL THEN 
            RAISE NOTICE 'Error: Nombre de Tipo de Documento no puede ser nulo.'; 
            RETURN FALSE; 
        END IF;

        IF TRIM(jnom_tipo) = '' THEN 
            RAISE NOTICE 'Error: Nombre de Tipo de Documento no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnom_tipo)) < 2 THEN 
            RAISE NOTICE 'Error: Nombre de Tipo de Documento muy corto (Mínimo 2 caracteres).'; 
            RETURN FALSE; 
        END IF;
        
        IF jnom_tipo !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
            RAISE NOTICE 'Error: Nombre de Tipo de Documento solo debe contener letras.'; 
            RETURN FALSE; 
        END IF;

        -- Inserción
        SELECT COALESCE(MAX(id_documento), 0) + 1 INTO jid_nuevo FROM tab_tipo_documentos;
        
        INSERT INTO tab_tipo_documentos (id_documento, nom_tipo_docum) VALUES (jid_nuevo, TRIM(jnom_tipo));
        RAISE NOTICE 'Tipo de Documento % creado exitosamente.', jid_nuevo; 
        RETURN TRUE;

EXCEPTION 
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Ya existe este Tipo de Documento.';
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error inesperado: %', SQLERRM; 
        RETURN FALSE;
END;
$$ 
LANGUAGE plpgsql;
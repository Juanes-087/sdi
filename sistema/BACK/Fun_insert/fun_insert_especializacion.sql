CREATE OR REPLACE FUNCTION fun_insert_especializacion   (jnom_espec tab_tipo_especializacion.nom_espec%TYPE)
                                                        RETURNS BOOLEAN AS
$$
    DECLARE 
        jid_nuevo tab_tipo_especializacion.id_especializacion%TYPE;
    BEGIN 
    -- Validaciones
        IF jnom_espec IS NULL THEN 
            RAISE NOTICE 'Error: Nombre de especialización no puede ser nulo.'; 
            RETURN FALSE;
        END IF;

        IF TRIM(jnom_espec) = '' THEN 
            RAISE NOTICE 'Error: Nombre de especialización no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnom_espec)) < 4 THEN 
            RAISE NOTICE 'Error: Nombre de especialización muy corto (Mínimo 4 caracteres).'; 
            RETURN FALSE; 
        END IF;

        IF jnom_espec !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
            RAISE NOTICE 'Error: Nombre de especialización solo debe contener letras.'; 
            RETURN FALSE; 
        END IF;
    
    -- Inserción
        SELECT COALESCE(MAX(id_especializacion), 0) + 1 INTO jid_nuevo FROM tab_tipo_especializacion;
        
        INSERT INTO tab_tipo_especializacion (id_especializacion, nom_espec) VALUES (jid_nuevo, TRIM(jnom_espec));
        RAISE NOTICE 'Especialización % creada exitosamente.', jid_nuevo; 
        RETURN TRUE;

EXCEPTION 
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Ya existe una especialización con ese nombre.';
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error inesperado: %', SQLERRM; 
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
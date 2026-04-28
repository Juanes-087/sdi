CREATE OR REPLACE FUNCTION fun_insert_cargo (jnom_cargo tab_cargos.nom_cargo%TYPE)
                                            RETURNS BOOLEAN AS
$$
    DECLARE jid_nuevo tab_cargos.id_cargo%TYPE;
            
BEGIN
    -- Validaciones
        IF jnom_cargo IS NULL THEN 
            RAISE NOTICE 'Error: El nombre del cargo no puede ser nulo.'; 
            RETURN FALSE; 
        END IF;

        IF TRIM(jnom_cargo) = '' THEN 
            RAISE NOTICE 'Error: El nombre del cargo no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnom_cargo)) < 4 THEN 
            RAISE NOTICE 'Error: El nombre del cargo es muy corto (Mínimo 4 caracteres).'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnom_cargo)) > 50 THEN 
            RAISE NOTICE 'Error: El nombre del cargo es muy largo (Máximo 50 caracteres).'; 
            RETURN FALSE;
        END IF;

        IF jnom_cargo !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
            RAISE NOTICE 'Error: El nombre del cargo solo debe contener letras.'; 
            RETURN FALSE; 
        END IF;

    -- Inserción
        SELECT COALESCE(MAX(id_cargo), 0) + 1 INTO jid_nuevo FROM tab_cargos;
        
        INSERT INTO tab_cargos (id_cargo, nom_cargo) VALUES (jid_nuevo, TRIM(jnom_cargo));
        
        RAISE NOTICE 'Cargo % creado exitosamente.', jid_nuevo; 
        RETURN TRUE;

EXCEPTION
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Ya existe un cargo con ese nombre.'; 
        RETURN FALSE;
    WHEN string_data_right_truncation THEN
        RAISE NOTICE 'Error: El texto es demasiado largo para el campo.';
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$ 
LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fun_insert_ciudades(jid_ciudad tab_ciudades.id_ciudad%TYPE,
                                               jid_depart tab_ciudades.id_depart%TYPE,
                                               jnom_ciudad tab_ciudades.nom_ciudad%TYPE) 
                                               RETURNS BOOLEAN AS
$$
    DECLARE j_check_val INTEGER;
    
BEGIN
    -- Validaciones IDs
        IF jid_ciudad IS NULL OR jid_ciudad <= 0 THEN 
            RAISE NOTICE 'Error: Código de ciudad inválido (Debe ser > 0).'; 
            RETURN FALSE; 
        END IF;

        IF jid_depart IS NULL OR jid_depart <= 0 THEN 
            RAISE NOTICE 'Error: Código de departamento inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Validar FK Departamento
        SELECT 1 INTO j_check_val FROM tab_departamentos WHERE id_depart = jid_depart LIMIT 1;
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: El departamento especificado no existe.';
            RETURN FALSE;
        END IF;

    -- Validaciones Texto
        IF jnom_ciudad IS NULL OR TRIM(jnom_ciudad) = '' THEN 
            RAISE NOTICE 'Error: Nombre de ciudad vacío.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnom_ciudad)) < 3 THEN 
            RAISE NOTICE 'Error: Nombre de ciudad muy corto.'; 
            RETURN FALSE; 
        END IF;

        IF jnom_ciudad !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
            RAISE NOTICE 'Error: Nombre de ciudad solo debe contener letras.'; 
            RETURN FALSE; 
        END IF;

    -- Insertar (ID Manual)
        INSERT INTO tab_ciudades (id_ciudad, id_depart, nom_ciudad) 
        VALUES (jid_ciudad, jid_depart, TRIM(jnom_ciudad));

        RAISE NOTICE 'Ciudad % registrada exitosamente.', jid_ciudad;
        RETURN TRUE;

EXCEPTION
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Ya existe registrada una ciudad con ese Código.'; 
        RETURN FALSE;
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Error: Departamento no válido (Error FK).';
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error inesperado: %', SQLERRM; 
        RETURN FALSE;
END;
$$ 
LANGUAGE plpgsql;

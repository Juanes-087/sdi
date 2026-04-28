CREATE OR REPLACE FUNCTION fun_insert_unidad_medida (jnom_unidad tab_unidades_medida.nom_unidad%TYPE)
                                                    RETURNS BOOLEAN AS
$$
    DECLARE jid_nuevo tab_unidades_medida.id_unidad_medida%TYPE;
            
BEGIN
    -- Validaciones
        IF jnom_unidad IS NULL THEN 
            RAISE NOTICE 'Error: El nombre de la unidad no puede ser nulo.'; 
            RETURN FALSE; 
        END IF;

        IF TRIM(jnom_unidad) = '' THEN 
            RAISE NOTICE 'Error: El nombre de la unidad no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnom_unidad)) > 20 THEN 
            RAISE NOTICE 'Error: El nombre de la unidad es muy largo (Máximo 20 caracteres).'; 
            RETURN FALSE; 
        END IF;
        
    -- Inserción
        SELECT COALESCE(MAX(id_unidad_medida), 0) + 1 INTO jid_nuevo FROM tab_unidades_medida;
        
        INSERT INTO tab_unidades_medida (id_unidad_medida, nom_unidad, user_insert, fec_insert) 
        VALUES (jid_nuevo, TRIM(jnom_unidad), CURRENT_USER, NOW());
        RAISE NOTICE 'Unidad de medida % registrada exitosamente.', jid_nuevo; 
        RETURN TRUE;

EXCEPTION 
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Ya existe una unidad de medida con ese nombre.';
        RETURN FALSE;
    WHEN string_data_right_truncation THEN
        RAISE NOTICE 'Error: El texto excede el límite permitido.';
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error inesperado: %', SQLERRM; 
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;

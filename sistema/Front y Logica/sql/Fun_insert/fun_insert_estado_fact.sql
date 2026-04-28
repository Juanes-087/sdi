CREATE OR REPLACE FUNCTION fun_insert_estado_fact (jnom_estado tab_estado_fact.nom_estado_fact%TYPE)
                                                    RETURNS BOOLEAN AS
$$
    DECLARE jid_nuevo tab_estado_fact.id_estado_fact%TYPE;

BEGIN
    -- Validaciones
        IF jnom_estado IS NULL OR TRIM(jnom_estado) = '' THEN 
            RAISE NOTICE 'Error: Nombre de estado vacío.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnom_estado)) < 3 THEN 
            RAISE NOTICE 'Error: Nombre de estado muy corto.'; 
            RETURN FALSE; 
        END IF;

        IF jnom_estado !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
            RAISE NOTICE 'Error: Caracteres inválidos en estado.'; 
            RETURN FALSE; 
        END IF;

    -- Generar ID
        SELECT COALESCE(MAX(id_estado_fact), 0) + 1 INTO jid_nuevo 
        FROM tab_estado_fact;

    -- Insertar
        INSERT INTO tab_estado_fact (id_estado_fact, nom_estado_fact) 
        VALUES (jid_nuevo, TRIM(jnom_estado));

        RAISE NOTICE 'Estado Factura % registrado.', jid_nuevo;
        RETURN TRUE;

EXCEPTION
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Ya existe ese Estado.'; 
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error inesperado: %', SQLERRM; 
        RETURN FALSE;
END;
$$ 
LANGUAGE plpgsql;

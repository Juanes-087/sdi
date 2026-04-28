CREATE OR REPLACE FUNCTION fun_insert_tipo_sangre (jnom_sangre tab_tipo_sangre.nom_tip_sang%TYPE)
                                                    RETURNS BOOLEAN AS
$$
    DECLARE jid_nuevo tab_tipo_sangre.id_tipo_sangre%TYPE;

BEGIN
    -- Validaciones
        IF jnom_sangre IS NULL OR TRIM(jnom_sangre) = '' THEN 
            RAISE NOTICE 'Error: Tipo de sangre vacío.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnom_sangre)) < 2 THEN 
            RAISE NOTICE 'Error: Tipo inválido (Ej: O+, A-).'; 
            RETURN FALSE; 
        END IF;

        IF jnom_sangre !~ '^[ABO]{1,2}[+-]$' THEN 
            RAISE NOTICE 'Error: Formato inválido (Use mayúsculas: O+, AB-).'; 
            RETURN FALSE; 
        END IF;

    -- Generar ID
        SELECT COALESCE(MAX(id_tipo_sangre), 0) + 1 INTO jid_nuevo 
        FROM tab_tipo_sangre;

    -- Insertar
        INSERT INTO tab_tipo_sangre (id_tipo_sangre, nom_tip_sang) 
        VALUES (jid_nuevo, TRIM(jnom_sangre));

        RAISE NOTICE 'Tipo de Sangre % registrado.', jid_nuevo;
        RETURN TRUE;

EXCEPTION
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Ya existe ese Tipo de Sangre.'; 
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error inesperado: %', SQLERRM; 
        RETURN FALSE;
END;
$$ 
LANGUAGE plpgsql;

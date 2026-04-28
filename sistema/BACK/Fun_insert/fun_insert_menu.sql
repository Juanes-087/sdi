CREATE OR REPLACE FUNCTION fun_insert_menu  (jnom_menu tab_menu.nom_menu%TYPE)
                                            RETURNS BOOLEAN AS
$$
    DECLARE jid_nuevo tab_menu.id_menu%TYPE;

BEGIN
    -- Validaciones
        IF jnom_menu IS NULL OR TRIM(jnom_menu) = '' THEN 
            RAISE NOTICE 'Error: Nombre del menú vacío.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnom_menu)) < 3 THEN 
            RAISE NOTICE 'Error: Nombre del menú muy corto.'; 
            RETURN FALSE; 
        END IF;

        IF jnom_menu !~ '^[a-zA-Z0-9ñÑáéíóúÁÉÍÓÚ\s\.\-_]+$' THEN 
            RAISE NOTICE 'Error: Caracteres inválidos en menú.'; 
            RETURN FALSE; 
        END IF;

    -- Generar ID
        SELECT COALESCE(MAX(id_menu), 0) + 1 INTO jid_nuevo 
        FROM tab_menu;

    -- Insertar
        INSERT INTO tab_menu (id_menu, nom_menu) 
        VALUES (jid_nuevo, TRIM(jnom_menu));

        RAISE NOTICE 'Menú % registrado.', jid_nuevo;
        RETURN TRUE;

EXCEPTION
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Ya existe ese Menú.'; 
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error inesperado: %', SQLERRM; 
        RETURN FALSE;
END;
$$ 
LANGUAGE plpgsql;

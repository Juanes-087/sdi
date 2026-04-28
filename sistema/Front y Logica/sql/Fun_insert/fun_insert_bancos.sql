CREATE OR REPLACE FUNCTION fun_insert_bancos (jid_ciudad tab_bancos.id_ciudad%TYPE,
                                              jnom_banco tab_bancos.nom_banco%TYPE,
                                              jdir_banco tab_bancos.dir_banco%TYPE) 
                                              RETURNS BOOLEAN AS
$$
    DECLARE jid_nuevo tab_bancos.id_banco%TYPE;
            j_check_val INTEGER;

BEGIN
    -- Validaciones FK
        IF jid_ciudad IS NULL OR jid_ciudad <= 0 THEN
            RAISE NOTICE 'Error: Ciudad inválida.';
            RETURN FALSE;
        END IF;

        SELECT 1 INTO j_check_val FROM tab_ciudades WHERE id_ciudad = jid_ciudad;
        
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: La ciudad no existe.';
            RETURN FALSE;
        END IF;

    -- Validaciones Texto
        IF jnom_banco IS NULL OR TRIM(jnom_banco) = '' THEN 
            RAISE NOTICE 'Error: Nombre del banco vacío.'; 
            RETURN FALSE; 
        END IF;

        IF jdir_banco IS NULL OR TRIM(jdir_banco) = '' THEN
            RAISE NOTICE 'Error: Dirección del banco vacía.';
            RETURN FALSE;
        END IF;

        IF LENGTH(TRIM(jnom_banco)) < 3 THEN 
            RAISE NOTICE 'Error: Nombre del banco muy corto.'; 
            RETURN FALSE; 
        END IF;

        IF jnom_banco !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
            RAISE NOTICE 'Error: Nombre del banco solo debe contener letras.'; 
            RETURN FALSE; 
        END IF;

    -- Generar ID
        SELECT COALESCE(MAX(id_banco), 0) + 1 INTO jid_nuevo 
        FROM tab_bancos;

    -- Insertar
        INSERT INTO tab_bancos (id_banco, id_ciudad, nom_banco, dir_banco) 
        VALUES (jid_nuevo, jid_ciudad, TRIM(jnom_banco), TRIM(jdir_banco));

        RAISE NOTICE 'Banco % registrado exitosamente.', jid_nuevo;
        RETURN TRUE;

EXCEPTION
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Ya existe un banco con ese nombre.'; 
        RETURN FALSE;
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Error: Referencia inválida.';
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error inesperado: %', SQLERRM; 
        RETURN FALSE;
END;
$$ 
LANGUAGE plpgsql;

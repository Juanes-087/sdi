CREATE OR REPLACE FUNCTION fun_insert_departamento  (jid_dian tab_departamentos.id_depart%TYPE,
                                                    jnom_depart tab_departamentos.nom_depart%TYPE)
                                                    RETURNS BOOLEAN AS
$$
    BEGIN
    -- Validaciones Numéricas
        IF jid_dian IS NULL THEN 
                RAISE NOTICE 'Error: ID DIAN no puede ser nulo.'; 
                RETURN FALSE; 
        END IF;

        IF jid_dian <= 0 THEN 
                RAISE NOTICE 'Error: ID DIAN debe ser mayor a cero.'; 
                RETURN FALSE; 
        END IF;

        IF jid_dian > 100 THEN -- Ajuste logico para departamentos colombianos (aprox 32 + codigos especiales)
                RAISE NOTICE 'Aviso: ID DIAN inusualmente alto, verifique.'; 
                -- RETURN FALSE; -- Descomentar si se quiere bloquear
        END IF;

    -- Validaciones Texto
        IF jnom_depart IS NULL OR TRIM(jnom_depart) = '' THEN 
                RAISE NOTICE 'Error: Nombre del departamento vacío.'; 
                RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnom_depart)) < 4 THEN 
                RAISE NOTICE 'Error: Nombre del departamento muy corto (Mínimo 4 caracteres).'; 
                RETURN FALSE; 
        END IF;

        IF jnom_depart !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
                RAISE NOTICE 'Error: Nombre del departamento contiene caracteres inválidos.'; 
                RETURN FALSE; 
        END IF;

    -- Inserción
        INSERT INTO tab_departamentos (id_depart, nom_depart) VALUES (jid_dian, TRIM(jnom_depart));
        RAISE NOTICE 'Departamento registrado exitosamente.'; 
        RETURN TRUE;

EXCEPTION
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: El ID o Nombre del departamento ya existe.'; 
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error inesperado: %', SQLERRM; 
        RETURN FALSE;
END;
$$ 
LANGUAGE plpgsql;
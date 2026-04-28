CREATE OR REPLACE FUNCTION fun_insert_cat_mat (jnom_cat tab_cat_mat_prim.nom_categoria%TYPE)
                                              RETURNS BOOLEAN AS
$$
    DECLARE jid_nuevo tab_cat_mat_prim.id_cat_mat%TYPE;
            
BEGIN
    -- Validaciones
        IF jnom_cat IS NULL THEN 
            RAISE NOTICE 'Error: El nombre de la categoría no puede ser nulo.'; 
            RETURN FALSE; 
        END IF;

        IF TRIM(jnom_cat) = '' THEN 
            RAISE NOTICE 'Error: El nombre de la categoría no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnom_cat)) < 3 THEN 
            RAISE NOTICE 'Error: El nombre de la categoría es muy corto (Mínimo 3 caracteres).'; 
            RETURN FALSE; 
        END IF;
        
        IF jnom_cat !~ '^[a-zA-ZñÑáéíóúÁÉÍÓÚ\s]+$' THEN 
            RAISE NOTICE 'Error: El nombre de la categoría solo debe contener letras.'; 
            RETURN FALSE;     
        END IF;

    -- Inserción
        SELECT COALESCE(MAX(id_cat_mat), 0) + 1 INTO jid_nuevo FROM tab_cat_mat_prim;
        
        INSERT INTO tab_cat_mat_prim (id_cat_mat, nom_categoria) VALUES (jid_nuevo, TRIM(jnom_cat));
        RAISE NOTICE 'Categoría de Materia Prima % creada exitosamente.', jid_nuevo; 
        RETURN TRUE;

EXCEPTION 
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Ya existe una categoría con ese nombre.';
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
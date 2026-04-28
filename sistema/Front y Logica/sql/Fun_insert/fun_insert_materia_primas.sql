/*
    -----------------------------------------------------------------------------
    PRUEBAS DE VALIDACIÓN
    -----------------------------------------------------------------------------
    1. Insertar Materia Prima Válida:
       SELECT fun_insert_materia_primas(1, 'Acero 1020', 10, 100);

    2. Error Stock Negativo (Script tiene Check >= 0, funcion valida < 0):
       SELECT fun_insert_materia_primas(1, 'Error Stock', -5, 100);

    3. Error Stock Min >= Stock Max:
       SELECT fun_insert_materia_primas(1, 'Error Rango', 50, 40);

    4. Error Categoría Inexistente:
       SELECT fun_insert_materia_primas(9999, 'Cat Error', 10, 100);
    -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_insert_materia_primas(jid_cat_mat tab_materias_primas.id_cat_mat%TYPE,
                                                    jnom_mat tab_materias_primas.nom_materia_prima%TYPE,
                                                    jstock_min tab_materias_primas.stock_min%TYPE,
                                                    jstock_max tab_materias_primas.stock_max%TYPE,
                                                    jimg_url tab_materias_primas.img_url%TYPE) 
                                                    RETURNS BOOLEAN AS
$$
    DECLARE jid_nuevo tab_materias_primas.id_mat_prima%TYPE;
            j_check_val INTEGER;
BEGIN
    -- Validaciones FK
        IF jid_cat_mat IS NULL OR jid_cat_mat <= 0 THEN 
            RAISE NOTICE 'Error: Categoría inválida.'; 
            RETURN FALSE; 
        END IF;

        SELECT 1 INTO j_check_val FROM tab_cat_mat_prim WHERE id_cat_mat = jid_cat_mat LIMIT 1;
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: La Categoría especificada no existe.';
            RETURN FALSE;
        END IF;

    -- Validaciones Texto
        IF jnom_mat IS NULL OR TRIM(jnom_mat) = '' THEN 
            RAISE NOTICE 'Error: Nombre de materia prima vacío.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnom_mat)) < 3 THEN 
            RAISE NOTICE 'Error: Nombre muy corto.'; 
            RETURN FALSE; 
        END IF;

        IF jnom_mat !~ '^[a-zA-Z0-9ñÑáéíóúÁÉÍÓÚ\s\.\-]+$' THEN 
            RAISE NOTICE 'Error: Caracteres inválidos en nombre.'; 
            RETURN FALSE; 
        END IF;

        -- Validacion URL Imagen
        IF jimg_url IS NULL OR TRIM(jimg_url) = '' THEN
            RAISE NOTICE 'Error: URL de imagen obligatoria.';
            RETURN FALSE;
        END IF;

    -- Validaciones Stock
        IF jstock_min IS NULL OR jstock_min < 0 THEN 
            RAISE NOTICE 'Error: Stock mínimo inválido.'; 
            RETURN FALSE; 
        END IF;

        IF jstock_max IS NULL OR jstock_max <= 0 THEN 
            RAISE NOTICE 'Error: Stock máximo inválido.'; 
            RETURN FALSE; 
        END IF;

        IF jstock_min >= jstock_max THEN
            RAISE NOTICE 'Error: El stock mínimo no puede ser mayor o igual al máximo.';
            RETURN FALSE;
        END IF;

    -- Generar ID
        SELECT COALESCE(MAX(id_mat_prima), 0) + 1 INTO jid_nuevo 
        FROM tab_materias_primas;

    -- Insertar
        INSERT INTO tab_materias_primas (id_mat_prima, id_cat_mat, nom_materia_prima, stock_min, stock_max, img_url) 
        VALUES (jid_nuevo, jid_cat_mat, TRIM(jnom_mat), jstock_min, jstock_max, TRIM(jimg_url));

        RAISE NOTICE 'Materia Prima % registrada exitosamente.', jid_nuevo;
        RETURN TRUE;

EXCEPTION
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Ya existe MP con ese nombre.'; 
        RETURN FALSE;
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Error: Referencia a categoría inválida.';
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error inesperado: %', SQLERRM; 
        RETURN FALSE;
END;
$$ 
LANGUAGE plpgsql;

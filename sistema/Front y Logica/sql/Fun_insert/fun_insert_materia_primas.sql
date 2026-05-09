/*
    -----------------------------------------------------------------------------
    PRUEBAS DE VALIDACIÓN
    -----------------------------------------------------------------------------
    1. Insertar Materia Prima Válida:
       SELECT fun_insert_materia_primas(1, 'Acero 1020', 10, 100, '/img.jpg', 45000);

    2. Error Precio Negativo:
       SELECT fun_insert_materia_primas(1, 'Error Precio', 10, 100, '/img.jpg', -1);
    -----------------------------------------------------------------------------
*/


drop function if exists fun_insert_materia_primas;

-----------------------------------------------------------------------------
-- FUNCIÓN: fun_insert_materia_primas
-- PROPÓSITO: Registra una nueva materia prima y su primer precio histórico.
-- DISPARADOR: Se llama al guardar el formulario de "Agregar Materia Prima".
-- LLAMADO DESDE: querys.php -> insertMateriaPrima()
-----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fun_insert_materia_primas(jid_cat_mat tab_materias_primas.id_cat_mat%TYPE,
                                                    jnom_mat tab_materias_primas.nom_materia_prima%TYPE,
                                                    jstock_min tab_materias_primas.stock_min%TYPE,
                                                    jstock_max tab_materias_primas.stock_max%TYPE,
                                                    jimg_url tab_materias_primas.img_url%TYPE,
                                                    jprecio DECIMAL) 
                                                    RETURNS BOOLEAN AS
$$
    DECLARE jid_nuevo tab_materias_primas.id_mat_prima%TYPE;
            jid_historico tab_historico_mat_prima.id_historico%TYPE;
            jid_prov_def tab_proveedores.id_prov%TYPE;
            j_check_val INTEGER;
BEGIN
    -- 1. Validación de integridad de datos
    IF jnom_mat IS NULL OR jnom_mat = '' THEN RETURN FALSE; END IF;

    -- 2. GENERACIÓN AUTOMÁTICA DE ID (Sin COALESCE)
    -- Buscamos el último ID y le sumamos 1. Si no hay nada, empezamos en 1.
    SELECT MAX(id_mat_prima) INTO jid_nuevo FROM tab_materias_primas;
    IF jid_nuevo IS NULL THEN
        jid_nuevo := 1;
    ELSE
        jid_nuevo := jid_nuevo + 1;
    END IF;

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

    -- Validación Precio
        IF jprecio IS NULL OR jprecio < 0 THEN
            RAISE NOTICE 'Error: El precio inicial es obligatorio y no puede ser negativo.';
            RETURN FALSE;
        END IF;

    -- Generar ID
        SELECT MAX(id_mat_prima) INTO jid_nuevo FROM tab_materias_primas;
        IF jid_nuevo IS NULL THEN
            jid_nuevo := 1;
        ELSE
            jid_nuevo := jid_nuevo + 1;
        END IF;

    -- Insertar Materia Prima
        INSERT INTO tab_materias_primas (id_mat_prima, id_cat_mat, nom_materia_prima, stock_min, stock_max, img_url) 
        VALUES (jid_nuevo, jid_cat_mat, TRIM(jnom_mat), jstock_min, jstock_max, TRIM(jimg_url));

    -- Registrar Precio Inicial en Histórico
        SELECT MAX(id_historico) INTO jid_historico FROM tab_historico_mat_prima;
        IF jid_historico IS NULL THEN
            jid_historico := 1;
        ELSE
            jid_historico := jid_historico + 1;
        END IF;
        
        -- Buscamos un proveedor por defecto (el primero disponible o uno genérico si existiera)
        SELECT id_prov INTO jid_prov_def FROM tab_proveedores WHERE ind_vivo = TRUE LIMIT 1;
        
        IF jid_prov_def IS NULL THEN
            RAISE NOTICE 'Aviso: No hay proveedores activos para vincular el precio inicial. Se omitió el registro histórico.';
        ELSE
            INSERT INTO tab_historico_mat_prima (id_historico, id_materia_prima, id_proveedor, precio_anterior, precio_nuevo, fecha_cambio, motivo)
            VALUES (jid_historico, jid_nuevo, jid_prov_def, 0, jprecio, NOW(), 'Precio inicial de registro');
        END IF;

        RAISE NOTICE 'Materia Prima % registrada exitosamente con precio inicial %.', jid_nuevo, jprecio;
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

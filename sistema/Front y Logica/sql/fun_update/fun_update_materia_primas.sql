/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID MP Nulo:           SELECT fun_update_materias_primas(NULL, 1, 'Nom', 10, 20);
   2.  ID MP Negativo:       SELECT fun_update_materias_primas(-1, 1, 'Nom', 10, 20);
   3.  ID Cat Nulo:          SELECT fun_update_materias_primas(1, NULL, 'Nom', 10, 20);
   4.  ID Cat Negativo:      SELECT fun_update_materias_primas(1, -5, 'Nom', 10, 20);
   5.  Nombre Vacío:         SELECT fun_update_materias_primas(1, 1, '', 10, 20);
   6.  Stock Min Neg:        SELECT fun_update_materias_primas(1, 1, 'Nom', -5, 20);
   7.  Stock Max < Min:      SELECT fun_update_materias_primas(1, 1, 'Nom', 20, 10);
   8.  SQL Inj (Nom):        SELECT fun_update_materias_primas(1, 1, '''; DROP TABLE tab_mp; --', 10, 20);
   9.  ID MP Inexistente:    SELECT fun_update_materias_primas(99999, 1, 'Nom', 10, 20);
   10. CASO EXITOSO:         SELECT fun_update_materias_primas(1, 1, 'Acero Inoxidable Grado Médico', 100, 500);
   -----------------------------------------------------------------------------
*/

drop function if exists fun_update_materias_primas;

CREATE OR REPLACE FUNCTION fun_update_materias_primas   (jid_mat_prima tab_materias_primas.id_mat_prima%TYPE,
                                                        jid_cat_mat tab_materias_primas.id_cat_mat%TYPE,
                                                        jnom_materia_prima tab_materias_primas.nom_materia_prima%TYPE,
                                                        jstock_min tab_materias_primas.stock_min%TYPE,
                                                        jstock_max tab_materias_primas.stock_max%TYPE,
                                                        jimg_url tab_materias_primas.img_url%TYPE,
                                                        jprecio DECIMAL)
                                                        RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
            jprecio_actual DECIMAL;
            jid_historico INT;
            jid_prov_def INT;
BEGIN
    -- Validar ID
        IF jid_mat_prima IS NULL OR jid_mat_prima <= 0 THEN 
            RAISE NOTICE 'Error: ID de materia prima inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_materias_primas WHERE id_mat_prima = jid_mat_prima;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Materia Prima con ID % no encontrada.', jid_mat_prima;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: La Materia Prima con ID % se encuentra eliminada. No se puede actualizar.', jid_mat_prima;
            RETURN FALSE;
        END IF;

    -- Validar FK Categoria
        IF jid_cat_mat IS NULL OR jid_cat_mat <= 0 THEN 
            RAISE NOTICE 'Error: ID de categoría inválido.'; 
            RETURN FALSE; 
        END IF;
        
        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_cat_mat_prim WHERE id_cat_mat = jid_cat_mat;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Categoría referenciada no existe o está inactiva.'; 
            RETURN FALSE; 
        END IF;

    -- 1. DETECCIÓN DE CAMBIO DE PRECIO
    -- Obtenemos el precio registrado actualmente para comparar
    SELECT precio_nuevo INTO jprecio_actual 
    FROM tab_historico_mat_prima 
    WHERE id_materia_prima = jid_mat_prima 
    ORDER BY fecha_cambio DESC 
    LIMIT 1;

    -- Si el precio ha cambiado (o no existía), registramos en el historial
    IF jprecio_actual IS NULL OR jprecio_actual != jprecio THEN
        -- Generar ID de historial sin COALESCE
        SELECT MAX(id_historico) INTO jid_historico FROM tab_historico_mat_prima;
        IF jid_historico IS NULL THEN jid_historico := 1; ELSE jid_historico := jid_historico + 1; END IF;

        -- Buscamos el proveedor vinculado
        SELECT id_prov INTO jid_prov_def FROM tab_mat_primas_prov WHERE id_mat_prima = jid_mat_prima LIMIT 1;
        
        IF jid_prov_def IS NOT NULL THEN
            INSERT INTO tab_historico_mat_prima (id_historico, id_materia_prima, id_proveedor, precio_anterior, precio_nuevo, fecha_cambio, motivo)
            VALUES (jid_historico, jid_mat_prima, jid_prov_def, COALESCE(jprecio_actual, 0), jprecio, NOW(), 'Actualización manual');
        END IF;
    END IF;

    -- Actualizar tabla principal
        UPDATE tab_materias_primas 
        SET id_cat_mat = jid_cat_mat, 
            nom_materia_prima = jnom_materia_prima,
            stock_min = jstock_min,
            stock_max = jstock_max,
            img_url = TRIM(jimg_url)
        WHERE id_mat_prima = jid_mat_prima;
        
        RAISE NOTICE 'Materia Prima actualizada exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

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
CREATE OR REPLACE FUNCTION fun_update_materias_primas   (jid_mat_prima tab_materias_primas.id_mat_prima%TYPE,
                                                        jid_cat_mat tab_materias_primas.id_cat_mat%TYPE,
                                                        jnom_materia_prima tab_materias_primas.nom_materia_prima%TYPE,
                                                        jstock_min tab_materias_primas.stock_min%TYPE,
                                                        jstock_max tab_materias_primas.stock_max%TYPE,
                                                        jimg_url tab_materias_primas.img_url%TYPE)
                                                        RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
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

    -- Validar Nombre
        IF jnom_materia_prima IS NULL OR TRIM(jnom_materia_prima)='' THEN 
            RAISE NOTICE 'Error: El nombre de la materia prima no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;

    -- Validar URL
        IF jimg_url IS NULL OR TRIM(jimg_url)='' THEN 
            RAISE NOTICE 'Error: La URL de la imagen no puede estar vacía.'; 
            RETURN FALSE; 
        END IF;

    -- Validar Stock
        IF jstock_min < 0 THEN 
            RAISE NOTICE 'Error: Stock mínimo no puede ser negativo.'; 
            RETURN FALSE; 
        END IF;

        IF jstock_max < 0 THEN 
            RAISE NOTICE 'Error: Stock máximo no puede ser negativo.'; 
            RETURN FALSE; 
        END IF;

        IF jstock_max < jstock_min THEN 
            RAISE NOTICE 'Error: Stock máximo no puede ser menor al stock mínimo.'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
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

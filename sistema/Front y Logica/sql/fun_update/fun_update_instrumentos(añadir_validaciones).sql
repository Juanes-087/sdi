/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Inst Nulo:         SELECT fun_update_instrumentos(NULL, 1, 'Bisturi', 'L1', 10, 5, 20, 'INV', 1, 'Acero', 'url');
   2.  ID Inst Negativo:     SELECT fun_update_instrumentos(-1, 1, 'Bisturi', 'L1', 10, 5, 20, 'INV', 1, 'Acero', 'url');
   3.  Especializ Nulo:      SELECT fun_update_instrumentos(1, NULL, 'Bisturi', 'L1', 10, 5, 20, 'INV', 1, 'Acero', 'url');
   4.  Especializ Invalida:  SELECT fun_update_instrumentos(1, 99999, 'Bisturi', 'L1', 10, 5, 20, 'INV', 1, 'Acero', 'url');
   5.  Cantidad Negativa:    SELECT fun_update_instrumentos(1, 1, 'Bisturi', 'L1', -10, 5, 20, 'INV', 1, 'Acero', 'url');
   6.  Stock Min Neg:        SELECT fun_update_instrumentos(1, 1, 'Bisturi', 'L1', 10, -5, 20, 'INV', 1, 'Acero', 'url');
   7.  Stock Max < Min:      SELECT fun_update_instrumentos(1, 1, 'Bisturi', 'L1', 10, 20, 5, 'INV', 1, 'Acero', 'url');
   8.  Nombre Vacío:         SELECT fun_update_instrumentos(1, 1, '', 'L1', 10, 5, 20, 'INV', 1, 'Acero', 'url');
   9.  Invima Vacío:         SELECT fun_update_instrumentos(1, 1, 'Bisturi', 'L1', 10, 5, 20, '', 1, 'Acero', 'url');
   10. CASO EXITOSO:         SELECT fun_update_instrumentos(1, 1, 'Bisturí Láser', 'LOTE-2026', 25, 5, 50, 'INVIMA-2026', 1, 'Quirúrgico', 'url.png');
   -----------------------------------------------------------------------------
*/

drop function if exists fun_update_instrumentos;    

CREATE OR REPLACE FUNCTION fun_update_instrumentos  (jid_instrumento tab_instrumentos.id_instrumento%TYPE,
                                                    jid_especializacion tab_instrumentos.id_especializacion%TYPE,
                                                    jnom_instrumento tab_instrumentos.nom_instrumento%TYPE,
                                                    jlote tab_instrumentos.lote%TYPE,
                                                    jcant_disp tab_instrumentos.cant_disp%TYPE,
                                                    jstock_min tab_instrumentos.stock_min%TYPE,
                                                    jstock_max tab_instrumentos.stock_max%TYPE,
                                                    jnumeral_en_kit tab_instrumentos.numeral_en_kit%TYPE,
                                                    jtipo_mat tab_instrumentos.tipo_mat%TYPE,
                                                    jimg_url tab_instrumentos.img_url%TYPE)
                                                    RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_instrumento IS NULL OR jid_instrumento <= 0 THEN 
            RAISE EXCEPTION 'Error: ID Instrumento inválido.'; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_instrumentos WHERE id_instrumento = jid_instrumento;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE EXCEPTION 'Error: Instrumento con ID % no encontrado.', jid_instrumento;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE EXCEPTION 'Error: El Instrumento con ID % se encuentra eliminado. No se puede actualizar.', jid_instrumento;
        END IF;

    -- Validar FK Especializacion
        IF jid_especializacion IS NULL OR jid_especializacion <= 0 THEN 
            RAISE EXCEPTION 'Error: ID Especialización inválido.'; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_tipo_especializacion WHERE id_especializacion = jid_especializacion;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE EXCEPTION 'Error: Especialización no existe o está inactiva.'; 
        END IF;

    -- Validaciones Lógicas
        IF jcant_disp < 0 THEN 
            RAISE EXCEPTION 'Error: La cantidad no puede ser negativa.'; 
        END IF;

        IF jstock_min < 0 THEN 
            RAISE EXCEPTION 'Error: Stock mínimo no puede ser negativo.'; 
        END IF;

        IF jstock_max < 0 THEN 
            RAISE EXCEPTION 'Error: Stock máximo no puede ser negativo.'; 
        END IF;

        IF jstock_max < jstock_min THEN 
            RAISE EXCEPTION 'Error: Stock máximo no puede ser menor al stock mínimo.'; 
        END IF;

        IF jnom_instrumento IS NULL OR TRIM(jnom_instrumento)='' THEN 
            RAISE EXCEPTION 'Error: El nombre del instrumento no puede estar vacío.'; 
        END IF;

    -- Actualizar
        UPDATE tab_instrumentos SET
            id_especializacion = jid_especializacion,
            nom_instrumento = jnom_instrumento,
            lote = COALESCE(jlote, 0),
            cant_disp = jcant_disp,
            stock_min = COALESCE(jstock_min, 0),
            stock_max = COALESCE(jstock_max, 0),
            numeral_en_kit = COALESCE(jnumeral_en_kit, 0),
            tipo_mat = jtipo_mat,
            img_url = jimg_url
        WHERE id_instrumento = jid_instrumento;
        
        RAISE NOTICE 'Instrumento actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE EXCEPTION 'Error inesperado: %', SQLERRM; 
END;
$$ LANGUAGE plpgsql;

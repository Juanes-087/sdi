/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Prov Nulo:         SELECT fun_update_mat_primas_prov(NULL, 1, 100, 'T', 10, 50);
   2.  ID MP Nulo:           SELECT fun_update_mat_primas_prov(1, NULL, 100, 'T', 10, 50);
   3.  Cantidad Negativa:    SELECT fun_update_mat_primas_prov(1, 1, 100, 'T', 10, -50);
   4.  Lote Negativo:        SELECT fun_update_mat_primas_prov(1, 1, -100, 'T', 10, 50);
   5.  Medida Negativa:      SELECT fun_update_mat_primas_prov(1, 1, 100, 'T', -10, 50);
   6.  Tipo Vacío:           SELECT fun_update_mat_primas_prov(1, 1, 100, '', 10, 50);
   7.  ID Prov Invalido:     SELECT fun_update_mat_primas_prov(99999, 1, 100, 'T', 10, 50);
   8.  ID MP Invalido:       SELECT fun_update_mat_primas_prov(1, 99999, 100, 'T', 10, 50);
   9.  SQL Inj (Tipo):       SELECT fun_update_mat_primas_prov(1, 1, 100, '''; DROP --', 10, 50);
   10. CASO EXITOSO:         SELECT fun_update_mat_primas_prov(1, 1, 202401, 'Acero Quirúrgico', 100, 5000);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_mat_primas_prov (jid_prov tab_mat_primas_prov.id_prov%TYPE,
                                                        jid_mat_prima tab_mat_primas_prov.id_mat_prima%TYPE,
                                                        jlote tab_mat_primas_prov.lote%TYPE,
                                                        jtipo_mat_prima tab_mat_primas_prov.tipo_mat_prima%TYPE,
                                                        jvalor_medida tab_mat_primas_prov.valor_medida%TYPE,
                                                        jid_unidad_medida tab_mat_primas_prov.id_unidad_medida%TYPE,
                                                        jcant_mat_prima tab_mat_primas_prov.cant_mat_prima%TYPE)
                                                        RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validar IDs
        IF jid_prov IS NULL OR jid_prov <= 0 THEN 
            RAISE NOTICE 'Error: ID de proveedor inválido.'; 
            RETURN FALSE; 
        END IF;

        IF jid_mat_prima IS NULL OR jid_mat_prima <= 0 THEN 
            RAISE NOTICE 'Error: ID de materia prima inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo 
        FROM tab_mat_primas_prov 
        WHERE id_prov = jid_prov AND id_mat_prima = jid_mat_prima;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Relación Materia Prima - Proveedor no encontrada.';
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: La Relación se encuentra eliminada (inactiva).';
            RETURN FALSE;
        END IF;

    -- Validaciones Lógicas
        IF jcant_mat_prima IS NULL OR jcant_mat_prima < 0 THEN 
            RAISE NOTICE 'Error: Cantidad no puede ser negativa.'; 
            RETURN FALSE; 
        END IF;

        IF jlote IS NULL OR jlote < 0 THEN 
            RAISE NOTICE 'Error: Lote no puede ser negativo.'; 
            RETURN FALSE; 
        END IF;


        IF jtipo_mat_prima IS NULL OR TRIM(jtipo_mat_prima)='' THEN 
            RAISE NOTICE 'Error: Tipo de materia prima no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;

        IF jvalor_medida IS NULL OR jvalor_medida <= 0 THEN 
            RAISE NOTICE 'Error: Valor de medida inválido.'; 
            RETURN FALSE; 
        END IF;

        IF jid_unidad_medida IS NULL OR jid_unidad_medida <= 0 THEN 
            RAISE NOTICE 'Error: ID Unidad de medida inválido.'; 
            RETURN FALSE; 
        END IF;

        -- Validar existencia Unidad de Medida
        SELECT ind_vivo INTO j_ind_vivo FROM tab_unidades_medida WHERE id_unidad_medida = jid_unidad_medida;
        IF j_ind_vivo IS NULL OR j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: Unidad de medida no existe o está inactiva.';
            RETURN FALSE;
        END IF;

    -- Actualizar
        UPDATE tab_mat_primas_prov SET
            lote = jlote,
            tipo_mat_prima = jtipo_mat_prima,
            valor_medida = jvalor_medida,
            id_unidad_medida = jid_unidad_medida,
            cant_mat_prima = jcant_mat_prima
        WHERE id_prov = jid_prov AND id_mat_prima = jid_mat_prima;
        
        RAISE NOTICE 'Relación Materia Prima - Proveedor actualizada exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

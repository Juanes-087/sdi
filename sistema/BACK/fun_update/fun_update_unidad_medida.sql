CREATE OR REPLACE FUNCTION fun_update_unidad_medida   (jid_unidad_medida tab_unidades_medida.id_unidad_medida%TYPE,
                                                     jnom_unidad tab_unidades_medida.nom_unidad%TYPE)
                                                     RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_unidad_medida IS NULL OR jid_unidad_medida <= 0 THEN
            RAISE NOTICE 'Error: ID de unidad de medida inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado check
        SELECT ind_vivo INTO j_ind_vivo FROM tab_unidades_medida WHERE id_unidad_medida = jid_unidad_medida;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Unidad de medida con ID % no encontrada.', jid_unidad_medida;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: La unidad de medida con ID % se encuentra eliminada. No se puede actualizar.', jid_unidad_medida;
            RETURN FALSE;
        END IF;

    -- Validar Nombre
        IF jnom_unidad IS NULL OR TRIM(jnom_unidad) = '' THEN
            RAISE NOTICE 'Error: El nombre de la unidad no puede estar vacío.';
            RETURN FALSE;
        END IF;

        IF LENGTH(TRIM(jnom_unidad)) > 20 THEN 
            RAISE NOTICE 'Error: El nombre de la unidad es muy largo (Máximo 20 caracteres).'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
        UPDATE tab_unidades_medida 
        SET nom_unidad = TRIM(jnom_unidad),
            user_update = CURRENT_USER,
            fec_update = NOW()
        WHERE id_unidad_medida = jid_unidad_medida;
        
        RAISE NOTICE 'Unidad de medida actualizada exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

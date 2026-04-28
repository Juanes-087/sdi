CREATE OR REPLACE FUNCTION fun_delete_unidad_medida(jid_unidad_medida tab_unidades_medida.id_unidad_medida%TYPE) 
                                                   RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_unidad_medida IS NULL THEN
            RAISE NOTICE 'Error: ID de unidad de medida nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_unidad_medida <= 0 THEN
            RAISE NOTICE 'Error: ID de unidad de medida inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_unidades_medida WHERE id_unidad_medida = jid_unidad_medida;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Unidad de medida con ID % no encontrada.', jid_unidad_medida;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: La unidad de medida con ID % ya fue eliminado anteriormente.', jid_unidad_medida;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_unidades_medida SET    user_delete = CURRENT_USER,
                                          fec_delete = CURRENT_TIMESTAMP,
                                          ind_vivo = FALSE
                                          Where id_unidad_medida = jid_unidad_medida;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar la unidad de medida con ID %.', jid_unidad_medida;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Unidad de medida con ID % eliminada exitosamente.', jid_unidad_medida;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;

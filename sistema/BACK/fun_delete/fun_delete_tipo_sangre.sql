/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Sangre Nulo:       SELECT fun_delete_tip_sangre(NULL);
   2.  ID Sangre Negativo:   SELECT fun_delete_tip_sangre(-1);
   3.  ID Sangre Cero:       SELECT fun_delete_tip_sangre(0);
   4.  ID Inexistente:       SELECT fun_delete_tip_sangre(99999);
   5.  Ya eliminado:         SELECT fun_delete_tip_sangre(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_tip_sangre(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_tip_sangre(2147483647);
   8.  Min Int Value:        SELECT fun_delete_tip_sangre(-2147483648);
   9.  Float Cast:           SELECT fun_delete_tip_sangre(1.0::INT);
   10. CASO EXITOSO:         SELECT fun_delete_tip_sangre(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_tip_sangre(jid_tipo_sangre tab_tipo_sangre.id_tipo_sangre%TYPE) 
                                                 RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_tipo_sangre IS NULL THEN
            RAISE NOTICE 'Error: ID de tipo de sangre nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_tipo_sangre <= 0 THEN
            RAISE NOTICE 'Error: ID de tipo de sangre inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_tipo_sangre WHERE id_tipo_sangre = jid_tipo_sangre;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Tipo de Sangre con ID % no encontrado.', jid_tipo_sangre;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El Tipo de Sangre con ID % ya fue eliminado anteriormente.', jid_tipo_sangre;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_tipo_sangre SET    user_delete = CURRENT_USER,
                                      fec_delete = CURRENT_TIMESTAMP,
                                      ind_vivo = FALSE
                                      Where id_tipo_sangre = jid_tipo_sangre;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el Tipo de Sangre con ID %.', jid_tipo_sangre;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Tipo de Sangre con ID % eliminado exitosamente.', jid_tipo_sangre;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
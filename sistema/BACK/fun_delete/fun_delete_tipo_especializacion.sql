/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Espec Nulo:        SELECT fun_delete_tip_espec(NULL);
   2.  ID Espec Negativo:    SELECT fun_delete_tip_espec(-1);
   3.  ID Espec Cero:        SELECT fun_delete_tip_espec(0);
   4.  ID Inexistente:       SELECT fun_delete_tip_espec(99999);
   5.  Ya eliminado:         SELECT fun_delete_tip_espec(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_tip_espec(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_tip_espec(2147483647);
   8.  Min Int Value:        SELECT fun_delete_tip_espec(-2147483648);
   9.  Float Cast:           SELECT fun_delete_tip_espec(9.9::INT);
   10. CASO EXITOSO:         SELECT fun_delete_tip_espec(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_tip_espec(jid_especializacion tab_tipo_especializacion.id_especializacion%TYPE)
                                                RETURNS BOOLEAN AS
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_especializacion IS NULL THEN
            RAISE NOTICE 'Error: ID de especialización nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_especializacion <= 0 THEN
            RAISE NOTICE 'Error: ID de especialización inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_tipo_especializacion WHERE id_especializacion = jid_especializacion;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Tipo de especialización con ID % no encontrado.', jid_especializacion;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El Tipo de especialización con ID % ya fue eliminado anteriormente.', jid_especializacion;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_tipo_especializacion SET user_delete = CURRENT_USER,
                                            fec_delete = CURRENT_TIMESTAMP,
                                            ind_vivo = FALSE
                                            Where id_especializacion = jid_especializacion;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el Tipo de especialización con ID %.', jid_especializacion;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Tipo de especialización con ID % eliminado exitosamente.', jid_especializacion;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
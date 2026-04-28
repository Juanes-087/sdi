/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Inst-Kit Nulo:     SELECT fun_delete_instrum_kit(NULL);
   2.  ID Inst-Kit Negativo: SELECT fun_delete_instrum_kit(-1);
   3.  ID Inst-Kit Cero:     SELECT fun_delete_instrum_kit(0);
   4.  ID Inexistente:       SELECT fun_delete_instrum_kit(99999);
   5.  Ya eliminado:         SELECT fun_delete_instrum_kit(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_instrum_kit(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_instrum_kit(2147483647);
   8.  Min Int Value:        SELECT fun_delete_instrum_kit(-2147483648);
   9.  Float Cast:           SELECT fun_delete_instrum_kit(1.5::INT);
   10. CASO EXITOSO:         SELECT fun_delete_instrum_kit(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_instrum_kit(jid_instrumento_kit tab_instrumentos_kit.id_instrumento_kit%TYPE) 
                                                  RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_instrumento_kit IS NULL THEN
            RAISE NOTICE 'Error: ID de instrumento-kit nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_instrumento_kit <= 0 THEN
            RAISE NOTICE 'Error: ID de instrumento-kit inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_instrumentos_kit WHERE id_instrumento_kit = jid_instrumento_kit;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Kit con instrumentos (ID %) no encontrado.', jid_instrumento_kit;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El Kit con instrumentos con ID % ya fue eliminado anteriormente.', jid_instrumento_kit;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_instrumentos_kit SET user_delete = CURRENT_USER,
                                        fec_delete = CURRENT_TIMESTAMP,
                                        ind_vivo = FALSE
                                        Where id_instrumento_kit = jid_instrumento_kit;

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el Kit con instrumentos con ID %.', jid_instrumento_kit;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Kit con instrumentos con ID % eliminado exitosamente.', jid_instrumento_kit;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
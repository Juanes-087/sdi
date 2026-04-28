/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Kit Nulo:          SELECT fun_delete_kit(NULL);
   2.  ID Kit Negativo:      SELECT fun_delete_kit(-1);
   3.  ID Kit Cero:          SELECT fun_delete_kit(0);
   4.  ID Inexistente:       SELECT fun_delete_kit(99999);
   5.  Ya eliminado:         SELECT fun_delete_kit(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_kit(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_kit(2147483647);
   8.  Min Int Value:        SELECT fun_delete_kit(-2147483648);
   9.  SQL Inyection:        SELECT fun_delete_kit(1 OR 1=1);
   10. CASO EXITOSO:         SELECT fun_delete_kit(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_kit(jid_kit tab_kits.id_kit%TYPE)
                                          RETURNS BOOLEAN AS
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_kit IS NULL THEN
            RAISE NOTICE 'Error: ID de kit nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_kit <= 0 THEN
            RAISE NOTICE 'Error: ID de kit inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_kits WHERE id_kit = jid_kit;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Kit con ID % no encontrado.', jid_kit;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El Kit con ID % ya fue eliminado anteriormente.', jid_kit;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_kits SET     user_delete = CURRENT_USER,
                                fec_delete = CURRENT_TIMESTAMP,
                                ind_vivo = FALSE
                                Where id_kit = jid_kit;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el Kit con ID %.', jid_kit;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Kit con ID % eliminado exitosamente.', jid_kit;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
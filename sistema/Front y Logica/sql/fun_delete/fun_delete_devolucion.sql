/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Devolución Nulo:   SELECT fun_delete_devolucion(NULL);
   2.  ID Devolución Neg:    SELECT fun_delete_devolucion(-1);
   3.  ID Devolución Cero:   SELECT fun_delete_devolucion(0);
   4.  ID Inexistente:       SELECT fun_delete_devolucion(99999);
   5.  Ya eliminado:         SELECT fun_delete_devolucion(2);
   6.  CASO EXITOSO:         SELECT fun_delete_devolucion(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_devolucion(jid_devolucion tab_dev.id_factura%TYPE) 
                                                 RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_devolucion IS NULL THEN
            RAISE NOTICE 'Error: ID de devolución nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_devolucion <= 0 THEN
            RAISE NOTICE 'Error: ID de devolución inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_dev WHERE id_factura = jid_devolucion;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Devolución con ID % no encontrada.', jid_devolucion;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: La devolución con ID % ya fue eliminada anteriormente.', jid_devolucion;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_dev SET user_delete = CURRENT_USER,
                                    fec_delete = CURRENT_TIMESTAMP,
                                    ind_vivo = FALSE
                                    Where id_factura = jid_devolucion;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar la devolución con ID %.', jid_devolucion;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Devolución con ID % eliminada exitosamente.', jid_devolucion;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Detalle Nulo:      SELECT fun_delete_detalle_factura(NULL);
   2.  ID Detalle Negativo:  SELECT fun_delete_detalle_factura(-1);
   3.  ID Detalle Cero:      SELECT fun_delete_detalle_factura(0);
   4.  ID Inexistente:       SELECT fun_delete_detalle_factura(99999);
   5.  Ya eliminado:         SELECT fun_delete_detalle_factura(2); -- Asumiendo ID 2 eliminado
   6.  CASO EXITOSO:         SELECT fun_delete_detalle_factura(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_detalle_factura(jid_detalle tab_detalle_facturas.id_detalle_factura%TYPE) 
                                                      RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_detalle IS NULL THEN
            RAISE NOTICE 'Error: ID de detalle de factura nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_detalle <= 0 THEN
            RAISE NOTICE 'Error: ID de detalle de factura inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_detalle_facturas WHERE id_detalle_factura = jid_detalle;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Detalle con ID % no encontrado.', jid_detalle;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El detalle con ID % ya fue eliminado anteriormente.', jid_detalle;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_detalle_facturas SET user_delete = CURRENT_USER,
                                        fec_delete = CURRENT_TIMESTAMP,
                                        ind_vivo = FALSE
                                        Where id_detalle_factura = jid_detalle;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el detalle con ID %.', jid_detalle;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Detalle con ID % eliminado exitosamente.', jid_detalle;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;

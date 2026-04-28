/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Factura Nulo:      SELECT fun_delete_fact(NULL);
   2.  ID Factura Negativo:  SELECT fun_delete_fact(-1);
   3.  ID Factura Cero:      SELECT fun_delete_fact(0);
   4.  ID Inexistente:       SELECT fun_delete_fact(99999);
   5.  Ya eliminado:         SELECT fun_delete_fact(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_fact(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_fact(2147483647);
   8.  Min Int Value:        SELECT fun_delete_fact(-2147483648);
   9.  Float Cast:           SELECT fun_delete_fact(1.5::INT);
   10. CASO EXITOSO:         SELECT fun_delete_fact(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_fact(jid_factura tab_facturas.id_factura%TYPE)
                                           RETURNS BOOLEAN AS
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_factura IS NULL THEN
            RAISE NOTICE 'Error: ID de factura nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_factura <= 0 THEN
            RAISE NOTICE 'Error: ID de factura inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_facturas WHERE id_factura = jid_factura;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Factura con ID % no encontrada.', jid_factura;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: La factura con ID % ya fue eliminada anteriormente.', jid_factura;
            RETURN FALSE;
        END IF;
    
    -- 3. Hacer el soft delete del Detalle
        UPDATE tab_detalle_facturas SET     user_delete = CURRENT_USER,
                                            fec_delete = CURRENT_TIMESTAMP,
                                            ind_vivo = FALSE
                                            Where id_factura = jid_factura
                                            AND ind_vivo = TRUE;

    -- 4. Borrar el encabezado
        UPDATE tab_facturas SET             user_delete = CURRENT_USER,
                                            fec_delete = CURRENT_TIMESTAMP,
                                            ind_vivo = FALSE
                                            Where id_factura = jid_factura;  

     -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el Encabezado de la factura con ID %.', jid_factura;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Factura con ID % y sus detalles (si tenía) eliminados exitosamente.', jid_factura;
            RETURN TRUE;
        END IF;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
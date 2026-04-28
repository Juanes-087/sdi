/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Factura Nulo:      SELECT fun_update_facturas(NULL, 1, 1, 1, NOW(), 100);
   2.  ID Factura Neg:       SELECT fun_update_facturas(-1, 1, 1, 1, NOW(), 100);
   3.  ID Cliente Invalido:  SELECT fun_update_facturas(1, -1, 1, 1, NOW(), 100);
   4.  ID Estado Invalido:   SELECT fun_update_facturas(1, 1, -1, 1, NOW(), 100);
   5.  Forma Pago Invalido:  SELECT fun_update_facturas(1, 1, 1, 0, NOW(), 100);
   6.  Forma Pago OutRange:  SELECT fun_update_facturas(1, 1, 1, 5, NOW(), 100);
   7.  Total Negativo:       SELECT fun_update_facturas(1, 1, 1, 1, NOW(), -500);
   8.  ID Fact Inexistente:  SELECT fun_update_facturas(99999, 1, 1, 1, NOW(), 100);
   9.  Fecha Nula:           SELECT fun_update_facturas(1, 1, 1, 1, NULL, 100);
   10. CASO EXITOSO:         SELECT fun_update_facturas(1, 1, 1, 2, CURRENT_DATE, 250000);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_facturas  (jid_factura tab_facturas.id_factura%TYPE,
                                                jid_cliente tab_facturas.id_cliente%TYPE,
                                                jid_estado_fact tab_facturas.id_estado_fact%TYPE,
                                                jind_forma_pago tab_facturas.ind_forma_pago%TYPE,
                                                jfecha_venta tab_facturas.fecha_venta%TYPE,
                                                jval_tot_fact tab_facturas.val_tot_fact%TYPE)
                                                RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_factura <= 0 THEN 
            RAISE NOTICE 'Error: ID Factura inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_facturas WHERE id_factura = jid_factura;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Factura con ID % no encontrada.', jid_factura;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: La Factura con ID % se encuentra eliminada. No se puede actualizar.', jid_factura;
            RETURN FALSE;
        END IF;

    -- Validar FK Cliente
        IF jid_cliente <= 0 THEN 
            RAISE NOTICE 'Error: ID Cliente inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_clientes WHERE id_cliente = jid_cliente;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Cliente no existe o inactivo.'; 
            RETURN FALSE; 
        END IF;
        
    -- Validar FK Estado
        IF jid_estado_fact <= 0 THEN 
            RAISE NOTICE 'Error: ID Estado inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_estado_fact WHERE id_estado_fact = jid_estado_fact;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Estado Factura no existe o inactivo.'; 
            RETURN FALSE; 
        END IF;

    -- Validaciones Logicas
        IF jind_forma_pago <= 0 OR jind_forma_pago > 3 THEN 
            RAISE NOTICE 'Error: Forma pago inválida (1-3).'; 
            RETURN FALSE; 
        END IF;

        IF jval_tot_fact < 0 THEN 
            RAISE NOTICE 'Error: Total factura no puede ser negativo.'; 
            RETURN FALSE; 
        END IF;
        
        IF jfecha_venta IS NULL THEN
            RAISE NOTICE 'Error: Fecha de venta no puede ser nula.';
            RETURN FALSE;
        END IF;

    -- Actualizar
        UPDATE tab_facturas SET
            id_cliente = jid_cliente,
            id_estado_fact = jid_estado_fact,
            ind_forma_pago = jind_forma_pago,
            fecha_venta = jfecha_venta,
            val_tot_fact = jval_tot_fact
        WHERE id_factura = jid_factura;
        
        RAISE NOTICE 'Factura actualizada exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

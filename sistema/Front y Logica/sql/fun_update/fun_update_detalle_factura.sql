/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Detalle Nulo:      SELECT fun_update_detalle_factura(NULL, 1, 1, 1, 50, 0, 50, 50);
   2.  ID Factura Nulo:      SELECT fun_update_detalle_factura(1, NULL, 1, 1, 50, 0, 50, 50);
   3.  ID Producto Nulo:     SELECT fun_update_detalle_factura(1, 1, NULL, 1, 50, 0, 50, 50);
   4.  Cantidad Negativa:    SELECT fun_update_detalle_factura(1, 1, 1, -5, 50, 0, 50, 50);
   5.  Precio Negativo:      SELECT fun_update_detalle_factura(1, 1, 1, 1, -50, 0, 50, 50);
   6.  Total Negativo:       SELECT fun_update_detalle_factura(1, 1, 1, 1, 50, 0, 50, -50);
   7.  ID Inexistente (999): SELECT fun_update_detalle_factura(99999, 1, 1, 1, 50, 0, 50, 50);
   8.  Factura Inexistente:  SELECT fun_update_detalle_factura(1, 99999, 1, 1, 50, 0, 50, 50);
   9.  Producto Inexistente: SELECT fun_update_detalle_factura(1, 1, 99999, 1, 50, 0, 50, 50);
   10. CASO EXITOSO:         SELECT fun_update_detalle_factura(1, 1, 1, 2, 50000, 0, 100000, 100000);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_detalle_factura   (jid_detalle_factura tab_detalle_facturas.id_detalle_factura%TYPE,
                                                        jid_factura tab_detalle_facturas.id_factura%TYPE,
                                                        jid_producto tab_detalle_facturas.id_producto%TYPE,
                                                        jcantidad tab_detalle_facturas.cantidad%TYPE,
                                                        jprecio_unitario tab_detalle_facturas.precio_unitario%TYPE,
                                                        jval_descuento tab_detalle_facturas.val_descuento%TYPE,
                                                        jval_bruto tab_detalle_facturas.val_bruto%TYPE,
                                                        jval_neto tab_detalle_facturas.val_neto%TYPE)
                                                        RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_detalle_factura <= 0 THEN 
            RAISE NOTICE 'Error: ID Detalle inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_detalle_facturas WHERE id_detalle_factura = jid_detalle_factura;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Detalle factura con ID % no encontrado.', jid_detalle_factura;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Detalle factura con ID % se encuentra eliminado. No se puede actualizar.', jid_detalle_factura;
            RETURN FALSE;
        END IF;

    -- Validar FK Factura
        IF jid_factura <= 0 THEN 
            RAISE NOTICE 'Error: ID Factura inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_facturas WHERE id_factura = jid_factura;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Factura padre no existe o inactiva.'; 
            RETURN FALSE; 
        END IF;

    -- Validar FK Producto
        IF jid_producto <= 0 THEN 
            RAISE NOTICE 'Error: ID Producto inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_productos WHERE id_producto = jid_producto;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Producto no existe o inactivo.'; 
            RETURN FALSE; 
        END IF;

    -- Validaciones Logicas
        IF jcantidad <= 0 THEN 
            RAISE NOTICE 'Error: Cantidad debe ser mayor a 0.'; 
            RETURN FALSE; 
        END IF;

        IF jprecio_unitario < 0 THEN 
            RAISE NOTICE 'Error: Precio unitario negativo.'; 
            RETURN FALSE; 
        END IF;
        
        IF jval_bruto < 0 OR jval_neto < 0 THEN 
            RAISE NOTICE 'Error: Valores monetarios no pueden ser negativos.'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
        UPDATE tab_detalle_facturas SET
            id_factura = jid_factura,
            id_producto = jid_producto,
            cantidad = jcantidad,
            precio_unitario = jprecio_unitario,
            val_descuento = jval_descuento,
            val_bruto = jval_bruto,
            val_neto = jval_neto
        WHERE id_detalle_factura = jid_detalle_factura;
        
        RAISE NOTICE 'Detalle de factura actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

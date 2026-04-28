-- Select * from tab_facturas
-- Select * from tab_detalle_facturas
-- Select fun_fact (1,1,20);

CREATE OR REPLACE FUNCTION fun_fact (jid_cliente tab_clientes.id_cliente%TYPE,
                                    jid_producto tab_productos.id_producto%TYPE,
                                    jcant tab_detalle_facturas.cantidad%TYPE) 
                                    RETURNS BOOLEAN AS
$$
DECLARE     jreg_parametros   RECORD;
            jreg_producto     RECORD;
            jreg_cliente      RECORD;
            jid_factura       tab_facturas.id_factura%TYPE;
            jid_detalle       tab_detalle_facturas.id_detalle_factura%TYPE;
            jtotal_factura    DECIMAL(10,2);
            jprecio_unitario  DECIMAL(10,2);

BEGIN
      -- Validar cantidad
            IF jcant < 1 THEN
                  Raise notice 'La cantidad debe ser mayor a 0';
                  RETURN FALSE;
            END IF;

      -- Traer parámetros
            Select a.id_empresa, a.nom_empresa, a.dir_empresa, a.tel_empresa, a.val_pordesc, a.val_inifact, a.val_finfact, a.val_actfact, a.val_observa INTO jreg_parametros From tab_parametros a;
            IF NOT FOUND THEN
                  Raise notice 'Error: No hay parámetros configurados';
                  RETURN FALSE;
            END IF;

      -- Validar cliente
            Select id_cliente, prim_nom, prim_apell, ind_vivo INTO jreg_cliente From tab_clientes
            Where id_cliente = jid_cliente;
            IF NOT FOUND THEN
                  Raise notice 'Error: Cliente no encontrado';
                  RETURN FALSE;
            END IF;

      -- Validar producto y obtener su precio
            Select id_producto, nombre_producto, precio_producto INTO jreg_producto From tab_productos
            Where id_producto = jid_producto;
            IF NOT FOUND THEN
                  Raise notice 'Error: Producto no encontrado';
                  RETURN FALSE;
            ELSE
                  IF jreg_parametros.val_actfact >= jreg_parametros.val_finfact THEN
                        Raise notice '¡¡ ALERTA...  ÚLTIMA FACTURA !!';
                  END IF;

                  jprecio_unitario = jreg_producto.precio_producto;

                  -- Actualizar valor actual de la factura
                        jid_factura = jreg_parametros.val_actfact;
                        UPDATE tab_parametros SET val_actfact = val_actfact + 1;
                        IF FOUND THEN
                              Raise notice 'Número de fact. % actualizada en Parametros.',jreg_parametros.val_actfact;
                        ELSE
                              Raise notice 'Error al actualizar parametros, intente nuevamente';
                              RETURN FALSE;
                        END IF;

                  -- Calcular el total
                        jtotal_factura = jcant * jprecio_unitario;

                  -- Insertar encabezado de factura
                        INSERT INTO tab_facturas (id_factura, id_cliente, fecha_venta, val_tot_fact)
                        VALUES (jid_factura, jid_cliente, CURRENT_TIMESTAMP, jtotal_factura);
                        IF FOUND THEN
                              Raise notice 'Encabezado de la factura % creado correctamente.',jid_factura;
                        ELSE
                              Raise notice 'Error al armar el encabezado de la factura, intente nuevamente..';
                              RETURN FALSE;
                        END IF;


                  -- Auto incrementado del id de detalle 
                        Select COALESCE(MAX(id_detalle_factura), 0) + 1 INTO jid_detalle From tab_detalle_facturas;

                  -- Insertar detalle
                        INSERT INTO tab_detalle_facturas (id_detalle_factura, id_factura, id_producto, cantidad, precio_unitario)
                        VALUES (jid_detalle, jid_factura, jid_producto, jcant, jprecio_unitario);
                         IF FOUND THEN
                              Raise notice 'Factura % creada exitosamente para el cliente %. Total: $%',jid_factura, jreg_cliente.prim_nom, jtotal_factura;
                              RETURN TRUE;
                        ELSE
                              Raise notice 'Error al armar el detalle de la factura, intente nuevamente..';
                              RETURN FALSE;
                        END IF;
            END IF;
      
      
EXCEPTION
    WHEN OTHERS THEN
        Raise notice 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql; 
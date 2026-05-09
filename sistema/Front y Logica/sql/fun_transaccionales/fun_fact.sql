/*

-- Pruebas
SELECT fun_fact(1, ARRAY[1, NULL]::INTEGER[], ARRAY[1, 1], 1);
SELECT fun_fact(1, ARRAY[1, 2, 11], ARRAY[5], 1);
SELECT fun_fact(1, ARRAY[]::INTEGER[], ARRAY[]::INTEGER[], 1);
SELECT fun_fact(1, ARRAY[1], ARRAY[-50], 1);
SELECT fun_fact(NULL, ARRAY[1], ARRAY[1], 1);
-- SELECT fun_fact(1, ARRAY['DROP TABLE'], ARRAY[1], 1);
SELECT fun_fact(1, ARRAY[1,1,1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,1,1], ARRAY[1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1], 1);
SELECT fun_fact(1, ARRAY[1, 999999, 11], ARRAY[1, 1, 1], 1);

-- Inserts
SELECT fun_fact(1, ARRAY[1, 11], ARRAY[2, 1], 1);
SELECT fun_fact(2, ARRAY[3], ARRAY[10], 2);
SELECT fun_fact(NULL, ARRAY[17], ARRAY[1], 3);

*/

drop function if exists fun_fact();

CREATE OR REPLACE FUNCTION fun_fact(jid_cliente       INTEGER,
                                    jproductos         INTEGER[], 
                                    jcantidades        INTEGER[],
                                    jid_forma_pago    tab_facturas.ind_forma_pago%TYPE,
                                    jobservaciones    VARCHAR DEFAULT 'N/A'
                                    ) RETURNS INTEGER AS
$$
        DECLARE
            -- Variables datos
            jreg_pmtros         RECORD;
            jreg_cliente        RECORD;
            
            -- Variables control IDs
            jid_factura         INTEGER;
            jid_detalle_actual  INTEGER; 
            jid_kardex_actual   INTEGER; 
            
            jcontador           INTEGER;
            jdif_longitud       INTEGER;
            jid_cliente_final   tab_clientes.id_cliente%TYPE;
            
            -- Variables financieras
            jval_bruto          DECIMAL(12,2); 
            jval_neto           DECIMAL(12,2);
            jval_descuento      DECIMAL(10,2);
            jtotal_factura      DECIMAL(12,2) := 0;
            
            -- Variables producto
            jnom_prod           VARCHAR;
            jprecio_venta       DECIMAL(10,2);
            jtipo_producto      INTEGER; 
            jid_aux             INTEGER;
            jid_instr_final     INTEGER;
            jid_kit_final       INTEGER;
            jstock_actual       INTEGER;

            BEGIN
                BEGIN 
                -- CARGA PARAMETROS
                    SELECT val_actfact, val_finfact, id_ciudad, val_pordesc INTO jreg_pmtros 
                    FROM tab_parametros WHERE id_empresa = 1;

                    IF NOT FOUND THEN 
                        RAISE EXCEPTION 'Error Crítico: No hay parámetros de empresa configurados.'; 
                    END IF;

                -- CLIENTE (Validamos que exista Y esté vivo)
                    IF jid_cliente IS NULL THEN jid_cliente_final := 99999; 
                        ELSE jid_cliente_final := jid_cliente; 
                    END IF;

                    SELECT prim_nom, prim_apell INTO jreg_cliente FROM tab_clientes 
                    WHERE id_cliente = jid_cliente_final AND ind_vivo = TRUE;

                    IF NOT FOUND THEN 
                        RAISE EXCEPTION 'El cliente % no existe o está inactivo en el sistema.', jid_cliente_final; 
                    END IF;

                -- VALIDACIONES DE ARRAYS
                    IF jproductos IS NULL OR jcantidades IS NULL THEN
                        RAISE EXCEPTION 'Error: Los datos de productos o cantidades son nulos.';
                    END IF;

                    IF array_length(jproductos, 1) IS NULL THEN 
                         RAISE EXCEPTION 'Error: La lista de productos está vacía.'; 
                    END IF;
                    
                    jdif_longitud := array_length(jproductos, 1) - array_length(jcantidades, 1);
                    IF jdif_longitud != 0 THEN 
                        RAISE EXCEPTION 'Error: La cantidad de productos no coincide con la cantidad de unidades.'; 
                    END IF;

                    IF jreg_pmtros.val_actfact >= jreg_pmtros.val_finfact THEN 
                        RAISE EXCEPTION 'Alerta: Se han agotado los consecutivos de facturación.'; 
                    END IF;

                -- PREPARAR IDs
                    SELECT COALESCE(MAX(id_detalle_factura), 0) INTO jid_detalle_actual FROM tab_detalle_facturas;
                    SELECT COALESCE(MAX(id_kardex_producto), 0) INTO jid_kardex_actual FROM tab_kardex_productos;

                -- ENCABEZADO FACTURA
                    jid_factura := jreg_pmtros.val_actfact;
        
                -- Actualizamos consecutivo
                    UPDATE tab_parametros SET val_actfact = val_actfact + 1 WHERE id_empresa = 1;

                    INSERT INTO tab_facturas (
                        id_factura, id_cliente, id_estado_fact, ind_forma_pago, fecha_venta, val_tot_fact
                    ) VALUES (
                        jid_factura, jid_cliente_final, 1, jid_forma_pago, NOW(), 0
                    );

                    RAISE NOTICE 'Factura % iniciada.', jid_factura;

                    -- BUCLE PRODUCTOS
                        FOR jcontador IN 1..array_length(jproductos, 1) LOOP
                            
                        -- Validaciones básicas
                            IF jproductos[jcontador] IS NULL OR jcantidades[jcontador] IS NULL OR jcantidades[jcontador] <= 0 THEN
                                RAISE EXCEPTION 'Error de Datos: Producto ID % tiene cantidad inválida.', jproductos[jcontador];
                            END IF;

                            IF jcantidades[jcontador] > 500 THEN
                                RAISE EXCEPTION 'Alerta: Cantidad excesiva (%) para producto ID %.', jcantidades[jcontador], jproductos[jcontador];
                            END IF;

                            jtipo_producto  := 0; 
                            jstock_actual   := NULL;
                            jid_instr_final := NULL;
                            jid_kit_final   := NULL;
                            
                        -- Obtener datos del producto y su origen (Instrumento o Kit)
                            SELECT p.nombre_producto, p.precio_producto, p.id_instrumento, p.id_kit 
                            INTO jnom_prod, jprecio_venta, jid_instr_final, jid_kit_final
                            FROM tab_productos p
                            WHERE p.id_producto = jproductos[jcontador] AND p.ind_vivo = TRUE;
                            
                            IF NOT FOUND THEN 
                                RAISE EXCEPTION 'Error: El producto con ID % no existe o está inactivo.', jproductos[jcontador]; 
                            END IF;

                        -- Determinar tipo y verificar stock
                            IF jid_instr_final IS NOT NULL THEN
                                jtipo_producto := 1;
                                SELECT cant_disp INTO jstock_actual FROM tab_instrumentos 
                                WHERE id_instrumento = jid_instr_final AND ind_vivo = TRUE;
                            ELSIF jid_kit_final IS NOT NULL THEN
                                jtipo_producto := 2;
                                SELECT cant_disp INTO jstock_actual FROM tab_kits 
                                WHERE id_kit = jid_kit_final AND ind_vivo = TRUE;
                            END IF;

                            IF jtipo_producto = 0 OR jstock_actual IS NULL THEN 
                                RAISE EXCEPTION 'Error Integridad: El producto % no tiene una referencia válida en inventario.', jnom_prod; 
                            END IF;

                            -- VALIDACIÓN DE STOCK
                            IF jcantidades[jcontador] > jstock_actual THEN
                                RAISE EXCEPTION 'Stock insuficiente para % (Disponible: %, Requerido: %)', jnom_prod, jstock_actual, jcantidades[jcontador];
                            END IF;

                        -- Cálculos
                            jval_bruto      := jprecio_venta * jcantidades[jcontador];
                            jval_descuento  := jval_bruto * (jreg_pmtros.val_pordesc / 100);
                            jval_neto       := (jval_bruto - jval_descuento);

                        -- INCREMENTAR ID DETALLE
                            jid_detalle_actual := jid_detalle_actual + 1;

                        -- INSERT DETALLE
                            INSERT INTO tab_detalle_facturas (
                                id_detalle_factura, id_factura, id_producto, cantidad, precio_unitario, val_descuento, val_bruto, val_neto
                            ) VALUES (
                                jid_detalle_actual, jid_factura, jproductos[jcontador], jcantidades[jcontador], jprecio_venta, jval_descuento, jval_bruto, jval_neto
                            );

                        -- INCREMENTAR ID KARDEX
                            jid_kardex_actual := jid_kardex_actual + 1;

                        -- ACTUALIZAR INVENTARIO Y KARDEX
                            IF jtipo_producto = 1 THEN
                                UPDATE tab_instrumentos SET cant_disp = cant_disp - jcantidades[jcontador] 
                                WHERE id_instrumento = jid_instr_final;
                                
                                INSERT INTO tab_kardex_productos (
                                    id_kardex_producto, id_instrumento, id_kit, tipo_movimiento, cantidad, fecha_movimiento, observaciones
                                ) VALUES (
                                    jid_kardex_actual, jid_instr_final, NULL, 2, jcantidades[jcontador], NOW(),
                                    '(VENTA[' || jid_factura || ']) Precio unitario: [' || to_char(jprecio_venta, 'FM$999,999,999') || '] Precio total: [' || to_char(jval_bruto, 'FM$999,999,999') || '] + ' || COALESCE(jobservaciones, '')
                                );
                            ELSE
                                UPDATE tab_kits SET cant_disp = cant_disp - jcantidades[jcontador] 
                                WHERE id_kit = jid_kit_final;
                                
                                INSERT INTO tab_kardex_productos (
                                    id_kardex_producto, id_instrumento, id_kit, tipo_movimiento, cantidad, fecha_movimiento, observaciones
                                ) VALUES (
                                    jid_kardex_actual, NULL, jid_kit_final, 2, jcantidades[jcontador], NOW(),
                                    '(VENTA[' || jid_factura || ']) Precio unitario: [' || to_char(jprecio_venta, 'FM$999,999,999') || '] Precio total: [' || to_char(jval_bruto, 'FM$999,999,999') || '] + ' || COALESCE(jobservaciones, '')
                                );
                            END IF;

                            jtotal_factura := jtotal_factura + jval_neto;
                        END LOOP;

                -- ACTUALIZAR TOTAL FACTURA
                    UPDATE tab_facturas SET val_tot_fact = jtotal_factura WHERE id_factura = jid_factura;
                    
                -- PUNTOS
                    IF jtotal_factura > 0 THEN
                        UPDATE tab_clientes SET val_puntos = val_puntos + FLOOR(jtotal_factura / 50000) 
                        WHERE id_cliente = jid_cliente_final;
                    END IF;

                    RAISE NOTICE 'Factura Exitosa. Total: %', jtotal_factura;
                    RETURN jid_factura;

    EXCEPTION
        WHEN OTHERS THEN 
            RAISE EXCEPTION 'Error en Venta: %', SQLERRM;
    END;
END;
$$ 
LANGUAGE plpgsql;
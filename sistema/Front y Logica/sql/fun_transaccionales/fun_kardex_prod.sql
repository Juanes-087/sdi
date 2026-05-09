/*
SELECT nom_instrumento, cant_disp FROM tab_instrumentos WHERE id_instrumento = 1; -- Conteo de stock

SELECT fun_kardex_productos(3, 1, 1, 50, 'Tipo Fake');
SELECT fun_kardex_productos(1, 99999, 1, 50, 'Instrumento Fake');
SELECT fun_kardex_productos(1, 1, 1, -10, 'Negativo');
SELECT fun_kardex_productos(1, 1, 4, 10000, 'Robo Masivo');
SELECT fun_kardex_productos(NULL, 1, 1, 10, 'Nulo');
SELECT fun_kardex_productos(1, 1, 1, 100, 'Producción Lote Z');
SELECT fun_kardex_productos(2, 1, 3, 5, 'Conteo Semanal');
SELECT fun_kardex_productos(1, 1, 2, 10, 'Venta Mostrador');

SELECT id_kardex_producto, id_instrumento, id_kit, cantidad, observaciones, user_insert 
FROM tab_kardex_productos 
ORDER BY id_kardex_producto DESC LIMIT 2;

*/

CREATE OR REPLACE FUNCTION fun_kardex_productos(jtipo_item         INTEGER, -- 1: Instrumento, 2: Kit
                                                                    jid_item            INTEGER, -- ID del Instrumento o Kit
                                                                    jtipo_movimiento  tab_kardex_productos.tipo_movimiento%TYPE, -- 1:Entrada Prod, 2:Venta, 3:Ajuste(+), 4:Baja(-), 5:Devolución
                                                                    jcantidad          tab_kardex_productos.cantidad%TYPE, 
                                                                    jobs                tab_kardex_productos.observaciones%TYPE,
                                                                    jreparable        BOOLEAN DEFAULT TRUE -- Solo aplica para Devolución (tipo 5)
                                                                    ) RETURNS BOOLEAN AS
$$
    DECLARE
        -- Variables
            jstock_actual       INTEGER;
            jnombre_item        VARCHAR;
            jid_nuevo_kardex  tab_kardex_productos.id_kardex_producto%TYPE;
        
        -- IDs auxiliares para el insert
            jid_instr_final     tab_instrumentos.id_instrumento%TYPE := NULL;
            jid_kit_final       tab_kits.id_kit%TYPE := NULL;

            BEGIN
                BEGIN -- Bloque de Protección
    
            -- VALIDACIÓN DE NULOS
                IF jtipo_item IS NULL OR jid_item IS NULL OR jtipo_movimiento IS NULL OR jcantidad IS NULL THEN
                    RAISE EXCEPTION 'Error de Datos: Parámetros nulos no permitidos.';
                END IF;

                IF jobs IS NULL OR TRIM(jobs) = '' THEN
                    RAISE EXCEPTION 'Error de Datos: La observación es obligatoria.';
                END IF;

            -- VALIDACIÓN DE LÓGICA (CANTIDAD Y TIPO)
                IF jcantidad <= 0 THEN
                    RAISE EXCEPTION 'Error de Negocio: Cantidad debe ser mayor a cero.';
                END IF;

                IF jcantidad > 5000 THEN 
                    RAISE EXCEPTION 'Alerta de Seguridad: Cantidad % excesiva para producto terminado.', jcantidad;
                END IF;

                IF jtipo_item NOT IN (1, 2) THEN
                    RAISE EXCEPTION 'Error de Datos: Tipo de Item % inválido (1=Instr, 2=Kit).', jtipo_item;
                END IF;

                IF jtipo_movimiento NOT BETWEEN 1 AND 5 THEN
                    RAISE EXCEPTION 'Error de Datos: Tipo de Movimiento % inválido.', jtipo_movimiento;
                END IF;

            -- VALIDACIÓN DE EXISTENCIA Y OBTENCIÓN DE STOCK
                IF jtipo_item = 1 THEN
                    -- INSTRUMENTO
                        SELECT nom_instrumento, cant_disp INTO jnombre_item, jstock_actual
                        FROM tab_instrumentos WHERE id_instrumento = jid_item AND ind_vivo = TRUE;
                        
                        IF NOT FOUND THEN
                            RAISE EXCEPTION 'Error de Integridad: El Instrumento ID % no existe o está inactivo.', jid_item;
                        END IF;
                        jid_instr_final := jid_item; -- Preparamos ID para el Insert
                    
                ELSE
                    -- KIT
                        SELECT nom_kit, cant_disp INTO jnombre_item, jstock_actual
                        FROM tab_kits WHERE id_kit = jid_item AND ind_vivo = TRUE;
                        
                        IF NOT FOUND THEN
                            RAISE EXCEPTION 'Error de Integridad: El Kit ID % no existe o está inactivo.', jid_item;
                        END IF;
                        jid_kit_final := jid_item; -- Preparamos ID para el Insert
                END IF;

            -- ACTUALIZACIÓN DE STOCK (SEGÚN MOVIMIENTO)
                CASE jtipo_movimiento
                    -- ENTRADAS (1: Producción, 3: Ajuste +)
                        WHEN 1, 3 THEN
                            IF jtipo_item = 1 THEN
                                UPDATE tab_instrumentos SET cant_disp = cant_disp + jcantidad 
                                WHERE id_instrumento = jid_item;
                            ELSE
                                UPDATE tab_kits SET cant_disp = cant_disp + jcantidad 
                                WHERE id_kit = jid_item;
                            END IF;

                    -- SALIDAS (2: Venta/Salida, 4: Baja/Daño)
                        WHEN 2, 4 THEN
                            -- Validar Stock suficiente
                            IF jcantidad > jstock_actual THEN
                                RAISE EXCEPTION 'Error de Stock: Saldo insuficiente en % (Stock: %, Pide: %).', jnombre_item, jstock_actual, jcantidad;
                            END IF;

                            IF jtipo_item = 1 THEN
                                UPDATE tab_instrumentos SET cant_disp = cant_disp - jcantidad 
                                WHERE id_instrumento = jid_item;
                            ELSE
                                UPDATE tab_kits SET cant_disp = cant_disp - jcantidad 
                                WHERE id_kit = jid_item;
                            END IF;

                    -- DEVOLUCIÓN (5)
                        WHEN 5 THEN
                            IF jreparable = TRUE THEN
                                IF jtipo_item = 1 THEN
                                    UPDATE tab_instrumentos SET cant_disp = cant_disp + jcantidad 
                                    WHERE id_instrumento = jid_item;
                                ELSE
                                    UPDATE tab_kits SET cant_disp = cant_disp + jcantidad 
                                    WHERE id_kit = jid_item;
                                END IF;
                            END IF;
                            -- Si no es reparable, solo queda el registro en el Kardex (abajo se inserta)
                END CASE;

            -- GENERAR ID KARDEX
                SELECT COALESCE(MAX(id_kardex_producto), 0) + 1 INTO jid_nuevo_kardex 
                FROM tab_kardex_productos;

            -- INSERTAR EN KARDEX
                INSERT INTO tab_kardex_productos (id_kardex_producto, 
                                                                id_instrumento, 
                                                                id_kit, 
                                                                tipo_movimiento, 
                                                                cantidad, 
                                                                fecha_movimiento, 
                                                                observaciones) VALUES (jid_nuevo_kardex, 
                                                                                                jid_instr_final, 
                                                                                                jid_kit_final, 
                                                                                                jtipo_movimiento, 
                                                                                                jcantidad, 
                                                                                                NOW(), 
                                                                                                jobs);

                RAISE NOTICE 'Kardex Productos Actualizado. ID: % | Item: % | Mov: %', jid_nuevo_kardex, jnombre_item, 
                            CASE 
                                WHEN jtipo_movimiento IN (1,3) THEN 'ENTRADA' 
                                WHEN jtipo_movimiento = 5 THEN (CASE WHEN jreparable THEN 'DEVOLUCIÓN (STOCK+)' ELSE 'DEVOLUCIÓN (DEFECTUOSO)' END)
                                ELSE 'SALIDA' 
                            END;
                RETURN TRUE;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE EXCEPTION 'Error en movimiento de Kardex: %', SQLERRM;
    END;
END;
$$ 
LANGUAGE plpgsql;

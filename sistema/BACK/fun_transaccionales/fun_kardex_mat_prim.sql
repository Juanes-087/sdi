/*
    -----------------------------------------------------------------------------
    PRUEBAS DE MOVIMIENTO (INVENTARIO MATERIA PRIMA)
    -----------------------------------------------------------------------------
    -- 1. Compra de Varilla (Exitosa):
    SELECT fun_kardex_materia_prima(1, 8, 1, 100, 100.0, 4, 'Compra Lote 2024-A');

    -- 2. Error de Unidad (Inconsistencia):
    SELECT fun_kardex_materia_prima(1, 8, 1, 50, 50.0, 1, 'Error: Metros vs Gramos');

    -- 3. Salida a Producción (Consumo):
    SELECT fun_kardex_materia_prima(1, 8, 2, 10, 100.0, 4, 'Salida a línea de producción');

    -- 4. Stock Insuficiente:
    SELECT fun_kardex_materia_prima(1, 8, 2, 5000, 100.0, 4, 'Error: Sobregiro de stock');
    -----------------------------------------------------------------------------
*/

drop function fun_kardex_materia_prima;

CREATE OR REPLACE FUNCTION fun_kardex_materia_prima(jid_materia        tab_materias_primas.id_mat_prima%TYPE,
                                                    jid_proveedor      tab_proveedores.id_prov%TYPE,
                                                    jtipo_movimiento   tab_kardex_mat_prima.tipo_movimiento%TYPE,
                                                    jcantidad          tab_kardex_mat_prima.cantidad%TYPE,
                                                    jvalor_medida      tab_mat_primas_prov.valor_medida%TYPE,
                                                    jid_unidad_medida  tab_mat_primas_prov.id_unidad_medida%TYPE,
                                                    jobs               tab_kardex_mat_prima.observaciones%TYPE
                                                    ) RETURNS BOOLEAN AS
$$
        DECLARE
        -- Variables de Datos
            jstock_actual    tab_mat_primas_prov.cant_mat_prima%TYPE;
            jvalor_stock     tab_mat_primas_prov.valor_medida%TYPE; 
            jid_unidad_stock tab_mat_primas_prov.id_unidad_medida%TYPE;
            jnom_mp          tab_materias_primas.nom_materia_prima%TYPE;
            jnom_prov        tab_proveedores.nom_prov%TYPE;
            jid_nuevo_kardex tab_kardex_mat_prima.id_kardex_mat_prima%TYPE;
            jid_mov_bodega   tab_bodega.id_movimiento%TYPE;
            jid_producc_nuevo tab_producc.id_producc%TYPE;
            jobs_final       tab_kardex_mat_prima.observaciones%TYPE;

        BEGIN
            BEGIN -- Inicio del Bloque de Protección
    
            -- 1. VALIDACIÓN DE ENTRADA (NULOS)
                IF jid_materia IS NULL OR jid_proveedor IS NULL OR jtipo_movimiento IS NULL OR jcantidad IS NULL 
                   OR jvalor_medida IS NULL OR jid_unidad_medida IS NULL THEN
                    RAISE NOTICE 'Error de Datos: Los parámetros obligatorios no pueden ser nulos.';
                    RAISE EXCEPTION USING ERRCODE = 'P0002';
                END IF;

                IF jobs IS NULL OR TRIM(jobs) = '' THEN
                    RAISE NOTICE 'Error de Datos: La observación es obligatoria.';
                    RAISE EXCEPTION USING ERRCODE = 'P0002';
                END IF;

            -- 2. VALIDACIÓN LÓGICA (CANTIDADES Y TIPOS)
                IF jcantidad <= 0 THEN
                    RAISE NOTICE 'Error de Negocio: La cantidad debe ser mayor a cero.';
                    RAISE EXCEPTION USING ERRCODE = 'P0002';
                END IF;

                IF jcantidad > 10000 THEN 
                    RAISE NOTICE 'Alerta de Seguridad: Cantidad excesiva (% unidades). Verifique.', jcantidad;
                    RAISE EXCEPTION USING ERRCODE = 'P0002';
                END IF;

                IF jtipo_movimiento NOT BETWEEN 1 AND 4 THEN
                    RAISE NOTICE 'Error de Datos: Tipo de movimiento % no válido (1-4).', jtipo_movimiento;
                    RAISE EXCEPTION USING ERRCODE = 'P0002';
                END IF;

            -- 3. VALIDACIÓN DE EXISTENCIA
            -- Materia Prima
                SELECT nom_materia_prima INTO jnom_mp FROM tab_materias_primas WHERE id_mat_prima = jid_materia AND ind_vivo = TRUE;
                IF NOT FOUND THEN
                    RAISE NOTICE 'Error de Integridad: La materia prima ID % no existe.', jid_materia;
                    RAISE EXCEPTION USING ERRCODE = 'P0001';
                END IF;

            -- Proveedor
                SELECT nom_prov INTO jnom_prov FROM tab_proveedores WHERE id_prov = jid_proveedor AND ind_vivo = TRUE;
                IF NOT FOUND THEN
                    RAISE NOTICE 'Error de Integridad: El proveedor ID % no existe.', jid_proveedor;
                    RAISE EXCEPTION USING ERRCODE = 'P0001';
                END IF;

            -- 4. VALIDACIÓN DE RELACIÓN Y CONSISTENCIA DE UNIDADES
                SELECT cant_mat_prima, valor_medida, id_unidad_medida 
                INTO jstock_actual, jvalor_stock, jid_unidad_stock
                FROM tab_mat_primas_prov 
                WHERE id_mat_prima = jid_materia AND id_prov = jid_proveedor AND ind_vivo = TRUE;

                IF NOT FOUND THEN
                    -- Auto-Onboarding (Crear relación si no existe)
                    INSERT INTO tab_mat_primas_prov (id_mat_prima, id_prov, cant_mat_prima, valor_medida, id_unidad_medida, lote, tipo_mat_prima, ind_vivo)
                    VALUES (jid_materia, jid_proveedor, 0, jvalor_medida, jid_unidad_medida, 0, 'Generico', TRUE);
                    
                    jstock_actual := 0;
                    jvalor_stock := jvalor_medida;
                    jid_unidad_stock := jid_unidad_medida;
                    RAISE NOTICE 'Info: Se creó relación automática entre Prov % y Materia %', jnom_prov, jnom_mp;
                ELSE
                    -- CONTROL DE INTEGRIDAD NUMÉRICA (Crucial para stock)
                    IF jid_unidad_medida <> jid_unidad_stock THEN
                        RAISE NOTICE 'Error de Unidades: El movimiento usa unidad % pero el stock está en %. Inconsistencia bloqueada.', jid_unidad_medida, jid_unidad_stock;
                        RAISE EXCEPTION USING ERRCODE = 'P0002';
                    END IF;
                END IF;

            -- 5. LÓGICA DE ACTUALIZACIÓN DE STOCK
                CASE jtipo_movimiento
                    -- COMPRA (1), AJUSTE POSITIVO (3)
                    WHEN 1, 3 THEN
                        UPDATE tab_mat_primas_prov 
                        SET cant_mat_prima = cant_mat_prima + jcantidad
                        WHERE id_mat_prima = jid_materia AND id_prov = jid_proveedor;

                        -- AUTOMATIZACIÓN BODEGA: Si es Compra o Ajuste Positivo, registrar ingreso físico
                        IF jtipo_movimiento IN (1, 3) THEN
                            SELECT COALESCE(MAX(id_movimiento), 0) + 1 INTO jid_mov_bodega FROM tab_bodega;
                            INSERT INTO tab_bodega (id_movimiento, id_prov, id_mat_prima, fec_ingreso, fec_salida)
                            VALUES (jid_mov_bodega, jid_proveedor, jid_materia, NOW(), NULL);
                            RAISE NOTICE 'Bodega: Registrado ingreso automático ID % (Tipo %)', jid_mov_bodega, jtipo_movimiento;
                        END IF;

                    -- PRODUCCIÓN (2), DAÑO/BAJA (4)
                    WHEN 2, 4 THEN
                        IF jcantidad > jstock_actual THEN
                            RAISE NOTICE 'Error de Stock: Saldo insuficiente para % (Stock: %, Requerido: %).', jnom_mp, jstock_actual, jcantidad;
                            RAISE EXCEPTION USING ERRCODE = 'P0002';
                        END IF;

                        UPDATE tab_mat_primas_prov 
                        SET cant_mat_prima = cant_mat_prima - jcantidad
                        WHERE id_mat_prima = jid_materia AND id_prov = jid_proveedor;

                        -- AUTOMATIZACIÓN PRODUCCIÓN: Si es Salida a Producción, registrar en tab_producc
                        IF jtipo_movimiento = 2 THEN
                            -- Buscamos el último movimiento de bodega para vincularlo
                            SELECT MAX(id_movimiento) INTO jid_mov_bodega 
                            FROM tab_bodega 
                            WHERE id_mat_prima = jid_materia AND id_prov = jid_proveedor AND ind_vivo = TRUE;

                            IF jid_mov_bodega IS NOT NULL THEN
                                SELECT COALESCE(MAX(id_producc), 0) + 1 INTO jid_producc_nuevo FROM tab_producc;
                                INSERT INTO tab_producc (id_producc, id_movimiento, fec_ingreso)
                                VALUES (jid_producc_nuevo, jid_mov_bodega, NOW());
                                RAISE NOTICE 'Producción: Registrada salida automática ID % (Vinculada a Bodega %)', jid_producc_nuevo, jid_mov_bodega;
                            ELSE
                                RAISE NOTICE 'Aviso: No se encontró un registro previo en tab_bodega para vincular esta producción.';
                            END IF;
                        END IF;

                        -- CIERRE DE BODEGA: Si el stock llega a 0 por Producción o Daño, marcar salida en bodega
                        IF (jstock_actual - jcantidad) = 0 THEN
                             UPDATE tab_bodega 
                             SET fec_salida = NOW()
                             WHERE id_movimiento = (
                                 SELECT MAX(id_movimiento) 
                                 FROM tab_bodega 
                                 WHERE id_mat_prima = jid_materia AND id_prov = jid_proveedor AND fec_salida IS NULL AND ind_vivo = TRUE
                             );
                             RAISE NOTICE 'Bodega: Todo el stock se ha agotado. Se marcó salida en bodega para el último lote.';
                        END IF;
                END CASE;

            -- 6. REGISTRO EN KARDEX
                SELECT COALESCE(MAX(id_kardex_mat_prima), 0) + 1 INTO jid_nuevo_kardex FROM tab_kardex_mat_prima;
                
                jobs_final := 'Proveedor: ' || jnom_prov || ' | ' || jobs;

                INSERT INTO tab_kardex_mat_prima (
                    id_kardex_mat_prima, id_materia_prima, id_unidad_medida, valor_medida, 
                    tipo_movimiento, cantidad, fecha_movimiento, observaciones
                ) VALUES (
                    jid_nuevo_kardex, jid_materia, jid_unidad_medida, jvalor_medida, 
                    jtipo_movimiento, jcantidad, NOW(), jobs_final
                );

                RAISE NOTICE 'Movimiento Registrado: Kardex #% (Stock Final Aprox: %)', jid_nuevo_kardex, 
                        CASE WHEN jtipo_movimiento IN (1,3) THEN jstock_actual + jcantidad ELSE jstock_actual - jcantidad END;
                
                RETURN TRUE;

    EXCEPTION
        WHEN SQLSTATE 'P0001' OR SQLSTATE 'P0002' THEN
            RAISE NOTICE 'Operación cancelada por regla de negocio/integridad.';
            RETURN FALSE;
        WHEN OTHERS THEN
            RAISE NOTICE 'Error Crítico en Sistema Kardex: %', SQLERRM;
            RETURN FALSE;
    END;
END;
$$ 
LANGUAGE plpgsql;
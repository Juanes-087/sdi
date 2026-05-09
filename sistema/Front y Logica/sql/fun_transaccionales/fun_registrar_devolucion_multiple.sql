-----------------------------------------------------------------------------
-- FUNCIÓN: fun_registrar_devolucion_multiple
-- PROPÓSITO: Procesa el retorno de varios productos de una misma factura.
-- DISPARADOR: Se ejecuta al confirmar el modal de "Devolución" en Movimientos.
-- LLAMADO DESDE: querys.php -> registrarDevolucionMultiple()
-- IMPACTO: 
--   1. Crea cabecera en tab_dev.
--   2. Registra entradas en Kardex (fun_kardex_productos).
--   3. Opcionalmente marca items como Dañados (jreparables).
-----------------------------------------------------------------------------

drop function if exists fun_registrar_devolucion_multiple;

CREATE OR REPLACE FUNCTION fun_registrar_devolucion_multiple(
    jid_factura INTEGER,
    jproductos INTEGER[],
    jcantidades INTEGER[],
    jreparables BOOLEAN[],
    jobservaciones VARCHAR DEFAULT 'N/A'
) RETURNS BOOLEAN AS $$
DECLARE
    jcontador   INTEGER;
    jtipo_item  INTEGER; -- 1: Instrumento, 2: Kit
    jid_item_real INTEGER;
BEGIN
    -- 1. Validaciones básicas de entrada
    IF jid_factura IS NULL THEN
        RAISE EXCEPTION 'Error: ID de factura es obligatorio.';
    END IF;

    IF jproductos IS NULL OR array_length(jproductos, 1) = 0 THEN
        RAISE EXCEPTION 'Error: Debe seleccionar al menos un producto para devolver.';
    END IF;

    IF array_length(jproductos, 1) != array_length(jcantidades, 1) OR 
       array_length(jproductos, 1) != array_length(jreparables, 1) THEN
        RAISE EXCEPTION 'Error: Los arreglos de productos, cantidades y estados no coinciden en longitud.';
    END IF;

    -- 2. Registrar cabecera en tab_dev si no existe (Control Visual Interno)
    IF NOT EXISTS (SELECT 1 FROM tab_dev WHERE id_factura = jid_factura) THEN
        INSERT INTO tab_dev (id_factura, ind_observaciones)
        VALUES (jid_factura, TRIM(COALESCE(jobservaciones, 'Devolución parcial/total de items.')));
    ELSE
        -- Si ya existe, actualizar observaciones para añadir el nuevo motivo
        UPDATE tab_dev 
        SET ind_observaciones = ind_observaciones || ' | ' || TRIM(COALESCE(jobservaciones, 'Nueva entrada de items.'))
        WHERE id_factura = jid_factura;
    END IF;

    -- 3. Bucle para procesar cada producto devuelto
    FOR jcontador IN 1..array_length(jproductos, 1) LOOP
        -- Obtener el origen del producto en el catálogo (Instrumento o Kit)
        SELECT 
            CASE WHEN id_instrumento IS NOT NULL THEN 1 ELSE 2 END,
            COALESCE(id_instrumento, id_kit)
        INTO jtipo_item, jid_item_real
        FROM tab_productos
        WHERE id_producto = jproductos[jcontador];

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Error: El producto ID % no existe en el catálogo.', jproductos[jcontador];
        END IF;

        -- 4. Registrar en la tabla de devoluciones pendientes (tab_devol_reparable)
        -- Queda con id_estado_devol en 1 (Pendiente) para ser gestionado posteriormente.
        INSERT INTO tab_devol_reparable (id_devol_reparable, id_factura, id_producto, cantidad, id_estado_devol)
        VALUES (
            (SELECT COALESCE(MAX(id_devol_reparable), 0) + 1 FROM tab_devol_reparable),
            jid_factura, 
            jproductos[jcontador], 
            jcantidades[jcontador], 
            1
        );
    END LOOP;

    RETURN TRUE;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Falló la operación de devolución: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

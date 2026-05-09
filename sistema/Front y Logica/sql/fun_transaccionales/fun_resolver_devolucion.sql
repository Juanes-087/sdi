-----------------------------------------------------------------------------
-- FUNCIÓN: fun_resolver_devolucion
-- PROPÓSITO: Resuelve una devolución pendiente (tab_devol_reparable), actualizando estado y kardex.
-- DISPARADOR: Se ejecuta al confirmar "Reparado" o "Desechado" en Gestionar Productos.
-----------------------------------------------------------------------------

drop function if exists fun_resolver_devolucion;

CREATE OR REPLACE FUNCTION fun_resolver_devolucion(
    jid_devol_reparable INTEGER,
    jid_nuevo_estado INTEGER -- 2: Reparado, 3: Desechado
) RETURNS BOOLEAN AS $$
DECLARE
    jproducto INTEGER;
    jfactura INTEGER;
    jcantidad INTEGER;
    jtipo_item INTEGER;
    jid_item_real INTEGER;
    jreparable_bol BOOLEAN;
BEGIN
    -- Validar si existe la devolución pendiente (estado 1)
    SELECT id_producto, id_factura, cantidad INTO jproducto, jfactura, jcantidad
    FROM tab_devol_reparable
    WHERE id_devol_reparable = jid_devol_reparable AND id_estado_devol = 1;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Error: La devolución pendiente no existe o ya fue resuelta.';
    END IF;

    -- Validar estado destino
    IF jid_nuevo_estado NOT IN (2, 3) THEN
        RAISE EXCEPTION 'Error: Estado de resolución no válido (debe ser 2 o 3).';
    END IF;

    -- Convertir ID de estado a booleano para fun_kardex_productos
    jreparable_bol := (jid_nuevo_estado = 2);

    -- Obtener el tipo de item y el id real del producto
    SELECT 
        CASE WHEN id_instrumento IS NOT NULL THEN 1 ELSE 2 END,
        COALESCE(id_instrumento, id_kit)
    INTO jtipo_item, jid_item_real
    FROM tab_productos
    WHERE id_producto = jproducto;

    -- Actualizar el estado en tab_devol_reparable
    UPDATE tab_devol_reparable
    SET id_estado_devol = jid_nuevo_estado
    WHERE id_devol_reparable = jid_devol_reparable;

    -- Registrar en kardex (y actualizar stock si es Reparado)
    PERFORM fun_kardex_productos(
        jtipo_item,
        jid_item_real,
        5, -- Tipo Movimiento: Devolución
        jcantidad,
        'Dev. Factura #' || jfactura || ' resuelta: ' || CASE WHEN jid_nuevo_estado = 2 THEN 'Reparado (Suma a stock)' ELSE 'Desechado (Baja)' END,
        jreparable_bol
    );

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Falló la operación de resolver devolución: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

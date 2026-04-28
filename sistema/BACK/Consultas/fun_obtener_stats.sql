-----------------------------------------------------------------------------
-- FUNCIÓN: fun_obtener_stats
-- PROPÓSITO: Recopila métricas clave para el Dashboard y Sidebar.
-- DISPARADOR: Se ejecuta al cargar el Dashboard o refrescar el menú lateral.
-- LLAMADO DESDE: querys.php -> getStats()
-----------------------------------------------------------------------------
drop function if exists fun_obtener_stats;

CREATE OR REPLACE FUNCTION fun_obtener_stats(
    OUT total_usuarios BIGINT, 
    OUT usuarios_mes BIGINT,
    OUT total_admins BIGINT,
    OUT total_clientes BIGINT,
    OUT total_productos BIGINT,
    OUT total_instrumentos BIGINT,
    OUT total_kits BIGINT,
    OUT mayor_venta_nombre VARCHAR,
    OUT mayor_venta_total BIGINT,
    OUT menor_stock_nombre VARCHAR,
    OUT menor_stock_cant INT,
    OUT total_ventas DECIMAL(15,2),
    OUT ventas_diarias DECIMAL(15,2),
    OUT total_proveedores BIGINT,
    OUT alerta_stock_critico INT,
    OUT val_pordesc DECIMAL(5,2),
    OUT ind_tema BOOLEAN,
    OUT ind_idioma VARCHAR(5)
) 
AS $$
DECLARE
    total_ventas_kits BIGINT := 0;
    total_ventas_general BIGINT := 0;
BEGIN
    -- 1. Total usuarios (activos)
    SELECT COUNT(id_user) INTO fun_obtener_stats.total_usuarios 
    FROM tab_users WHERE ind_vivo = true;

    -- 2. Usuarios nuevos este mes
    SELECT COUNT(id_user) INTO fun_obtener_stats.usuarios_mes 
    FROM tab_users 
    WHERE ind_vivo = true 
    AND EXTRACT(MONTH FROM fec_insert) = EXTRACT(MONTH FROM CURRENT_DATE)
    AND EXTRACT(YEAR FROM fec_insert) = EXTRACT(YEAR FROM CURRENT_DATE);

    -- 3. Empleados y Clientes
    SELECT COUNT(id_empleado) INTO fun_obtener_stats.total_admins 
    FROM tab_empleados 
    WHERE ind_vivo = true;

    SELECT COUNT(id_cliente) INTO fun_obtener_stats.total_clientes FROM tab_clientes WHERE ind_vivo = true; 
    -- 4. Total Productos (Del catálogo de venta: tab_productos)
    SELECT COUNT(id_producto) INTO fun_obtener_stats.total_productos FROM tab_productos WHERE ind_vivo = true;
    
    -- Totales de inventario físico (informativo)
    SELECT COUNT(id_instrumento) INTO fun_obtener_stats.total_instrumentos FROM tab_instrumentos WHERE ind_vivo = true;
    SELECT COUNT(id_kit) INTO fun_obtener_stats.total_kits FROM tab_kits WHERE ind_vivo = true;

    -- 5. Mayor Venta
    SELECT p.nombre_producto, SUM(df.cantidad)
    INTO fun_obtener_stats.mayor_venta_nombre, fun_obtener_stats.mayor_venta_total
    FROM tab_detalle_facturas df 
    JOIN tab_productos p ON p.id_producto = df.id_producto 
    WHERE df.ind_vivo = true
    GROUP BY p.nombre_producto 
    ORDER BY SUM(df.cantidad) DESC 
    LIMIT 1;

    IF fun_obtener_stats.mayor_venta_nombre IS NULL THEN
        fun_obtener_stats.mayor_venta_nombre := 'Sin datos';
        fun_obtener_stats.mayor_venta_total := 0;
    END IF;

    -- 6. Menor Stock
    SELECT nombre, cantidad INTO fun_obtener_stats.menor_stock_nombre, fun_obtener_stats.menor_stock_cant
    FROM (
        SELECT nom_kit as nombre, cant_disp as cantidad FROM tab_kits WHERE ind_vivo = true
        UNION ALL
        SELECT nom_instrumento as nombre, cant_disp as cantidad FROM tab_instrumentos WHERE ind_vivo = true
    ) subquery
    ORDER BY cantidad ASC
    LIMIT 1;

    IF fun_obtener_stats.menor_stock_nombre IS NULL THEN
        fun_obtener_stats.menor_stock_nombre := 'Sin datos';
        fun_obtener_stats.menor_stock_cant := 0;
    END IF;

    -- 7. Ventas Totales (Facturas + Kardex de Ventas)
    -- Sumamos el valor de las facturas pagas
    SELECT SUM(val_tot_fact) INTO fun_obtener_stats.total_ventas
    FROM tab_facturas 
    WHERE id_estado_fact = 1 AND ind_vivo = true;

    -- BLOQUE DE PROTECCIÓN: Si no hay facturas, convertimos el NULL en 0
    IF fun_obtener_stats.total_ventas IS NULL THEN
        fun_obtener_stats.total_ventas := 0;
    END IF;

    -- Sumar ventas manuales registradas en kardex
    SELECT SUM(k.cantidad * p.precio_producto) INTO total_ventas_general
    FROM tab_kardex_productos k
    JOIN tab_productos p ON (k.id_instrumento = p.id_instrumento OR k.id_kit = p.id_kit)
    WHERE k.tipo_movimiento = 2 AND k.ind_vivo = true AND p.ind_vivo = true;

    IF total_ventas_general IS NOT NULL THEN
        fun_obtener_stats.total_ventas := fun_obtener_stats.total_ventas + total_ventas_general;
    END IF;

    -- 8. Ventas Diarias (Facturas + Kardex de Ventas de hoy)
    SELECT SUM(val_tot_fact) INTO fun_obtener_stats.ventas_diarias
    FROM tab_facturas 
    WHERE id_estado_fact = 1 
    AND DATE(fecha_venta) = CURRENT_DATE 
    AND ind_vivo = true;

    IF fun_obtener_stats.ventas_diarias IS NULL THEN
        fun_obtener_stats.ventas_diarias := 0;
    END IF;

    -- Sumar ventas manuales diarias registradas en kardex
    SELECT SUM(k.cantidad * p.precio_producto) INTO total_ventas_general
    FROM tab_kardex_productos k
    JOIN tab_productos p ON (k.id_instrumento = p.id_instrumento OR k.id_kit = p.id_kit)
    WHERE k.tipo_movimiento = 2 
    AND DATE(k.fecha_movimiento) = CURRENT_DATE
    AND k.ind_vivo = true AND p.ind_vivo = true;

    IF total_ventas_general IS NOT NULL THEN
        fun_obtener_stats.ventas_diarias := fun_obtener_stats.ventas_diarias + total_ventas_general;
    END IF;

    -- 9. Total Proveedores
    SELECT COUNT(id_prov) INTO fun_obtener_stats.total_proveedores 
    FROM tab_proveedores 
    WHERE ind_vivo = true;


    -- 12. Alerta de Stock Crítico (Suma de Instrumentos, Kits y Materias Primas bajo el mínimo)
    SELECT COUNT(1) INTO fun_obtener_stats.alerta_stock_critico
    FROM (
        SELECT id_instrumento FROM tab_instrumentos WHERE cant_disp <= stock_min AND stock_min > 0 AND ind_vivo = true
        UNION ALL
        SELECT id_kit FROM tab_kits WHERE cant_disp <= stock_min AND stock_min > 0 AND ind_vivo = true
        UNION ALL
        SELECT mpp.id_mat_prima FROM tab_mat_primas_prov mpp 
        JOIN tab_materias_primas mp ON mpp.id_mat_prima = mp.id_mat_prima 
        WHERE mpp.cant_mat_prima <= mp.stock_min 
        AND mp.stock_min > 0 AND mpp.ind_vivo = true AND mp.ind_vivo = true
    ) AS sub_alertas;
    
    -- 13. Porcentaje de descuento global, Tema e Idioma (Parámetros)
    SELECT tp.val_pordesc, tp.ind_tema, tp.ind_idioma 
    INTO fun_obtener_stats.val_pordesc, fun_obtener_stats.ind_tema, fun_obtener_stats.ind_idioma 
    FROM tab_parametros tp WHERE tp.id_empresa = 1;

END;
$$ LANGUAGE plpgsql;

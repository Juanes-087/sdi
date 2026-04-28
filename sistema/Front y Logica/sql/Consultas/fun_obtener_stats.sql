-- Función para obtener estadísticas del dashboard
-- Evita SELECT COUNT(*) en PHP
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
    OUT lead_time_promedio VARCHAR,
    OUT indice_conversion DECIMAL(5,2),
    OUT alerta_stock_critico INT
) 
AS $$
DECLARE
    total_ventas_kits BIGINT := 0;
    total_ventas_general BIGINT := 0;
BEGIN
    -- 1. Total usuarios (activos)
    SELECT COUNT(id_user) INTO total_usuarios 
    FROM tab_users WHERE COALESCE(ind_vivo, true) = true;

    -- 2. Usuarios nuevos este mes
    SELECT COUNT(id_user) INTO usuarios_mes 
    FROM tab_users 
    WHERE COALESCE(ind_vivo, true) = true 
    AND EXTRACT(MONTH FROM fec_insert) = EXTRACT(MONTH FROM CURRENT_DATE)
    AND EXTRACT(YEAR FROM fec_insert) = EXTRACT(YEAR FROM CURRENT_DATE);

    -- 3. Empleados y Clientes
    SELECT COUNT(id_empleado) INTO total_admins 
    FROM tab_empleados 
    WHERE COALESCE(ind_vivo, true) = true;

    SELECT COUNT(id_cliente) INTO total_clientes FROM tab_clientes WHERE COALESCE(ind_vivo, true) = true; 
    -- 4. Total Productos (Del catálogo de venta: tab_productos)
    SELECT COUNT(id_producto) INTO total_productos FROM tab_productos WHERE COALESCE(ind_vivo, true) = true;
    
    -- Totales de inventario físico (informativo)
    SELECT COUNT(id_instrumento) INTO total_instrumentos FROM tab_instrumentos WHERE COALESCE(ind_vivo, true) = true;
    SELECT COUNT(id_kit) INTO total_kits FROM tab_kits WHERE COALESCE(ind_vivo, true) = true;

    -- 5. Mayor Venta
    SELECT p.nombre_producto, SUM(df.cantidad)
    INTO mayor_venta_nombre, mayor_venta_total
    FROM tab_detalle_facturas df 
    JOIN tab_productos p ON p.id_producto = df.id_producto 
    WHERE COALESCE(df.ind_vivo, true) = true
    GROUP BY p.nombre_producto 
    ORDER BY SUM(df.cantidad) DESC 
    LIMIT 1;

    IF mayor_venta_nombre IS NULL THEN
        mayor_venta_nombre := 'Sin datos';
        mayor_venta_total := 0;
    END IF;

    -- 6. Menor Stock
    SELECT nombre, cantidad INTO menor_stock_nombre, menor_stock_cant
    FROM (
        SELECT nom_kit as nombre, cant_disp as cantidad FROM tab_kits WHERE COALESCE(ind_vivo, true) = true
        UNION ALL
        SELECT nom_instrumento as nombre, cant_disp as cantidad FROM tab_instrumentos WHERE COALESCE(ind_vivo, true) = true
    ) subquery
    ORDER BY cantidad ASC
    LIMIT 1;

    IF menor_stock_nombre IS NULL THEN
        menor_stock_nombre := 'Sin datos';
        menor_stock_cant := 0;
    END IF;

    -- 7. Ventas Totales (Facturas + Kardex de Ventas)
    SELECT COALESCE(SUM(val_tot_fact), 0) INTO total_ventas
    FROM tab_facturas 
    WHERE id_estado_fact = 1 AND COALESCE(ind_vivo, true) = true;

    -- Sumar ventas manuales registradas en kardex
    SELECT total_ventas + COALESCE(SUM(k.cantidad * p.precio_producto), 0) INTO total_ventas
    FROM tab_kardex_productos k
    JOIN tab_productos p ON (k.id_instrumento = p.id_instrumento OR k.id_kit = p.id_kit)
    WHERE k.tipo_movimiento = 2 AND COALESCE(k.ind_vivo, true) = true AND COALESCE(p.ind_vivo, true) = true;

    -- 8. Ventas Diarias (Facturas + Kardex de Ventas de hoy)
    SELECT COALESCE(SUM(val_tot_fact), 0) INTO ventas_diarias
    FROM tab_facturas 
    WHERE id_estado_fact = 1 
    AND DATE(fecha_venta) = CURRENT_DATE 
    AND COALESCE(ind_vivo, true) = true;

    -- Sumar ventas manuales diarias registradas en kardex
    SELECT ventas_diarias + COALESCE(SUM(k.cantidad * p.precio_producto), 0) INTO ventas_diarias
    FROM tab_kardex_productos k
    JOIN tab_productos p ON (k.id_instrumento = p.id_instrumento OR k.id_kit = p.id_kit)
    WHERE k.tipo_movimiento = 2 
    AND DATE(k.fecha_movimiento) = CURRENT_DATE
    AND COALESCE(k.ind_vivo, true) = true AND COALESCE(p.ind_vivo, true) = true;

    -- 9. Total Proveedores
    SELECT COUNT(id_prov) INTO total_proveedores 
    FROM tab_proveedores 
    WHERE COALESCE(ind_vivo, true) = true;

    -- 10. Lead Time Promedio (Días y Horas) de Bodega a Producción
    SELECT COALESCE(
        TO_CHAR(
            AVG(EXTRACT(EPOCH FROM (p.fec_ingreso - b.fec_ingreso))) * interval '1 second',
            'DD "d" HH24 "h"'
        ), '0 d 0 h'
    ) INTO lead_time_promedio
    FROM tab_producc p
    JOIN tab_bodega b ON p.id_movimiento = b.id_movimiento
    WHERE p.fec_ingreso IS NOT NULL AND b.fec_ingreso IS NOT NULL;
    
    -- Si el resultado empieza por '00', limpiar un poco
    IF lead_time_promedio LIKE '00 d%' THEN
        lead_time_promedio := SUBSTRING(lead_time_promedio FROM 6);
    END IF;

    -- 11. Índice de Conversión de Kits
    SELECT COALESCE(SUM(df.cantidad), 0) INTO total_ventas_general
    FROM tab_detalle_facturas df
    JOIN tab_productos p ON df.id_producto = p.id_producto
    WHERE COALESCE(df.ind_vivo, true) = true AND COALESCE(p.ind_vivo, true) = true;

    IF total_ventas_general > 0 THEN
        SELECT COALESCE(SUM(df.cantidad), 0) INTO total_ventas_kits
        FROM tab_detalle_facturas df
        JOIN tab_productos p ON df.id_producto = p.id_producto
        WHERE p.id_kit IS NOT NULL AND COALESCE(df.ind_vivo, true) = true AND COALESCE(p.ind_vivo, true) = true;
        
        indice_conversion := (total_ventas_kits::numeric / total_ventas_general::numeric) * 100;
    ELSE
        indice_conversion := 0;
    END IF;

    -- 12. Alerta de Stock Crítico (Suma de Instrumentos, Kits y Materias Primas bajo el mínimo)
    SELECT COUNT(*) INTO alerta_stock_critico
    FROM (
        SELECT id_instrumento FROM tab_instrumentos WHERE cant_disp <= stock_min AND COALESCE(ind_vivo, true) = true
        UNION ALL
        SELECT id_kit FROM tab_kits WHERE cant_disp <= stock_min AND COALESCE(ind_vivo, true) = true
        UNION ALL
        SELECT mpp.id_mat_prima FROM tab_mat_primas_prov mpp 
        JOIN tab_materias_primas mp ON mpp.id_mat_prima = mp.id_mat_prima 
        WHERE mpp.cant_mat_prima <= mp.stock_min 
        AND COALESCE(mpp.ind_vivo, true) = true AND COALESCE(mp.ind_vivo, true) = true
    ) AS sub_alertas;

END;
$$ LANGUAGE plpgsql;

-----------------------------------------------------------------------------
-- FUNCIÓN: fun_obtener_alertas_detalle
-- PROPÓSITO: Retorna la lista de productos que están bajo el stock mínimo.
-- DISPARADOR: Se ejecuta al hacer clic en el ícono de notificaciones (campana).
-- LLAMADO DESDE: querys.php -> getAlertasDetalle()
-- NOTA TÉCNICA: Se usa ::VARCHAR y ::INT para asegurar que el UNION ALL no falle 
--              por discrepancia de tipos entre tablas.
-----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fun_obtener_alertas_detalle()
RETURNS TABLE (
    tipo VARCHAR,
    nombre VARCHAR,
    actual INT,
    minimo INT
) AS $$
BEGIN
    RETURN QUERY
    -- 1. Instrumentos
    SELECT 
        'Instrumento'::VARCHAR as tipo, -- Casting explícito para evitar errores de tipo en la unión
        i.nom_instrumento::VARCHAR as nombre,
        i.cant_disp::INT as actual,
        i.stock_min::INT as minimo
    FROM tab_instrumentos i
    WHERE i.cant_disp <= i.stock_min 
    AND i.ind_vivo = true
    AND i.stock_min > 0
    
    UNION ALL
    
    -- 2. Kits
    SELECT 
        'Kit'::VARCHAR as tipo,
        k.nom_kit::VARCHAR as nombre,
        k.cant_disp::INT as actual,
        k.stock_min::INT as minimo
    FROM tab_kits k
    WHERE k.cant_disp <= k.stock_min 
    AND k.ind_vivo = true
    AND k.stock_min > 0
    
    UNION ALL
    
    -- 3. Materias Primas
    SELECT 
        'Materia Prima'::VARCHAR as tipo,
        mp.nom_materia_prima::VARCHAR as nombre,
        mpp.cant_mat_prima::INT as actual,
        mp.stock_min::INT as minimo
    FROM tab_mat_primas_prov mpp
    JOIN tab_materias_primas mp ON mpp.id_mat_prima = mp.id_mat_prima
    WHERE mpp.cant_mat_prima <= mp.stock_min 
    AND mpp.ind_vivo = true 
    AND mp.ind_vivo = true
    AND mp.stock_min > 0;

END;
$$ LANGUAGE plpgsql;

-- Función para obtener detalle de alertas de stock crítico
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
        CAST('Instrumento' AS VARCHAR) as tipo,
        i.nom_instrumento as nombre,
        i.cant_disp as actual,
        i.stock_min as minimo
    FROM tab_instrumentos i
    WHERE i.cant_disp <= i.stock_min 
    AND COALESCE(i.ind_vivo, true) = true
    
    UNION ALL
    
    -- 2. Kits
    SELECT 
        CAST('Kit' AS VARCHAR) as tipo,
        k.nom_kit as nombre,
        k.cant_disp as actual,
        k.stock_min as minimo
    FROM tab_kits k
    WHERE k.cant_disp <= k.stock_min 
    AND COALESCE(k.ind_vivo, true) = true
    
    UNION ALL
    
    -- 3. Materias Primas
    SELECT 
        CAST('Materia Prima' AS VARCHAR) as tipo,
        mp.nom_materia_prima as nombre,
        mpp.cant_mat_prima as actual,
        mp.stock_min as minimo
    FROM tab_mat_primas_prov mpp
    JOIN tab_materias_primas mp ON mpp.id_mat_prima = mp.id_mat_prima
    WHERE mpp.cant_mat_prima <= mp.stock_min 
    AND COALESCE(mpp.ind_vivo, true) = true AND COALESCE(mp.ind_vivo, true) = true;

END;
$$ LANGUAGE plpgsql;

/*
    -----------------------------------------------------------------------------
-- FUNCIÓN: fun_get_historico_precios
-- PROPÓSITO: Obtiene el registro de cambios de precio de una materia prima.
-- DISPARADOR: Se ejecuta al abrir el modal de detalles de una materia prima.
-- LLAMADO DESDE: querys.php -> getHistoricoPrecios()
-----------------------------------------------------------------------------
*/

drop function if exists fun_get_historico_precios;

CREATE OR REPLACE FUNCTION fun_get_historico_precios(jid_mat_prima INT)
RETURNS TABLE (
    fecha_formateada TEXT,
    precio_nuevo DECIMAL,
    precio_anterior DECIMAL,
    motivo VARCHAR,
    nom_prov VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    -- Unimos con proveedores para saber quién suministró ese precio
    SELECT 
        TO_CHAR(h.fecha_cambio, 'DD/MM/YYYY HH24:MI')::TEXT as fecha_formateada,
        h.precio_nuevo::DECIMAL,
        h.precio_anterior::DECIMAL,
        h.motivo::VARCHAR,
        p.nom_prov::VARCHAR
    FROM tab_historico_mat_prima h
    JOIN tab_proveedores p ON h.id_proveedor = p.id_prov
    WHERE h.id_materia_prima = jid_mat_prima
    ORDER BY h.fecha_cambio DESC;
END;
$$ LANGUAGE plpgsql;

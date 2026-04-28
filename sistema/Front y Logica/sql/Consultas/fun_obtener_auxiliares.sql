-- Función para obtener listas auxiliares (Solo Nombres) en JSON - ACTUALIZADA
CREATE OR REPLACE FUNCTION fun_obtener_auxiliares()
RETURNS JSON AS $$
DECLARE
    j_ciudades JSON;
    j_documentos JSON;
    j_bancos JSON;
    j_cargos JSON;
    j_sangre JSON;
    j_especializaciones JSON;
    j_proveedores JSON;
    j_generos JSON;             
    j_unidades_medida JSON;     
    j_result JSON;
BEGIN
    -- 1. Ciudades
    SELECT json_agg(json_build_object('id', t.id_ciudad, 'label', t.nom_ciudad) ORDER BY t.nom_ciudad) INTO j_ciudades FROM tab_ciudades t;
    
    -- 2. Documentos
    SELECT json_agg(json_build_object('id', t.id_documento, 'label', t.nom_tipo_docum) ORDER BY t.nom_tipo_docum) INTO j_documentos FROM tab_tipo_documentos t;
    
    -- 3. Bancos
    SELECT json_agg(json_build_object('id', t.id_banco, 'label', t.nom_banco) ORDER BY t.nom_banco) INTO j_bancos FROM tab_bancos t;
    
    -- 4. Cargos
    SELECT json_agg(json_build_object('id', t.id_cargo, 'label', t.nom_cargo) ORDER BY t.nom_cargo) INTO j_cargos FROM tab_cargos t;
    
    -- 5. Tipos de Sangre
    SELECT json_agg(json_build_object('id', t.id_tipo_sangre, 'label', t.nom_tip_sang) ORDER BY t.nom_tip_sang) INTO j_sangre FROM tab_tipo_sangre t;

    -- 6. Especializaciones
    SELECT json_agg(json_build_object('id', t.id_especializacion, 'label', t.nom_espec) ORDER BY t.nom_espec) INTO j_especializaciones FROM tab_tipo_especializacion t;

    -- 7. Proveedores
    SELECT json_agg(json_build_object('id', p.id_prov, 'label', p.nom_prov) ORDER BY p.nom_prov) INTO j_proveedores FROM tab_proveedores p WHERE p.ind_vivo = true;

    -- 8. GÉNEROS (Estático, tab_generos eliminada)
    j_generos := '[{"id":1,"label":"Masculino"},{"id":2,"label":"Femenino"},{"id":3,"label":"Otro"}]'::json;

    -- 9. UNIDADES DE MEDIDA (Nuevo campo para Fase 9)
    SELECT json_agg(json_build_object('id', u.id_unidad_medida, 'label', u.nom_unidad) ORDER BY u.nom_unidad) INTO j_unidades_medida FROM tab_unidades_medida u WHERE u.ind_vivo = true;

    -- Construir objeto JSON final incluyendo los nuevos auxiliares
    SELECT json_build_object(
        'ciudades', COALESCE(j_ciudades, '[]'::json),
        'documentos', COALESCE(j_documentos, '[]'::json),
        'bancos', COALESCE(j_bancos, '[]'::json),
        'cargos', COALESCE(j_cargos, '[]'::json),
        'sangre', COALESCE(j_sangre, '[]'::json),
        'especializaciones', COALESCE(j_especializaciones, '[]'::json),
        'proveedores', COALESCE(j_proveedores, '[]'::json),
        'generos', COALESCE(j_generos, '[]'::json),          -- Inyección al JSON
        'unidades', COALESCE(j_unidades_medida, '[]'::json)  -- Inyección al JSON
    ) INTO j_result;

    RETURN j_result;
END;
$$ LANGUAGE plpgsql;
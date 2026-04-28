/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Empleado Nulo:     SELECT fun_update_empleados(NULL, 1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1.5e6, 70, 1.70, NOW(), 'Obs');
   2.  ID Empleado Negativo: SELECT fun_update_empleados(-1, 1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1.5e6, 70, 1.70, NOW(), 'Obs');
   3.  ID Doc Invalido:      SELECT fun_update_empleados(1, -1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1.5e6, 70, 1.70, NOW(), 'Obs');
   4.  Salario Bajo:         SELECT fun_update_empleados(1, 1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1000000, 70, 1.70, NOW(), 'Obs');
   5.  Peso Invalido (<40):  SELECT fun_update_empleados(1, 1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1.5e6, 20, 1.70, NOW(), 'Obs');
   6.  Email Invalido fmt:   SELECT fun_update_empleados(1, 1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'badmail', 300, NOW(), 1.5e6, 70, 1.70, NOW(), 'Obs');
   7.  Nombre Vacío:         SELECT fun_update_empleados(1, 1, 1, 1, 1, '123', '', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1.5e6, 70, 1.70, NOW(), 'Obs');
   8.  ID Inexistente (999): SELECT fun_update_empleados(99999, 1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1.5e6, 70, 1.70, NOW(), 'Obs');
   9.  Fecha Futura Examen:  SELECT fun_update_empleados(1, 1, 1, 1, 1, '123', 'N', 'S', 'A', 'S', 'm@m.com', 300, NOW(), 1.5e6, 70, 1.70, '2030-01-01', 'Obs');
   10. CASO EXITOSO:         SELECT fun_update_empleados(1, 1, 1, 1, 1, '10203040', 'Juan', 'David', 'Perez', NULL, 'juan@empresa.com', 3105556677, CURRENT_DATE, 2500000, 75, 1.78, CURRENT_DATE, 'Promocion');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_insert_mat_prima_proveedor (jid_mat_prima tab_mat_primas_prov.id_mat_prima%TYPE,
                                                            jid_prov tab_mat_primas_prov.id_prov%TYPE,
                                                            jlote tab_mat_primas_prov.lote%TYPE,
                                                            jtipo_mat_prima tab_mat_primas_prov.tipo_mat_prima%TYPE,
                                                            jvalor_medida tab_mat_primas_prov.valor_medida%TYPE,
                                                            jid_unidad tab_mat_primas_prov.id_unidad_medida%TYPE,
                                                            jcant_inicial tab_mat_primas_prov.cant_mat_prima%TYPE) 
                                                            RETURNS BOOLEAN AS
$$
    DECLARE j_check_val INTEGER;
BEGIN
    -- Validaciones IDs
        IF jid_mat_prima IS NULL OR jid_mat_prima <= 0 THEN 
            RAISE NOTICE 'Error: ID Materia Prima inválido.'; 
            RETURN FALSE; 
        END IF;

        IF jid_prov IS NULL OR jid_prov <= 0 THEN 
            RAISE NOTICE 'Error: ID Proveedor inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Validaciones Existencia
        SELECT 1 INTO j_check_val FROM tab_materias_primas WHERE id_mat_prima = jid_mat_prima LIMIT 1;
        
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: Materia prima no existe.';
            RETURN FALSE;
        END IF;

        SELECT 1 INTO j_check_val FROM tab_proveedores WHERE id_prov = jid_prov LIMIT 1;
        
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: Proveedor no existe.';
            RETURN FALSE;
        END IF;

    -- Validaciones Nuevos Campos
        IF jlote IS NULL THEN 
            RAISE NOTICE 'Error: Lote obligatorio.'; 
            RETURN FALSE; 
        END IF;
        
        IF jtipo_mat_prima IS NULL OR TRIM(jtipo_mat_prima) = '' THEN 
            RAISE NOTICE 'Error: Tipo materia prima obligatorio.'; 
            RETURN FALSE; 
        END IF;
        

        IF jvalor_medida IS NULL OR jvalor_medida <= 0 THEN 
            RAISE NOTICE 'Error: Valor de medida inválido.'; 
            RETURN FALSE; 
        END IF;

        IF jid_unidad IS NULL OR jid_unidad <= 0 THEN 
            RAISE NOTICE 'Error: ID de unidad de medida inválido.'; 
            RETURN FALSE; 
        END IF;

        -- Validar existencia Unidad de Medida
        SELECT 1 INTO j_check_val FROM tab_unidades_medida WHERE id_unidad_medida = jid_unidad LIMIT 1;
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: La unidad de medida especificada no existe.';
            RETURN FALSE;
        END IF;

    -- Validaciones Cantidad
        IF jcant_inicial IS NULL OR jcant_inicial < 0 THEN 
            RAISE NOTICE 'Error: Cantidad inicial negativa no permitida.'; 
            RETURN FALSE; 
        END IF;

    -- Insertar Relación
        INSERT INTO tab_mat_primas_prov (id_mat_prima, id_prov, lote, tipo_mat_prima, valor_medida, id_unidad_medida, cant_mat_prima) 
        VALUES (jid_mat_prima, jid_prov, jlote, TRIM(jtipo_mat_prima), jvalor_medida, jid_unidad, jcant_inicial);

        RAISE NOTICE 'Relación MP-Proveedor registrada.';
        RETURN TRUE;

EXCEPTION
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Esta relación MP-Proveedor ya existe. Use Update.'; 
        RETURN FALSE;
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Error: Referencias inválidas en BD.';
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error inesperado: %', SQLERRM; 
        RETURN FALSE;
END;
$$ 
LANGUAGE plpgsql;

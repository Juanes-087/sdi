/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Histórico Nulo:    SELECT fun_update_historico_mat_prima(NULL, 1, 1, 10, 12, NOW(), 'Motivo');
   2.  ID Histórico Neg:     SELECT fun_update_historico_mat_prima(-1, 1, 1, 10, 12, NOW(), 'Motivo');
   3.  MP Nulo:              SELECT fun_update_historico_mat_prima(1, NULL, 1, 10, 12, NOW(), 'Motivo');
   4.  Prov Nulo:            SELECT fun_update_historico_mat_prima(1, 1, NULL, 10, 12, NOW(), 'Motivo');
   5.  MP Inexistente:       SELECT fun_update_historico_mat_prima(1, 99999, 1, 10, 12, NOW(), 'Motivo');
   6.  Prov Inexistente:     SELECT fun_update_historico_mat_prima(1, 1, 99999, 10, 12, NOW(), 'Motivo');
   7.  Precio Negativo:      SELECT fun_update_historico_mat_prima(1, 1, 1, -10, 12, NOW(), 'Motivo');
   8.  Fecha Nula:           SELECT fun_update_historico_mat_prima(1, 1, 1, 10, 12, NULL, 'Motivo');
   9.  ID Inexistente (999): SELECT fun_update_historico_mat_prima(99999, 1, 1, 10, 12, NOW(), 'Motivo');
   10. CASO EXITOSO:         SELECT fun_update_historico_mat_prima(1, 1, 1, 1000, 1200, CURRENT_TIMESTAMP, 'Ajuste anual');
   -----------------------------------------------------------------------------
*/

drop function if exists fun_update_historico_mat_prima();

CREATE OR REPLACE FUNCTION fun_update_historico_mat_prima   (jid_historico tab_historico_mat_prima.id_historico%TYPE,
                                                            jid_materia_prima tab_historico_mat_prima.id_materia_prima%TYPE,
                                                            jid_proveedor tab_historico_mat_prima.id_proveedor%TYPE,
                                                            jprecio_anterior tab_historico_mat_prima.precio_anterior%TYPE,
                                                            jprecio_nuevo tab_historico_mat_prima.precio_nuevo%TYPE,
                                                            jfecha_cambio tab_historico_mat_prima.fecha_cambio%TYPE,
                                                            jmotivo tab_historico_mat_prima.motivo%TYPE DEFAULT 'N/A')
                                                            RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_historico <= 0 THEN 
            RAISE NOTICE 'Error: ID Histórico inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_historico_mat_prima WHERE id_historico = jid_historico;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Histórico con ID % no encontrado.', jid_historico;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Histórico con ID % se encuentra eliminado. No se puede actualizar.', jid_historico;
            RETURN FALSE;
        END IF;

    -- Validar FK Materia Prima
        IF jid_materia_prima <= 0 THEN 
            RAISE NOTICE 'Error: ID MP inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_materias_primas WHERE id_mat_prima = jid_materia_prima;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Materia Prima no existe o inactiva.'; 
            RETURN FALSE; 
        END IF;

    -- Validar FK Proveedor
        IF jid_proveedor <= 0 THEN 
            RAISE NOTICE 'Error: ID Proveedor inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_proveedores WHERE id_prov = jid_proveedor;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Proveedor no existe o inactivo.'; 
            RETURN FALSE; 
        END IF;
        
    -- Validar Precios
        IF jprecio_anterior < 0 OR jprecio_nuevo < 0 THEN 
            RAISE NOTICE 'Error: Precios no pueden ser negativos.'; 
            RETURN FALSE; 
        END IF;
        
        IF jfecha_cambio IS NULL THEN
            RAISE NOTICE 'Error: Fecha de cambio no puede ser nula.';
            RETURN FALSE;
        END IF;

    -- Actualizar
        UPDATE tab_historico_mat_prima SET
            id_materia_prima = jid_materia_prima,
            id_proveedor = jid_proveedor,
            precio_anterior = jprecio_anterior,
            precio_nuevo = jprecio_nuevo,
            fecha_cambio = jfecha_cambio,
            motivo = jmotivo
        WHERE id_historico = jid_historico;
        
        RAISE NOTICE 'Histórico actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

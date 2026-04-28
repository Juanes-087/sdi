/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Prov Nulo:         SELECT fun_delete_mat_prim_provee(NULL, 1);
   2.  ID Mat Nulo:          SELECT fun_delete_mat_prim_provee(1, NULL);
   3.  ID Prov Negativo:     SELECT fun_delete_mat_prim_provee(-1, 1);
   4.  ID Mat Negativo:      SELECT fun_delete_mat_prim_provee(1, -1);
   5.  ID Prov Cero:         SELECT fun_delete_mat_prim_provee(0, 1);
   6.  ID Mat Cero:          SELECT fun_delete_mat_prim_provee(1, 0);
   7.  Ambos Nulos:          SELECT fun_delete_mat_prim_provee(NULL, NULL);
   8.  Rel Inexistente:      SELECT fun_delete_mat_prim_provee(99999, 99999);
   9.  Ya eliminado:         SELECT fun_delete_mat_prim_provee(2, 1);
   10. CASO EXITOSO:         SELECT fun_delete_mat_prim_provee(1, 1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_mat_prim_provee(jid_prov tab_mat_primas_prov.id_prov%TYPE,
                                                      jid_mat_prima tab_mat_primas_prov.id_mat_prima%TYPE) 
                                                      RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_prov IS NULL OR jid_mat_prima IS NULL THEN
            RAISE NOTICE 'Error: IDs nulos.';
            RETURN FALSE;
        END IF;
        
        IF jid_prov <= 0 OR jid_mat_prima <= 0 THEN
            RAISE NOTICE 'Error: IDs inválidos.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo 
        FROM tab_mat_primas_prov 
        WHERE id_prov = jid_prov AND id_mat_prima = jid_mat_prima;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Relación Materia Prima - Proveedor no encontrada.';
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: La relación Materia Prima - Proveedor ya fue eliminada anteriormente.';
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_mat_primas_prov SET  user_delete = CURRENT_USER,
                                        fec_delete = CURRENT_TIMESTAMP,
                                        ind_vivo = FALSE
                                        Where id_prov = jid_prov 
                                        AND id_mat_prima = jid_mat_prima;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar la relación Materia Prima - Proveedor.';
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Relación Materia Prima - Proveedor eliminada exitosamente.';
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
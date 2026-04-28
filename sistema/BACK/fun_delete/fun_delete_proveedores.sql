/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Prov Nulo:         SELECT fun_delete_prov(NULL);
   2.  ID Prov Negativo:     SELECT fun_delete_prov(-1);
   3.  ID Prov Cero:         SELECT fun_delete_prov(0);
   4.  ID Inexistente:       SELECT fun_delete_prov(99999);
   5.  Ya eliminado:         SELECT fun_delete_prov(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_prov(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_prov(2147483647);
   8.  Min Int Value:        SELECT fun_delete_prov(-2147483648);
   9.  Float Cast:           SELECT fun_delete_prov(1.9::INT);
   10. CASO EXITOSO:         SELECT fun_delete_prov(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_prov(jid_prov tab_proveedores.id_prov%TYPE) 
                                           RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_prov IS NULL THEN
            RAISE NOTICE 'Error: ID de proveedor nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_prov <= 0 THEN
            RAISE NOTICE 'Error: ID de proveedor inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_proveedores WHERE id_prov = jid_prov;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Proveedor con ID % no encontrado.', jid_prov;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El Proveedor con ID % ya fue eliminado anteriormente.', jid_prov;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_proveedores SET    user_delete = CURRENT_USER,
                                      fec_delete = CURRENT_TIMESTAMP,
                                      ind_vivo = FALSE
                                      Where id_prov = jid_prov;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el Proveedor con ID %.', jid_prov;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Proveedor con ID % eliminado exitosamente.', jid_prov;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
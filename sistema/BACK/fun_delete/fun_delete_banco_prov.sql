/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Prov Nulo:         SELECT fun_delete_banco_prov(NULL, 1);
   2.  ID Banco Nulo:        SELECT fun_delete_banco_prov(1, NULL);
   3.  ID Prov Negativo:     SELECT fun_delete_banco_prov(-1, 1);
   4.  ID Banco Negativo:    SELECT fun_delete_banco_prov(1, -1);
   5.  ID Prov Cero:         SELECT fun_delete_banco_prov(0, 1);
   6.  ID Banco Cero:        SELECT fun_delete_banco_prov(1, 0);
   7.  Ambos Nulos:          SELECT fun_delete_banco_prov(NULL, NULL);
   8.  Rel Inexistente:      SELECT fun_delete_banco_prov(99999, 99999);
   9.  Ya eliminado:         SELECT fun_delete_banco_prov(2, 1); -- Asumiendo ID 2 eliminado
   10. CASO EXITOSO:         SELECT fun_delete_banco_prov(1, 1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_banco_prov(jid_prov tab_bancos_proveedor.id_prov%TYPE,
                                                 jid_banco tab_bancos_proveedor.id_banco%TYPE) 
                                                 RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_prov IS NULL OR jid_banco IS NULL THEN
            RAISE NOTICE 'Error: IDs nulos.';
            RETURN FALSE;
        END IF;
        
        IF jid_prov <= 0 OR jid_banco <= 0 THEN
            RAISE NOTICE 'Error: IDs inválidos.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo 
        FROM tab_bancos_proveedor 
        Where id_prov = jid_prov AND id_banco = jid_banco;

    -- 1. Verificar existencia física (Si es NULL, no encontró el registro)
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Relación Banco-Proveedor no encontrada.';
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico (Si es FALSE, ya estaba borrado)
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: La relación Banco-Proveedor ya fue eliminada anteriormente.';
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_bancos_proveedor SET user_delete = CURRENT_USER,
                                        fec_delete = CURRENT_TIMESTAMP,
                                        ind_vivo = FALSE
                                        Where id_prov = jid_prov 
                                        AND id_banco = jid_banco;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar la relación Banco-Proveedor.';
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Relación Banco-Proveedor eliminada exitosamente.';
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
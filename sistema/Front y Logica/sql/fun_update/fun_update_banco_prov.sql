/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Prov Nulo:         SELECT fun_update_bancos_proveedor(NULL, 1, '123-456');
   2.  ID Banco Nulo:        SELECT fun_update_bancos_proveedor(1, NULL, '123-456');
   3.  ID Prov Negativo:     SELECT fun_update_bancos_proveedor(-5, 1, '123-456');
   4.  ID Banco Negativo:    SELECT fun_update_bancos_proveedor(1, -5, '123-456');
   5.  Cuenta Vacía:         SELECT fun_update_bancos_proveedor(1, 1, '');
   6.  SQL Injection (Cta):  SELECT fun_update_bancos_proveedor(1, 1, '''; DROP TABLE tab_bancos; --');
   7.  ID Inexistente (Prov):SELECT fun_update_bancos_proveedor(99999, 1, '123-456');
   8.  ID Inexistente (Bco): SELECT fun_update_bancos_proveedor(1, 99999, '123-456');
   9.  Soft Delete (Asumiendo ID 2 eliminado): SELECT fun_update_bancos_proveedor(2, 1, '123-456');
   10. CASO EXITOSO:         SELECT fun_update_bancos_proveedor(1, 1, '987-654-321-UPDATED');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_bancos_proveedor  (jid_prov tab_bancos_proveedor.id_prov%TYPE,
                                                        jid_banco tab_bancos_proveedor.id_banco%TYPE,
                                                        jnum_cuenta tab_bancos_proveedor.num_cuenta%TYPE)
                                                        RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validar IDs
        IF jid_prov IS NULL OR jid_prov <= 0 THEN 
            RAISE NOTICE 'Error: ID de proveedor inválido.'; 
            RETURN FALSE; 
        END IF;

        IF jid_banco IS NULL OR jid_banco <= 0 THEN 
            RAISE NOTICE 'Error: ID de banco inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo 
        FROM tab_bancos_proveedor 
        WHERE id_prov = jid_prov AND id_banco = jid_banco;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Relación Banco-Proveedor no encontrada.';
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: La Relación Banco-Proveedor se encuentra eliminada. No se puede actualizar.';
            RETURN FALSE;
        END IF;

    -- Validar Cuenta
        IF jnum_cuenta IS NULL OR jnum_cuenta !~ '^[0-9]{10,20}$' THEN 
            RAISE NOTICE 'Error: El número de cuenta es obligatorio y debe tener entre 10 y 20 dígitos numéricos.'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
        UPDATE tab_bancos_proveedor 
        SET num_cuenta = jnum_cuenta 
        WHERE id_prov = jid_prov AND id_banco = jid_banco;
        
        RAISE NOTICE 'Relación Banco-Proveedor actualizada exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

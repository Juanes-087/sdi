/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Banco Nulo:        SELECT fun_update_bancos(NULL, 1, 'Nom', 'Dir');
   2.  ID Banco Negativo:    SELECT fun_update_bancos(-1, 1, 'Nom', 'Dir');
   3.  ID Ciudad Nulo:       SELECT fun_update_bancos(1, NULL, 'Nom', 'Dir');
   4.  ID Ciudad Negativo:   SELECT fun_update_bancos(1, -5, 'Nom', 'Dir');
   5.  Nombre Vacío:         SELECT fun_update_bancos(1, 1, '', 'Dir');
   6.  Dirección Vacía:      SELECT fun_update_bancos(1, 1, 'Nom', '');
   7.  SQL Inj (Nombre):     SELECT fun_update_bancos(1, 1, '''; DROP TABLE tab_bancos; --', 'Dir');
   8.  ID Banco Inexistente: SELECT fun_update_bancos(99999, 1, 'Nom', 'Dir');
   9.  ID Ciudad Inexistente:SELECT fun_update_bancos(1, 99999, 'Nom', 'Dir');
   10. CASO EXITOSO:         SELECT fun_update_bancos(1, 1, 'Banco Updated', 'Calle 123');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_bancos(jid_banco tab_bancos.id_banco%TYPE,
                                             jid_ciudad tab_bancos.id_ciudad%TYPE,
                                             jnom_banco tab_bancos.nom_banco%TYPE,
                                             jdir_banco tab_bancos.dir_banco%TYPE)
                                             RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_banco IS NULL OR jid_banco <= 0 THEN 
            RAISE NOTICE 'Error: ID Banco inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_bancos WHERE id_banco = jid_banco;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Banco con ID % no encontrado.', jid_banco;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Banco con ID % se encuentra eliminado. No se puede actualizar.', jid_banco;
            RETURN FALSE;
        END IF;

    -- FKs
        IF jid_ciudad IS NULL OR jid_ciudad <= 0 THEN 
            RAISE NOTICE 'Error: ID Ciudad inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_ciudades WHERE id_ciudad = jid_ciudad;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Ciudad no existe o inactiva.'; 
            RETURN FALSE; 
        END IF;

    -- Strings
        IF jnom_banco IS NULL OR TRIM(jnom_banco) = '' THEN 
            RAISE NOTICE 'Error: Nombre banco vacío.'; 
            RETURN FALSE; 
        END IF;

        IF jdir_banco IS NULL OR TRIM(jdir_banco) = '' THEN 
            RAISE NOTICE 'Error: Dirección banco vacía.'; 
            RETURN FALSE; 
        END IF;

        UPDATE tab_bancos SET
            id_ciudad = jid_ciudad,
            nom_banco = jnom_banco,
            dir_banco = jdir_banco
        WHERE id_banco = jid_banco;
        
        RAISE NOTICE 'Banco actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

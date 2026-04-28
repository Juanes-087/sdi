/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Cargo Nulo:        SELECT fun_update_cargos(NULL, 'Nom');
   2.  ID Cargo Negativo:    SELECT fun_update_cargos(-1, 'Nom');
   3.  Nombre Vacío:         SELECT fun_update_cargos(1, '');
   4.  Nombre Solo Espacios: SELECT fun_update_cargos(1, '   ');
   5.  SQL Inj 1 (Simple):   SELECT fun_update_cargos(1, '''; DROP TABLE tab_cargos; --');
   6.  SQL Inj 2 (Logic):    SELECT fun_update_cargos(1, ''' OR 1=1; --');
   7.  ID Inexistente (999): SELECT fun_update_cargos(99999, 'Nom');
   8.  Soft Deleted (ID 2):  SELECT fun_update_cargos(2, 'Nom');
   9.  Nombre NULL:          SELECT fun_update_cargos(1, NULL);
   10. CASO EXITOSO:         SELECT fun_update_cargos(1, 'Gerente General Updated');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_cargos  (jid_cargo tab_cargos.id_cargo%TYPE,
                                              jnom_cargo tab_cargos.nom_cargo%TYPE)
                                              RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_cargo IS NULL OR jid_cargo <= 0 THEN
            RAISE NOTICE 'Error: ID de cargo inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado check
        SELECT ind_vivo INTO j_ind_vivo FROM tab_cargos WHERE id_cargo = jid_cargo;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Cargo con ID % no encontrado.', jid_cargo;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Cargo con ID % se encuentra eliminado. No se puede actualizar.', jid_cargo;
            RETURN FALSE;
        END IF;

    -- Validar Nombre
        IF jnom_cargo IS NULL OR TRIM(jnom_cargo) = '' THEN
            RAISE NOTICE 'Error: El nombre del cargo no puede estar vacío.';
            RETURN FALSE;
        END IF;

    -- Actualizar
        UPDATE tab_cargos 
        SET nom_cargo = jnom_cargo 
        WHERE id_cargo = jid_cargo;
        
        RAISE NOTICE 'Cargo actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

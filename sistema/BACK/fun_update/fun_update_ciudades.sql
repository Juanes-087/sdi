/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Ciudad Nulo:       SELECT fun_update_ciudades(NULL, 1, 'Nom');
   2.  ID Ciudad Negativo:   SELECT fun_update_ciudades(-1, 1, 'Nom');
   3.  ID Depart Nulo:       SELECT fun_update_ciudades(1, NULL, 'Nom');
   4.  ID Depart Negativo:   SELECT fun_update_ciudades(1, -5, 'Nom');
   5.  Nombre Vacío:         SELECT fun_update_ciudades(1, 1, '');
   6.  SQL Inj (Nombre):     SELECT fun_update_ciudades(1, 1, '''; DROP TABLE tab_ciudades; --');
   7.  ID Inexistente (999): SELECT fun_update_ciudades(99999, 1, 'Nom');
   8.  Soft Deleted (ID 2):  SELECT fun_update_ciudades(2, 1, 'Nom');
   9.  Depart Inexistente:   SELECT fun_update_ciudades(1, 99999, 'Nom');
   10. CASO EXITOSO:         SELECT fun_update_ciudades(1, 1, 'Medellín Updated');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_ciudades  (jid_ciudad tab_ciudades.id_ciudad%TYPE,
                                                jid_depart tab_ciudades.id_depart%TYPE,
                                                jnom_ciudad tab_ciudades.nom_ciudad%TYPE)
                                                RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_ciudad IS NULL OR jid_ciudad <= 0 THEN
            RAISE NOTICE 'Error: ID de ciudad inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_ciudades WHERE id_ciudad = jid_ciudad;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Ciudad con ID % no encontrada.', jid_ciudad;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: La Ciudad con ID % se encuentra eliminada. No se puede actualizar.', jid_ciudad;
            RETURN FALSE;
        END IF;

    -- Validar FK Departamento
        IF jid_depart IS NULL OR jid_depart <= 0 THEN
            RAISE NOTICE 'Error: ID de departamento inválido.';
            RETURN FALSE;
        END IF;

    -- Validar existencia del FK (Departamento)
        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_departamentos WHERE id_depart = jid_depart;
        
        IF j_ind_vivo_fk IS NULL THEN
            RAISE NOTICE 'Error: El departamento referenciado (ID %) no existe.', jid_depart;
            RETURN FALSE;
        END IF;

        IF j_ind_vivo_fk = FALSE THEN
            RAISE NOTICE 'Error: El departamento referenciado (ID %) está eliminado (inactivo).', jid_depart;
            RETURN FALSE;
        END IF;

    -- Validar Nombre
        IF jnom_ciudad IS NULL OR TRIM(jnom_ciudad) = '' THEN
            RAISE NOTICE 'Error: El nombre de la ciudad no puede estar vacío.';
            RETURN FALSE;
        END IF;

    -- Actualizar
        UPDATE tab_ciudades 
        SET id_depart = jid_depart, 
            nom_ciudad = jnom_ciudad 
        WHERE id_ciudad = jid_ciudad;
        
        RAISE NOTICE 'Ciudad actualizada exitosamente.';
        RETURN TRUE;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

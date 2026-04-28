/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Depart Nulo:       SELECT fun_update_departamentos(NULL, 'Antioquia');
   2.  ID Depart Negativo:   SELECT fun_update_departamentos(-1, 'Antioquia');
   3.  Nombre Vacío:         SELECT fun_update_departamentos(1, '');
   4.  Nombre Solo Espacios: SELECT fun_update_departamentos(1, '   ');
   5.  SQL Inj 1 (Simple):   SELECT fun_update_departamentos(1, '''; DROP TABLE tab_departamentos; --');
   6.  SQL Inj 2 (Logic):    SELECT fun_update_departamentos(1, ''' OR 1=1; --');
   7.  ID Inexistente (999): SELECT fun_update_departamentos(99999, 'Nom');
   8.  Soft Deleted (ID 2):  SELECT fun_update_departamentos(2, 'Nom');
   9.  Nombre NULL:          SELECT fun_update_departamentos(1, NULL);
   10. CASO EXITOSO:         SELECT fun_update_departamentos(1, 'Antioquia Updated');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_departamentos (jid_depart tab_departamentos.id_depart%TYPE,
                                                    jnom_depart tab_departamentos.nom_depart%TYPE)
                                                    RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_depart IS NULL OR jid_depart <= 0 THEN
            RAISE NOTICE 'Error: ID de departamento inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_departamentos WHERE id_depart = jid_depart;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Departamento con ID % no encontrado.', jid_depart;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Departamento con ID % se encuentra eliminado (inactivo). No se puede actualizar.', jid_depart;
            RETURN FALSE;
        END IF;

    -- Validar Campos
        IF jnom_depart IS NULL OR TRIM(jnom_depart) = '' THEN
            RAISE NOTICE 'Error: El nombre del departamento no puede estar vacío.';
            RETURN FALSE;
        END IF;

    -- Actualizar
        UPDATE tab_departamentos 
        SET nom_depart = jnom_depart 
        WHERE id_depart = jid_depart;
        
        RAISE NOTICE 'Departamento actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$ LANGUAGE plpgsql;

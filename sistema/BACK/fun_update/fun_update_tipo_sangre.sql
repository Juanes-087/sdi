/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Sangre Nulo:       SELECT fun_update_tipo_sangre(NULL, 'O+');
   2.  ID Sangre Negativo:   SELECT fun_update_tipo_sangre(-1, 'O+');
   3.  Nombre Vacío:         SELECT fun_update_tipo_sangre(1, '');
   4.  Nombre Espacios:      SELECT fun_update_tipo_sangre(1, '   ');
   5.  SQL Inj (Nom):        SELECT fun_update_tipo_sangre(1, '''; DROP TABLE tab_sangre; --');
   6.  ID Inexistente (999): SELECT fun_update_tipo_sangre(99999, 'O+');
   7.  Soft Delet (ID 2):    SELECT fun_update_tipo_sangre(2, 'O+');
   8.  Nombre NULL:          SELECT fun_update_tipo_sangre(1, NULL);
   9.  ID Cero:              SELECT fun_update_tipo_sangre(0, 'O+');
   10. CASO EXITOSO:         SELECT fun_update_tipo_sangre(1, 'O Positivo');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_tipo_sangre   (jid_tipo_sangre tab_tipo_sangre.id_tipo_sangre%TYPE,
                                                    jnom_tip_sang tab_tipo_sangre.nom_tip_sang%TYPE)
                                                    RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_tipo_sangre IS NULL OR jid_tipo_sangre <= 0 THEN
            RAISE NOTICE 'Error: ID de tipo de sangre inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado check
        SELECT ind_vivo INTO j_ind_vivo FROM tab_tipo_sangre WHERE id_tipo_sangre = jid_tipo_sangre;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Tipo de Sangre con ID % no encontrado.', jid_tipo_sangre;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Tipo de Sangre con ID % se encuentra eliminado. No se puede actualizar.', jid_tipo_sangre;
            RETURN FALSE;
        END IF;

    -- Validar Nombre
        IF jnom_tip_sang IS NULL OR TRIM(jnom_tip_sang) = '' THEN
            RAISE NOTICE 'Error: El nombre del tipo de sangre no puede estar vacío.';
            RETURN FALSE;
        END IF;

    -- Actualizar
        UPDATE tab_tipo_sangre 
        SET nom_tip_sang = jnom_tip_sang 
        WHERE id_tipo_sangre = jid_tipo_sangre;
        
        RAISE NOTICE 'Tipo de Sangre actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Menu Nulo:         SELECT fun_update_menu(NULL, 'Inicio');
   2.  ID Menu Negativo:     SELECT fun_update_menu(-1, 'Inicio');
   3.  Nombre Vacío:         SELECT fun_update_menu(1, '');
   4.  Nombre Espacios:      SELECT fun_update_menu(1, '   ');
   5.  SQL Inj (Nom):        SELECT fun_update_menu(1, '''; DROP TABLE tab_menu; --');
   6.  ID Menu Inexistente:  SELECT fun_update_menu(99999, 'Inicio');
   7.  Soft Delet (ID 2):    SELECT fun_update_menu(2, 'Inicio');
   8.  Nombre NULL:          SELECT fun_update_menu(1, NULL);
   9.  ID Cero:              SELECT fun_update_menu(0, 'Inicio');
   10. CASO EXITOSO:         SELECT fun_update_menu(1, 'Dashboard Principal');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_menu(jid_menu tab_menu.id_menu%TYPE,
                                           jnom_menu tab_menu.nom_menu%TYPE)
                                           RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_menu IS NULL OR jid_menu <= 0 THEN
            RAISE NOTICE 'Error: ID de menú inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_menu WHERE id_menu = jid_menu;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Menú con ID % no encontrado.', jid_menu;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Menú con ID % se encuentra eliminado. No se puede actualizar.', jid_menu;
            RETURN FALSE;
        END IF;

    -- Validar Nombre
        IF jnom_menu IS NULL OR TRIM(jnom_menu) = '' THEN 
            RAISE NOTICE 'Error: El nombre del menú no puede estar vacío.'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
        UPDATE tab_menu 
        SET nom_menu = jnom_menu 
        WHERE id_menu = jid_menu;
        
        RAISE NOTICE 'Menú actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

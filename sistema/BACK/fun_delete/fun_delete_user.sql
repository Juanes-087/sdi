/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID User Nulo:         SELECT fun_user_delete(NULL);
   2.  ID User Negativo:     SELECT fun_user_delete(-1);
   3.  ID User Cero:         SELECT fun_user_delete(0);
   4.  ID Inexistente:       SELECT fun_user_delete(99999);
   5.  Ya eliminado:         SELECT fun_user_delete(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_user_delete(NULL);
   7.  Max Int Value:        SELECT fun_user_delete(2147483647);
   8.  Min Int Value:        SELECT fun_user_delete(-2147483648);
   9.  SQL Injection:        SELECT fun_user_delete(1 OR 1=1); -- Error SQLSTATE, revisar
   10. CASO EXITOSO:         SELECT fun_user_delete(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_user_delete(jid_user tab_users.id_user%TYPE) 
                                           RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_user IS NULL THEN
            RAISE NOTICE 'Error: ID de usuario nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_user <= 0 THEN
            RAISE NOTICE 'Error: ID de usuario inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_users WHERE id_user = jid_user;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Usuario con ID % no encontrado.', jid_user;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El usuario con ID % ya fue eliminado anteriormente.', jid_user;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_users SET    user_delete = CURRENT_USER,
                                fec_delete = CURRENT_TIMESTAMP,
                                ind_vivo = FALSE
                                Where id_user = jid_user;

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el usuario con ID %.', jid_user;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Usuario con ID % eliminado exitosamente.', jid_user;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Ciudad Nulo:       SELECT fun_delete_ciudad(NULL);
   2.  ID Ciudad Negativo:   SELECT fun_delete_ciudad(-1);
   3.  ID Ciudad Cero:       SELECT fun_delete_ciudad(0);
   4.  ID Inexistente:       SELECT fun_delete_ciudad(99999);
   5.  Ya eliminado:         SELECT fun_delete_ciudad(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_ciudad(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_ciudad(2147483647);
   8.  Min Int Value:        SELECT fun_delete_ciudad(-2147483648);
   9.  Tipo Float:           SELECT fun_delete_ciudad(1.5::INT); -- Casteo automatico, prueba integridad
   10. CASO EXITOSO:         SELECT fun_delete_ciudad(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_ciudad(jid_ciudad tab_ciudades.id_ciudad%TYPE) 
                                             RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_ciudad IS NULL THEN
            RAISE NOTICE 'Error: ID de ciudad nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_ciudad <= 0 THEN
            RAISE NOTICE 'Error: ID de ciudad inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_ciudades WHERE id_ciudad = jid_ciudad;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Ciudad con ID % no encontrada.', jid_ciudad;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: La Ciudad con ID % ya fue eliminada anteriormente.', jid_ciudad;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_ciudades SET user_delete = CURRENT_USER,
                                fec_delete = CURRENT_TIMESTAMP,
                                ind_vivo = FALSE
                                Where id_ciudad = jid_ciudad;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar la Ciudad con ID %.', jid_ciudad;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Ciudad con ID % eliminada exitosamente.', jid_ciudad;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
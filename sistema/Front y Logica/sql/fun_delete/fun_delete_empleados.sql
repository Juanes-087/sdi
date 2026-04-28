/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Empleado Nulo:     SELECT fun_delete_empleado(NULL);
   2.  ID Empleado Negativo: SELECT fun_delete_empleado(-1);
   3.  ID Empleado Cero:     SELECT fun_delete_empleado(0);
   4.  ID Inexistente:       SELECT fun_delete_empleado(99999);
   5.  Ya eliminado:         SELECT fun_delete_empleado(2);
   6.  CASO EXITOSO:         SELECT fun_delete_empleado(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_empleado(jid_empleado tab_empleados.id_empleado%TYPE) 
                                               RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_empleado IS NULL THEN
            RAISE NOTICE 'Error: ID de empleado nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_empleado <= 0 THEN
            RAISE NOTICE 'Error: ID de empleado inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_empleados WHERE id_empleado = jid_empleado;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Empleado con ID % no encontrado.', jid_empleado;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El Empleado con ID % ya fue eliminado anteriormente.', jid_empleado;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_empleados SET user_delete = CURRENT_USER,
                                 fec_delete = CURRENT_TIMESTAMP,
                                 ind_vivo = FALSE
                                 Where id_empleado = jid_empleado;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el Empleado con ID %.', jid_empleado;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Empleado con ID % eliminado exitosamente.', jid_empleado;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
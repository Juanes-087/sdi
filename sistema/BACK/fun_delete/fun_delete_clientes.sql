/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Cliente Nulo:      SELECT fun_delete_cliente(NULL);
   2.  ID Cliente Negativo:  SELECT fun_delete_cliente(-1);
   3.  ID Cliente Cero:      SELECT fun_delete_cliente(0);
   4.  ID Inexistente:       SELECT fun_delete_cliente(99999);
   5.  Ya eliminado:         SELECT fun_delete_cliente(2); -- Asumiendo ID 2 eliminado
   6.  CASO EXITOSO:         SELECT fun_delete_cliente(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_cliente(jid_cliente tab_clientes.id_cliente%TYPE) 
                                              RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_cliente IS NULL THEN
            RAISE NOTICE 'Error: ID de cliente nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_cliente <= 0 THEN
            RAISE NOTICE 'Error: ID de cliente inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_clientes WHERE id_cliente = jid_cliente;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Cliente con ID % no encontrado.', jid_cliente;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El Cliente con ID % ya fue eliminado anteriormente.', jid_cliente;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_clientes SET user_delete = CURRENT_USER,
                                fec_delete = CURRENT_TIMESTAMP,
                                ind_vivo = FALSE
                                Where id_cliente = jid_cliente;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el Cliente con ID %.', jid_cliente;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Cliente con ID % eliminado exitosamente.', jid_cliente;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
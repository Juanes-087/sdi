/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Prod Nulo:         SELECT fun_delete_producto(NULL);
   2.  ID Prod Negativo:     SELECT fun_delete_producto(-1);
   3.  ID Prod Cero:         SELECT fun_delete_producto(0);
   4.  ID Inexistente:       SELECT fun_delete_producto(99999);
   5.  Ya eliminado:         SELECT fun_delete_producto(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_producto(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_producto(2147483647);
   8.  Min Int Value:        SELECT fun_delete_producto(-2147483648);
   9.  SQL Inyection:        SELECT fun_delete_producto(1 OR 1=1);
   10. CASO EXITOSO:         SELECT fun_delete_producto(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_producto(jid_producto tab_productos.id_producto%TYPE)
                                               RETURNS BOOLEAN AS
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_producto IS NULL THEN
            RAISE NOTICE 'Error: ID de producto nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_producto <= 0 THEN
            RAISE NOTICE 'Error: ID de producto inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_productos WHERE id_producto = jid_producto;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Producto con ID % no encontrado.', jid_producto;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El Producto con ID % ya fue eliminado anteriormente.', jid_producto;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_productos SET user_delete = CURRENT_USER,
                                 fec_delete = CURRENT_TIMESTAMP,
                                 ind_vivo = FALSE
                                 Where id_producto = jid_producto;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el Producto con ID %.', jid_producto;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Producto con ID % eliminado exitosamente.', jid_producto;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
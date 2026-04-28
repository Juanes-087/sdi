/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Kardex Nulo:       SELECT fun_delete_kardex_productos(NULL);
   2.  ID Kardex Negativo:   SELECT fun_delete_kardex_productos(-1);
   3.  ID Kardex Cero:       SELECT fun_delete_kardex_productos(0);
   4.  ID Inexistente:       SELECT fun_delete_kardex_productos(99999);
   5.  Ya eliminado:         SELECT fun_delete_kardex_productos(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_kardex_productos(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_kardex_productos(2147483647);
   8.  Min Int Value:        SELECT fun_delete_kardex_productos(-2147483648);
   9.  Float Cast:           SELECT fun_delete_kardex_productos(1.99::INT);
   10. CASO EXITOSO:         SELECT fun_delete_kardex_productos(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_kardex_productos(jid_kardex_producto tab_kardex_productos.id_kardex_producto%TYPE) 
                                                       RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_kardex_producto IS NULL THEN
            RAISE NOTICE 'Error: El ID del kardex de producto es obligatorio.';
            RETURN FALSE;
        END IF;

        IF jid_kardex_producto <= 0 THEN
            RAISE NOTICE 'Error: El ID del kardex de producto debe ser mayor a 0.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_kardex_productos WHERE id_kardex_producto = jid_kardex_producto;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Registro de Kardex de producto con ID % no encontrado.', jid_kardex_producto;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El registro de Kardex de producto con ID % ya fue eliminado anteriormente.', jid_kardex_producto;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_kardex_productos SET user_delete = CURRENT_USER,
                                        fec_delete = CURRENT_TIMESTAMP,
                                        ind_vivo = FALSE
                                        Where id_kardex_producto = jid_kardex_producto;

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el registro del kardex de productos con ID %.', jid_kardex_producto;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Registro de Kardex de producto con ID % eliminado exitosamente.', jid_kardex_producto;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;

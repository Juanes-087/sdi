/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Kardex Nulo:       SELECT fun_delete_kardex_mat_prima(NULL);
   2.  ID Kardex Negativo:   SELECT fun_delete_kardex_mat_prima(-1);
   3.  ID Kardex Cero:       SELECT fun_delete_kardex_mat_prima(0);
   4.  ID Inexistente:       SELECT fun_delete_kardex_mat_prima(99999);
   5.  Ya eliminado:         SELECT fun_delete_kardex_mat_prima(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_kardex_mat_prima(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_kardex_mat_prima(2147483647);
   8.  Min Int Value:        SELECT fun_delete_kardex_mat_prima(-2147483648);
   9.  Float Cast:           SELECT fun_delete_kardex_mat_prima(99::FLOAT::INT);
   10. CASO EXITOSO:         SELECT fun_delete_kardex_mat_prima(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_kardex_mat_prima(jid_kardex tab_kardex_mat_prima.id_kardex_mat_prima%TYPE) 
                                                       RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_kardex IS NULL THEN
            RAISE NOTICE 'Error: El ID del kardex es obligatorio.';
            RETURN FALSE;
        END IF;

        IF jid_kardex <= 0 THEN
            RAISE NOTICE 'Error: El ID del kardex debe ser mayor a 0.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_kardex_mat_prima WHERE id_kardex_mat_prima = jid_kardex;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Registro de Kardex con ID % no encontrado.', jid_kardex;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El registro de Kardex con ID % ya fue eliminado anteriormente.', jid_kardex;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_kardex_mat_prima SET user_delete = CURRENT_USER,
                                        fec_delete = CURRENT_TIMESTAMP,
                                        ind_vivo = FALSE
                                        Where id_kardex_mat_prima = jid_kardex;

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el registro del kardex con ID %.', jid_kardex;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Registro de Kardex con ID % eliminado exitosamente.', jid_kardex;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;

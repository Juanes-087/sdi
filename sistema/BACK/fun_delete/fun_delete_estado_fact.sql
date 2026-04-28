/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Estado Nulo:       SELECT fun_delete_estado_fact(NULL);
   2.  ID Estado Negativo:   SELECT fun_delete_estado_fact(-1);
   3.  ID Estado Cero:       SELECT fun_delete_estado_fact(0);
   4.  ID Inexistente:       SELECT fun_delete_estado_fact(99999);
   5.  Ya eliminado:         SELECT fun_delete_estado_fact(2); -- Asumiendo ID 2 eliminado
   6.  Con Hijas (Facturas): SELECT fun_delete_estado_fact(1); -- Si hay facturas activas
   7.  Null Cast:            SELECT fun_delete_estado_fact(NULL::INT);
   8.  Max Int Value:        SELECT fun_delete_estado_fact(2147483647);
   9.  Min Int Value:        SELECT fun_delete_estado_fact(-2147483648);
   10. CASO EXITOSO:         SELECT fun_delete_estado_fact(3); -- Estado sin uso
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_estado_fact(jid_estado tab_estado_fact.id_estado_fact%TYPE) 
                                                  RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_estado IS NULL THEN
            RAISE NOTICE 'Error: El ID del estado de factura es obligatorio.';
            RETURN FALSE;
        END IF;

        IF jid_estado <= 0 THEN
            RAISE NOTICE 'Error: El ID del estado de factura debe ser mayor a 0.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_estado_fact WHERE id_estado_fact = jid_estado;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Estado de factura con ID % no encontrado.', jid_estado;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El estado de factura con ID % ya fue eliminado anteriormente.', jid_estado;
            RETURN FALSE;
        END IF;

    -- 3. Verificar Hijos (Integridad Referencial)
        IF EXISTS (Select 1 From tab_facturas Where id_estado_fact = jid_estado AND ind_vivo = TRUE) THEN
            RAISE NOTICE 'Error: No se puede eliminar, existen facturas activas con este estado (ID %).', jid_estado;
            RETURN FALSE;
        END IF;

    -- 4. Hacer el soft delete
        UPDATE tab_estado_fact SET user_delete = CURRENT_USER,
                                   fec_delete = CURRENT_TIMESTAMP,
                                   ind_vivo = FALSE
                                   Where id_estado_fact = jid_estado;

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el estado de factura con ID %.', jid_estado;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Estado de factura con ID % eliminado exitosamente.', jid_estado;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;

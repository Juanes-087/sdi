/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Cargo Nulo:        SELECT fun_delete_cargo(NULL);
   2.  ID Cargo Negativo:    SELECT fun_delete_cargo(-1);
   3.  ID Cargo Cero:        SELECT fun_delete_cargo(0);
   4.  ID Inexistente:       SELECT fun_delete_cargo(99999);
   5.  Ya eliminado:         SELECT fun_delete_cargo(2); -- Asumiendo ID 2 eliminado
   6.  Null Wrapper:         SELECT fun_delete_cargo(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_cargo(2147483647);
   8.  Min Int Value:        SELECT fun_delete_cargo(-2147483648);
   9.  Tipo Invalido:        -- SELECT fun_delete_cargo('texto'); (Fallará en llamada)
   10. CASO EXITOSO:         SELECT fun_delete_cargo(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_cargo(jid_cargo tab_cargos.id_cargo%TYPE) 
                                            RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_cargo IS NULL THEN
            RAISE NOTICE 'Error: ID de cargo nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_cargo <= 0 THEN
            RAISE NOTICE 'Error: ID de cargo inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_cargos WHERE id_cargo = jid_cargo;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Cargo con ID % no encontrado.', jid_cargo;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El Cargo con ID % ya fue eliminado anteriormente.', jid_cargo;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_cargos SET   user_delete = CURRENT_USER,
                                fec_delete = CURRENT_TIMESTAMP,
                                ind_vivo = FALSE
                                Where id_cargo = jid_cargo;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el Cargo con ID %.', jid_cargo;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Cargo con ID % eliminado exitosamente.', jid_cargo;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
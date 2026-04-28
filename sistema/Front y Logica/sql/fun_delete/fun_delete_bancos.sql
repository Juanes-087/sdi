/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Banco Nulo:        SELECT fun_delete_banco(NULL);
   2.  ID Banco Negativo:    SELECT fun_delete_banco(-1);
   3.  ID Banco Cero:        SELECT fun_delete_banco(0);
   4.  ID Inexistente:       SELECT fun_delete_banco(99999);
   5.  Ya eliminado:         SELECT fun_delete_banco(2); -- Asumiendo ID 2 eliminado
   6.  SQL Injection Sim:    SELECT fun_delete_banco(1 OR 1=1); -- Error de tipo, pero buena prueba conceptual
   7.  Null Wrapper:         SELECT fun_delete_banco(NULL::INT);
   8.  Max Int Value:        SELECT fun_delete_banco(2147483647);
   9.  Min Int Value:        SELECT fun_delete_banco(-2147483648);
   10. CASO EXITOSO:         SELECT fun_delete_banco(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_banco(jid_banco tab_bancos.id_banco%TYPE) 
                                            RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_banco IS NULL THEN
            RAISE NOTICE 'Error: ID de banco nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_banco <= 0 THEN
            RAISE NOTICE 'Error: ID de banco inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_bancos WHERE id_banco = jid_banco;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Banco con ID % no encontrado.', jid_banco;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El Banco con ID % ya fue eliminado anteriormente.', jid_banco;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_bancos SET   user_delete = CURRENT_USER,
                                fec_delete = CURRENT_TIMESTAMP,
                                ind_vivo = FALSE
                                Where id_banco = jid_banco;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el Banco con ID %.', jid_banco;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Banco con ID % eliminado exitosamente.', jid_banco;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
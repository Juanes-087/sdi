/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Doc Nulo:          SELECT fun_delete_tip_doc(NULL);
   2.  ID Doc Negativo:      SELECT fun_delete_tip_doc(-1);
   3.  ID Doc Cero:          SELECT fun_delete_tip_doc(0);
   4.  ID Inexistente:       SELECT fun_delete_tip_doc(99999);
   5.  Ya eliminado:         SELECT fun_delete_tip_doc(2); -- Asumiendo ID 2 eliminado
   6.  Null Cast:            SELECT fun_delete_tip_doc(NULL::INT);
   7.  Max Int Value:        SELECT fun_delete_tip_doc(2147483647);
   8.  Min Int Value:        SELECT fun_delete_tip_doc(-2147483648);
   9.  Float Cast:           SELECT fun_delete_tip_doc(2.0::INT);
   10. CASO EXITOSO:         SELECT fun_delete_tip_doc(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_tip_doc(jid_documento tab_tipo_documentos.id_documento%TYPE)
                                              RETURNS BOOLEAN AS
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_documento IS NULL THEN
            RAISE NOTICE 'Error: ID de documento nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_documento <= 0 THEN
            RAISE NOTICE 'Error: ID de documento inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_tipo_documentos WHERE id_documento = jid_documento;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Tipo de Documento con ID % no encontrado.', jid_documento;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El Tipo de Documento con ID % ya fue eliminado anteriormente.', jid_documento;
            RETURN FALSE;
        END IF;

    -- 3. Hacer el soft delete
        UPDATE tab_tipo_documentos SET      user_delete = CURRENT_USER,
                                            fec_delete = CURRENT_TIMESTAMP,
                                            ind_vivo = FALSE
                                            Where id_documento = jid_documento;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el Tipo de Documento con ID %.', jid_documento;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Tipo de Documento con ID % eliminado exitosamente.', jid_documento;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
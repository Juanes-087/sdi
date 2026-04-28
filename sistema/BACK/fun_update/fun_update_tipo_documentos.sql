/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID TipoDoc Nulo:      SELECT fun_update_tipo_documentos(NULL, 'Nom');
   2.  ID TipoDoc Negativo:  SELECT fun_update_tipo_documentos(-1, 'Nom');
   3.  Nombre Vacío:         SELECT fun_update_tipo_documentos(1, '');
   4.  Nombre Espacios:      SELECT fun_update_tipo_documentos(1, '   ');
   5.  SQL Inj (Nom):        SELECT fun_update_tipo_documentos(1, '''; DROP TABLE tab_tipo_doc; --');
   6.  ID Inexistente (999): SELECT fun_update_tipo_documentos(99999, 'Nom');
   7.  Soft Deleted:         SELECT fun_update_tipo_documentos(2, 'Nom');
   8.  Nombre NULL:          SELECT fun_update_tipo_documentos(1, NULL);
   9.  ID Cero:              SELECT fun_update_tipo_documentos(0, 'Nom');
   10. CASO EXITOSO:         SELECT fun_update_tipo_documentos(1, 'Cédula de Extranjería');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_tipo_documentos   (jid_documento tab_tipo_documentos.id_documento%TYPE,
                                                        jnom_tipo_docum tab_tipo_documentos.nom_tipo_docum%TYPE)
                                                        RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_documento IS NULL OR jid_documento <= 0 THEN
            RAISE NOTICE 'Error: ID de tipo de documento inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado check
        SELECT ind_vivo INTO j_ind_vivo FROM tab_tipo_documentos WHERE id_documento = jid_documento;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Tipo de Documento con ID % no encontrado.', jid_documento;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Tipo de Documento con ID % se encuentra eliminado. No se puede actualizar.', jid_documento;
            RETURN FALSE;
        END IF;

    -- Validar Nombre
        IF jnom_tipo_docum IS NULL OR TRIM(jnom_tipo_docum) = '' THEN
            RAISE NOTICE 'Error: El nombre del tipo de documento no puede estar vacío.';
            RETURN FALSE;
        END IF;

    -- Actualizar
        UPDATE tab_tipo_documentos 
        SET nom_tipo_docum = jnom_tipo_docum 
        WHERE id_documento = jid_documento;
        
        RAISE NOTICE 'Tipo de Documento actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Reg Nulo:          SELECT fun_update_instrumentos_kit(NULL, 1, 1, 1);
   2.  ID Reg Negativo:      SELECT fun_update_instrumentos_kit(-1, 1, 1, 1);
   3.  ID Kit Nulo:          SELECT fun_update_instrumentos_kit(1, NULL, 1, 1);
   4.  ID Inst Nulo:         SELECT fun_update_instrumentos_kit(1, 1, NULL, 1);
   5.  Cant Negativa:        SELECT fun_update_instrumentos_kit(1, 1, 1, -1);
   6.  Cant Cero:            SELECT fun_update_instrumentos_kit(1, 1, 1, 0);
   7.  Cant Excesiva(11):    SELECT fun_update_instrumentos_kit(1, 1, 1, 11);
   8.  ID Reg Inexistente:   SELECT fun_update_instrumentos_kit(99999, 1, 1, 1);
   9.  ID Kit Inex:          SELECT fun_update_instrumentos_kit(1, 999, 1, 1);
   10. CASO EXITOSO:         SELECT fun_update_instrumentos_kit(1, 1, 1, 2);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_instrumentos_kit  (jid_instrumento_kit tab_instrumentos_kit.id_instrumento_kit%TYPE,
                                                        jid_kit tab_instrumentos_kit.id_kit%TYPE,
                                                        jid_instrumento tab_instrumentos_kit.id_instrumento%TYPE,
                                                        jcant_instrumento tab_instrumentos_kit.cant_instrumento%TYPE)
                                                        RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
BEGIN
    -- Validar ID Principal
        IF jid_instrumento_kit IS NULL OR jid_instrumento_kit <= 0 THEN 
            RAISE NOTICE 'Error: ID Registro inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_instrumentos_kit WHERE id_instrumento_kit = jid_instrumento_kit;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Registro con ID % no encontrado.', jid_instrumento_kit;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El registro con ID % se encuentra eliminado. No se puede actualizar.', jid_instrumento_kit;
            RETURN FALSE;
        END IF;

    -- Validar FK Kit
        IF jid_kit IS NULL OR jid_kit <= 0 THEN 
            RAISE NOTICE 'Error: ID Kit inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_kits WHERE id_kit = jid_kit;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Kit no existe o inactivo.'; 
            RETURN FALSE; 
        END IF;
        
    -- Validar FK Instrumento
        IF jid_instrumento IS NULL OR jid_instrumento <= 0 THEN 
            RAISE NOTICE 'Error: ID Instrumento inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_instrumentos WHERE id_instrumento = jid_instrumento;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Instrumento no existe o inactivo.'; 
            RETURN FALSE; 
        END IF;

    -- Validar Cantidad
        IF jcant_instrumento <= 0 OR jcant_instrumento > 10 THEN 
            RAISE NOTICE 'Error: Cantidad de instrumento inválida (Debe ser entre 1 y 10).'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
        UPDATE tab_instrumentos_kit SET
            id_kit = jid_kit,
            id_instrumento = jid_instrumento,
            cant_instrumento = jcant_instrumento
        WHERE id_instrumento_kit = jid_instrumento_kit;
        
        RAISE NOTICE 'Registro actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Dept Nulo:         SELECT fun_delete_departamento(NULL);
   2.  ID Dept Negativo:     SELECT fun_delete_departamento(-1);
   3.  ID Dept Cero:         SELECT fun_delete_departamento(0);
   4.  ID Inexistente:       SELECT fun_delete_departamento(99999);
   5.  Ya eliminado:         SELECT fun_delete_departamento(2); -- Asumiendo ID 2 eliminado
   6.  Con Ciudades (Error): SELECT fun_delete_departamento(3); -- Si tiene ciudades hijas
   7.  CASO EXITOSO:         SELECT fun_delete_departamento(1);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_delete_departamento(jid_depart tab_departamentos.id_depart%TYPE) 
                                                   RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validaciones
        IF jid_depart IS NULL THEN
            RAISE NOTICE 'Error: ID de departamento nulo.';
            RETURN FALSE;
        END IF;
        
        IF jid_depart <= 0 THEN
            RAISE NOTICE 'Error: ID de departamento inválido.';
            RETURN FALSE;
        END IF;

    -- Optimización: Obtener estado en una sola consulta
        SELECT ind_vivo INTO j_ind_vivo FROM tab_departamentos WHERE id_depart = jid_depart;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Departamento con ID % no encontrado.', jid_depart;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Aviso: El Departamento con ID % ya fue eliminado anteriormente.', jid_depart;
            RETURN FALSE;
        END IF;

    -- 3. Verificar Hijos (Integridad Referencial)
        IF EXISTS (Select 1 From tab_ciudades Where id_depart = jid_depart AND ind_vivo = TRUE) THEN
            RAISE NOTICE 'Error: No se puede eliminar, existen ciudades asociadas a este departamento (ID %).', jid_depart;
            RETURN FALSE;
        END IF;

    -- 4. Hacer el soft delete
        UPDATE tab_departamentos SET user_delete = CURRENT_USER,
                                     fec_delete = CURRENT_TIMESTAMP,
                                     ind_vivo = FALSE
                                     Where id_depart = jid_depart;                                        

    -- Verificar que se actualizó
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: No se pudo eliminar el Departamento con ID %.', jid_depart;
            RETURN FALSE;
        ELSE
            RAISE NOTICE 'Departamento con ID % eliminado exitosamente.', jid_depart;
            RETURN TRUE;
        END IF;   

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
LANGUAGE plpgsql;
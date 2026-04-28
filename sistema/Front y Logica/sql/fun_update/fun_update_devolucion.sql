/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Factura Nulo:      SELECT fun_update_devolucion(NULL, 'Obs');
   2.  ID Factura Negativo:  SELECT fun_update_devolucion(-1, 'Obs');
   3.  Obs Vacía:            SELECT fun_update_devolucion(1, '');
   4.  Obs Solo Espacios:    SELECT fun_update_devolucion(1, '   ');
   5.  SQL Inj (Obs):        SELECT fun_update_devolucion(1, '''; DROP TABLE tab_dev; --');
   6.  ID Inexistente (999): SELECT fun_update_devolucion(99999, 'Obs');
   7.  Soft Deleted (ID 2):  SELECT fun_update_devolucion(2, 'Obs');
   8.  Obs NULL:             SELECT fun_update_devolucion(1, NULL);
   9.  ID Cero:              SELECT fun_update_devolucion(0, 'Obs');
   10. CASO EXITOSO:         SELECT fun_update_devolucion(1, 'Cliente satisfecho con cambio.');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_devolucion(jid_factura tab_dev.id_factura%TYPE,
                                                jind_observaciones tab_dev.ind_observaciones%TYPE)
                                                RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
BEGIN
    -- Validar ID (Es PK y FK a la vez)
        IF jid_factura <= 0 THEN 
            RAISE NOTICE 'Error: ID Factura inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_dev WHERE id_factura = jid_factura;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Registro de devolución con ID % no encontrado.', jid_factura;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: La devolución con ID % se encuentra eliminada. No se puede actualizar.', jid_factura;
            RETURN FALSE;
        END IF;

    -- Validar Contenido
        IF jind_observaciones IS NULL OR TRIM(jind_observaciones)='' THEN 
            RAISE NOTICE 'Error: Observaciones no pueden estar vacías.'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
        UPDATE tab_dev 
        SET ind_observaciones = jind_observaciones 
        WHERE id_factura = jid_factura;
        
        RAISE NOTICE 'Devolución actualizada exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

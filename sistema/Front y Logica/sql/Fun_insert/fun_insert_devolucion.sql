/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Factura Nulo:      SELECT fun_insert_devolucion(NULL, 'Obs');
   2.  ID Factura Negativo:  SELECT fun_insert_devolucion(-1, 'Obs');
   3.  Obs Vacía:            SELECT fun_insert_devolucion(1, '');
   4.  Obs Solo Espacios:    SELECT fun_insert_devolucion(1, '   ');
   5.  Factura No Existe:    SELECT fun_insert_devolucion(99999, 'Obs');
   6.  Ya Existe Devolución: SELECT fun_insert_devolucion(1, 'Obs'); -- Si ya hay registro
   7.  CASO EXITOSO:         SELECT fun_insert_devolucion(1, 'Producto defectuoso.');
   -----------------------------------------------------------------------------
*/

drop function if exists fun_insert_devolucion();

CREATE OR REPLACE FUNCTION fun_insert_devolucion (jid_factura tab_dev.id_factura%TYPE,
                                                  jobservaciones tab_dev.ind_observaciones%TYPE DEFAULT 'N/A') 
                                                  RETURNS BOOLEAN AS
$$
    DECLARE j_check_val INTEGER;
            j_ind_vivo BOOLEAN;

    BEGIN
    -- Validaciones FK
        IF jid_factura IS NULL OR jid_factura <= 0 THEN
            RAISE NOTICE 'Error: ID Factura inválido.';
            RETURN FALSE;
        END IF;

        SELECT ind_vivo INTO j_ind_vivo FROM tab_facturas WHERE id_factura = jid_factura;
        
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: La factura no existe.';
            RETURN FALSE;
        END IF;

        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: La factura está eliminada.';
            RETURN FALSE;
        END IF;

    -- Validaciones Texto
        IF jobservaciones IS NULL OR TRIM(jobservaciones) = '' THEN 
            RAISE NOTICE 'Error: Observaciones vacías.'; 
            RETURN FALSE; 
        END IF;

    -- Validar Duplicidad (1 a 1)
        PERFORM 1 FROM tab_dev WHERE id_factura = jid_factura;
        IF FOUND THEN
            RAISE NOTICE 'Error: Ya existe una devolución para esta factura.';
            RETURN FALSE;
        END IF;

    -- Insertar
        INSERT INTO tab_dev (id_factura, ind_observaciones) 
        VALUES (jid_factura, TRIM(jobservaciones));

        RAISE NOTICE 'Devolución registrada exitosamente para Factura %.', jid_factura;
        RETURN TRUE;

    EXCEPTION
        WHEN unique_violation THEN 
            RAISE NOTICE 'Error: Ya existe una devolución para esta factura.'; 
            RETURN FALSE;
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'Error: Referencia inválida a factura.';
            RETURN FALSE;
        WHEN OTHERS THEN 
            RAISE NOTICE 'Error inesperado: %', SQLERRM; 
            RETURN FALSE;
    END;
$$ 
LANGUAGE plpgsql;

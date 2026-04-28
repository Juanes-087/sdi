/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Kardex Nulo:       SELECT fun_update_kardex_productos(NULL, 1, NULL, 1, 5, NOW(), 'Obs');
   2.  ID Kardex Neg:        SELECT fun_update_kardex_productos(-1, 1, NULL, 1, 5, NOW(), 'Obs');
   3.  Inst & Kit Nulos:     SELECT fun_update_kardex_productos(1, NULL, NULL, 1, 5, NOW(), 'Obs');
   4.  Inst & Kit Set:       SELECT fun_update_kardex_productos(1, 1, 1, 1, 5, NOW(), 'Obs');
   5.  Inst Inexistente:     SELECT fun_update_kardex_productos(1, 99999, NULL, 1, 5, NOW(), 'Obs');
   6.  Kit Inexistente:      SELECT fun_update_kardex_productos(1, NULL, 99999, 1, 5, NOW(), 'Obs');
   7.  Tipo Mov Inv (5):     SELECT fun_update_kardex_productos(1, 1, NULL, 5, 5, NOW(), 'Obs');
   8.  Cantidad Negativa:    SELECT fun_update_kardex_productos(1, 1, NULL, 1, -5, NOW(), 'Obs');
   9.  Fecha Nula:           SELECT fun_update_kardex_productos(1, 1, NULL, 1, 5, NULL, 'Obs');
   10. CASO EXITOSO:         SELECT fun_update_kardex_productos(1, 1, NULL, 2, 10, CURRENT_TIMESTAMP, 'Reposición');
   -----------------------------------------------------------------------------
*/

drop function if exists fun_update_kardex_productos();

CREATE OR REPLACE FUNCTION fun_update_kardex_productos  (jid_kardex_producto tab_kardex_productos.id_kardex_producto%TYPE,
                                                        jid_instrumento tab_kardex_productos.id_instrumento%TYPE,
                                                        jid_kit tab_kardex_productos.id_kit%TYPE,
                                                        jtipo_movimiento tab_kardex_productos.tipo_movimiento%TYPE,
                                                        jcantidad tab_kardex_productos.cantidad%TYPE,
                                                        jfecha_movimiento tab_kardex_productos.fecha_movimiento%TYPE,
                                                        jobservaciones tab_kardex_productos.observaciones%TYPE DEFAULT 'N/A')
                                                        RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_kardex_producto IS NULL OR jid_kardex_producto <= 0 THEN 
            RAISE NOTICE 'Error: ID Kardex inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_kardex_productos WHERE id_kardex_producto = jid_kardex_producto;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Kardex Producto con ID % no encontrado.', jid_kardex_producto;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Kardex Producto con ID % se encuentra eliminado. No se puede actualizar.', jid_kardex_producto;
            RETURN FALSE;
        END IF;

    -- Validar XOR (Instrumento o Kit)
        IF (jid_instrumento IS NOT NULL AND jid_kit IS NOT NULL) THEN
            RAISE NOTICE 'Error: No puede ser Instrumento Y Kit a la vez.';
            RETURN FALSE;
        END IF;

        IF (jid_instrumento IS NULL AND jid_kit IS NULL) THEN
            RAISE NOTICE 'Error: Debe especificar Instrumento O Kit.';
            RETURN FALSE;
        END IF;

    -- Validar FKs
        IF jid_instrumento IS NOT NULL THEN
            IF jid_instrumento <= 0 THEN 
                RAISE NOTICE 'Error: ID Instrumento inválido.'; 
                RETURN FALSE; 
            END IF;

            SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_instrumentos WHERE id_instrumento = jid_instrumento;
            
            IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
                RAISE NOTICE 'Error: Instrumento no existe o inactivo.'; 
                RETURN FALSE; 
            END IF;
        END IF;

        IF jid_kit IS NOT NULL THEN
            IF jid_kit <= 0 THEN 
                RAISE NOTICE 'Error: ID Kit inválido.'; 
                RETURN FALSE; 
            END IF;
            
            SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_kits WHERE id_kit = jid_kit;
            
            IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
                RAISE NOTICE 'Error: Kit no existe o inactivo.'; 
                RETURN FALSE; 
            END IF;
        END IF;

    -- Validaciones Logicas
        IF jtipo_movimiento <= 0 OR jtipo_movimiento > 4 THEN 
            RAISE NOTICE 'Error: Tipo Movimiento fuera de rango (1-4).'; 
            RETURN FALSE; 
        END IF;

        IF jcantidad <= 0 THEN 
            RAISE NOTICE 'Error: La cantidad debe ser positiva.'; 
            RETURN FALSE; 
        END IF;

        IF jfecha_movimiento IS NULL THEN 
            RAISE NOTICE 'Error: Fecha movimiento no puede ser nula.'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
        UPDATE tab_kardex_productos SET
            id_instrumento = jid_instrumento,
            id_kit = jid_kit,
            tipo_movimiento = jtipo_movimiento,
            cantidad = jcantidad,
            fecha_movimiento = jfecha_movimiento,
            observaciones = jobservaciones
        WHERE id_kardex_producto = jid_kardex_producto;
        
        RAISE NOTICE 'Kardex Productos actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

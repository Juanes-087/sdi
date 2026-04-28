/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Prod Nulo:         SELECT fun_update_producto(NULL, 1, 1, 'Prod', 100);
   2.  ID Prod Negativo:     SELECT fun_update_producto(-1, 1, 1, 'Prod', 100);
   3.  Inst & Kit Nulos:     SELECT fun_update_producto(1, NULL, NULL, 'Prod', 100);
   4.  Inst & Kit Set:       SELECT fun_update_producto(1, 1, 1, 'Prod', 100);
   5.  Nombre Corto:         SELECT fun_update_producto(1, 1, NULL, 'P', 100);
   6.  Precio Negativo:      SELECT fun_update_producto(1, 1, NULL, 'Prod', -100);
   7.  Inst Inexistente:     SELECT fun_update_producto(1, 99999, NULL, 'Prod', 100);
   8.  Kit Inexistente:      SELECT fun_update_producto(1, NULL, 99999, 'Prod', 100);
   9.  Soft Deleted:         SELECT fun_update_producto(2, 1, NULL, 'Prod', 100);
   10. CASO EXITOSO:         SELECT fun_update_producto(1, 1, NULL, 'Venta Bisturí Premium', 150000);
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_producto  (jid_producto tab_productos.id_producto%TYPE,
                                                jid_instrumento tab_productos.id_instrumento%TYPE,
                                                jid_kit tab_productos.id_kit%TYPE,
                                                jnombre_producto tab_productos.nombre_producto%TYPE,
                                                jprecio_producto tab_productos.precio_producto%TYPE,
                                                jimg_url tab_productos.img_url%TYPE)
                                                RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_producto IS NULL OR jid_producto <= 0 THEN 
            RAISE NOTICE 'Error: ID Producto inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_productos WHERE id_producto = jid_producto;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Producto con ID % no encontrado.', jid_producto;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El Producto con ID % se encuentra eliminado. No se puede actualizar.', jid_producto;
            RETURN FALSE;
        END IF;

    -- Validar Exclusividad (XOR)
        IF (jid_instrumento IS NOT NULL AND jid_kit IS NOT NULL) THEN
            RAISE NOTICE 'Error: No puede relacionar un Instrumento Y un Kit al mismo tiempo.';
            RETURN FALSE;
        END IF;

        IF (jid_instrumento IS NULL AND jid_kit IS NULL) THEN
            RAISE NOTICE 'Error: Debe relacionar un Instrumento O un Kit.';
            RETURN FALSE;
        END IF;

    -- Validar FKs (Solo la que no sea nula)
        IF jid_instrumento IS NOT NULL THEN
            IF jid_instrumento <= 0 THEN 
                RAISE NOTICE 'Error: ID Instrumento inválido.'; 
                RETURN FALSE; 
            END IF;

            SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_instrumentos WHERE id_instrumento = jid_instrumento;
            
            IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
                RAISE NOTICE 'Error: El Instrumento no existe o está inactivo.'; 
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
                RAISE NOTICE 'Error: El Kit no existe o está inactivo.'; 
                RETURN FALSE; 
            END IF;
        END IF;

    -- Validar Nombre
        IF jnombre_producto IS NULL OR LENGTH(TRIM(jnombre_producto)) < 4 THEN 
            RAISE NOTICE 'Error: Nombre del producto inválido (Mínimo 4 caracteres).'; 
            RETURN FALSE; 
        END IF;

    -- Validar URL
        IF jimg_url IS NULL OR TRIM(jimg_url) = '' THEN
            RAISE NOTICE 'Error: URL de imagen obligatoria.';
            RETURN FALSE;
        END IF;

    -- Validar Precio
        IF jprecio_producto < 0 THEN 
            RAISE NOTICE 'Error: El precio no puede ser negativo.'; 
            RETURN FALSE; 
        END IF;

    -- Actualizar
        UPDATE tab_productos SET
            id_instrumento = jid_instrumento,
            id_kit = jid_kit,
            nombre_producto = jnombre_producto,
            precio_producto = jprecio_producto,
            img_url = TRIM(jimg_url)
        WHERE id_producto = jid_producto;
        
        RAISE NOTICE 'Producto actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

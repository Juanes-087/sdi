/*
    -----------------------------------------------------------------------------
    PRUEBAS DE VALIDACIÓN
    -----------------------------------------------------------------------------
    1. Insertar Producto tipo Instrumento:
       SELECT fun_insert_producto(1, NULL, 'Martillo Qx', 50000);

    2. Insertar Producto tipo Kit:
       SELECT fun_insert_producto(NULL, 1, 'Kit Básico', 150000);

    3. Error: Ambos IDs nulos o ambos presentes:
       SELECT fun_insert_producto(1, 1, 'Error Dual', 100);
    -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_insert_producto  (jid_instrumento tab_productos.id_instrumento%TYPE,
                                                jid_kit tab_productos.id_kit%TYPE,
                                                jnom_produc tab_productos.nombre_producto%TYPE,
                                                jprecio tab_productos.precio_producto%TYPE,
                                                jimg_url tab_productos.img_url%TYPE
) RETURNS BOOLEAN AS
$$
    DECLARE     
        nuevo_id tab_productos.id_producto%TYPE;
        j_check_val INTEGER;
    BEGIN
        -- Validar integridad Exclusiva (XOR)
            IF (jid_instrumento IS NOT NULL AND jid_kit IS NOT NULL) OR 
               (jid_instrumento IS NULL AND jid_kit IS NULL) THEN
                RAISE NOTICE 'Error: Debe especificar ID Instrumento O ID Kit, pero no ambos ni ninguno.';
                RETURN FALSE;
            END IF;

        -- Validar Existencia de FK
            IF jid_instrumento IS NOT NULL THEN
                SELECT 1 INTO j_check_val FROM tab_instrumentos WHERE id_instrumento = jid_instrumento;
                IF NOT FOUND THEN 
                    RAISE NOTICE 'Error: Instrumento con ID % no existe.', jid_instrumento; 
                    RETURN FALSE; 
                END IF;
            END IF;

            IF jid_kit IS NOT NULL THEN
                SELECT 1 INTO j_check_val FROM tab_kits WHERE id_kit = jid_kit;
                IF NOT FOUND THEN 
                    RAISE NOTICE 'Error: Kit con ID % no existe.', jid_kit; 
                    RETURN FALSE; 
                END IF;
            END IF;

        -- Validar Campos de Texto
            IF jnom_produc IS NULL OR TRIM(jnom_produc) = '' THEN
                RAISE NOTICE 'Error: Nombre obligatorio.';
                RETURN FALSE;
            END IF;
            
            IF LENGTH(TRIM(jnom_produc)) < 3 THEN
                 RAISE NOTICE 'Error: Nombre muy corto.';
                 RETURN FALSE;
            END IF;

            -- Validar Imagen
            IF jimg_url IS NULL OR TRIM(jimg_url) = '' THEN
                RAISE NOTICE 'Error: URL de imagen obligatoria.';
                RETURN FALSE;
            END IF;

        -- Validar Precio
            IF jprecio IS NULL THEN
                RAISE NOTICE 'Error: El precio no puede ser nulo.';
                RETURN FALSE;
            END IF;

            IF jprecio <= 0 THEN
                RAISE NOTICE 'Error: El precio debe ser mayor a 0.';
                RETURN FALSE;
            END IF;

        -- Generar ID
            SELECT COALESCE(MAX(id_producto),0)+1 INTO nuevo_id FROM tab_productos;

        -- Insertar
            INSERT INTO tab_productos (
                id_producto, id_instrumento, id_kit, nombre_producto, precio_producto, img_url
            ) VALUES (
                nuevo_id, jid_instrumento, jid_kit, TRIM(jnom_produc), jprecio, TRIM(jimg_url)
            );

            RAISE NOTICE 'Producto % creado exitosamente.', nuevo_id;
            RETURN TRUE;

    EXCEPTION 
        WHEN unique_violation THEN
            RAISE NOTICE 'Error: Producto duplicado.';
            RETURN FALSE;
        WHEN check_violation THEN
            RAISE NOTICE 'Error: Violación de restricción (Check IDs).';
            RETURN FALSE;
        WHEN OTHERS THEN 
            RAISE NOTICE 'Error inesperado: %', SQLERRM;
            RETURN FALSE;
    END;
$$ LANGUAGE plpgsql;

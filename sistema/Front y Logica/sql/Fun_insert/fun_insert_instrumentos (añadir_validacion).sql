/*

    Hola juan, falta añadir validaciones
    
    -----------------------------------------------------------------------------
    PRUEBAS DE VALIDACIÓN
    -----------------------------------------------------------------------------
    1. Insertar Instrumento Válido:
       SELECT fun_insert_instrumentos(1, 'Espejo Bucal', 100, 15000, 
                                      123, 'INV-2024', 1, 'Acero Inoxidable', 'http://img.com/espejo.jpg', 
                                      10, 200);

    2. Insertar con Backorder (Stock Min/Max Null):
       SELECT fun_insert_instrumentos(1, 'Sonda', 50, 25000, 
                                      NULL, 'INV-2025', NULL, 'Metal', 'http://img.com/sonda.jpg');
    -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_insert_instrumentos(jid_especializacion tab_instrumentos.id_especializacion%TYPE,
                                                   jnom_instru tab_instrumentos.nom_instrumento%TYPE,
                                                   jcant_disp tab_instrumentos.cant_disp%TYPE,
                                                   jlote tab_instrumentos.lote%TYPE,
                                                   jnumeral tab_instrumentos.numeral_en_kit%TYPE,
                                                   jtipo_mat tab_instrumentos.tipo_mat%TYPE,
                                                   jimg_url tab_instrumentos.img_url%TYPE,
                                                   jstock_min tab_instrumentos.stock_min%TYPE DEFAULT NULL,
                                                   jstock_max tab_instrumentos.stock_max%TYPE DEFAULT NULL
                                                   ) RETURNS BOOLEAN AS
$$
    DECLARE 
        jid_nuevo tab_instrumentos.id_instrumento%TYPE;
    BEGIN
        -- 1. Validaciones FK
            IF jid_especializacion IS NULL OR jid_especializacion <= 0 THEN
                RAISE EXCEPTION 'Error: Especialización inválida.';
            END IF;

            IF NOT EXISTS (SELECT 1 FROM tab_tipo_especializacion WHERE id_especializacion = jid_especializacion) THEN
                RAISE EXCEPTION 'Error: La especialización no existe.';
            END IF;

        -- 2. Validaciones Texto Obligatorias
            IF jnom_instru IS NULL OR TRIM(jnom_instru) = '' THEN 
                RAISE EXCEPTION 'Error: Nombre de instrumento vacío.'; 
            END IF;

            IF LENGTH(TRIM(jnom_instru)) < 3 THEN
                 RAISE EXCEPTION 'Error: Nombre de instrumento muy corto.';
            END IF;

            IF jtipo_mat IS NULL OR jtipo_mat NOT IN (1, 2) THEN
                RAISE EXCEPTION 'Error: Tipo de material inválido (1=Specialized/Acero, 2=Special/Aluminio).';
            END IF;

            IF jimg_url IS NULL OR TRIM(jimg_url) = '' THEN
                RAISE EXCEPTION 'Error: URL de imagen es obligatoria.';
            END IF;

        -- 3. Validaciones Numéricas
            -- Cantidad
            IF jcant_disp IS NULL THEN
                RAISE EXCEPTION 'Error: Cantidad disponible no puede ser nula.';
            END IF;

            -- Stocks (Opcionales, pero si vienen, positivos)
            IF jstock_min IS NOT NULL AND jstock_min < 0 THEN
                RAISE EXCEPTION 'Error: Stock mínimo no puede ser negativo.';
            END IF;
            
            IF jstock_max IS NOT NULL AND jstock_max < 0 THEN
                 RAISE EXCEPTION 'Error: Stock máximo no puede ser negativo.';
            END IF;

        -- 4. Generar ID
            SELECT COALESCE(MAX(id_instrumento), 0) + 1 INTO jid_nuevo FROM tab_instrumentos;

        -- 5. Insertar
            INSERT INTO tab_instrumentos (
                id_instrumento, id_especializacion, nom_instrumento, lote, cant_disp, 
                numeral_en_kit, tipo_mat, img_url, stock_min, stock_max
            ) VALUES (
                jid_nuevo, jid_especializacion, TRIM(jnom_instru), COALESCE(jlote, 0), jcant_disp,
                COALESCE(jnumeral, 0), jtipo_mat, TRIM(jimg_url), COALESCE(jstock_min, 0), COALESCE(jstock_max, 0)
            );

            RAISE NOTICE 'Instrumento % registrado exitosamente.', jid_nuevo;

            -- Automatización: Registrar en historial de fabricación si hay stock inicial
            IF jcant_disp > 0 THEN
                PERFORM fun_kardex_productos(1, jid_nuevo, 1, jcant_disp, 'Carga inicial por creación');
            END IF;

            RETURN TRUE;

    EXCEPTION
        WHEN unique_violation THEN 
            RAISE EXCEPTION 'Error: Violación de unicidad (Lote duplicado?).'; 
        WHEN foreign_key_violation THEN
            RAISE EXCEPTION 'Error: Referencia inválida.';
        WHEN OTHERS THEN 
            RAISE EXCEPTION 'Error inesperado: %', SQLERRM; 
    END;
$$ LANGUAGE plpgsql;

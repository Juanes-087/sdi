CREATE OR REPLACE FUNCTION fun_insert_kits (jid_especializacion tab_kits.id_especializacion%TYPE,
                                            jnom_kit tab_kits.nom_kit%TYPE,
                                            jcant_disp tab_kits.cant_disp%TYPE,
                                            jtipo_mat tab_kits.tipo_mat%TYPE,
                                            jstock_min tab_kits.stock_min%TYPE DEFAULT 0,
                                            jstock_max tab_kits.stock_max%TYPE DEFAULT 0,
                                            jimg_url tab_kits.img_url%TYPE DEFAULT '',
                                            jinstruments INTEGER[] DEFAULT '{}') 
                                            RETURNS BOOLEAN AS
$$
    DECLARE jid_nuevo tab_kits.id_kit%TYPE;
            j_check_val INTEGER;
            j_inst_id INTEGER;

BEGIN
    -- 1. VALIDACIONES BÁSICAS
    -- Primero revisamos que nos hayan mandado una especialización válida
    IF jid_especializacion IS NULL OR jid_especializacion <= 0 THEN
        RAISE EXCEPTION 'Error: Debes seleccionar una especialización válida.';
    END IF;

    -- Verificamos si esa especialización existe realmente en la tabla
    IF NOT EXISTS (SELECT 1 FROM tab_tipo_especializacion WHERE id_especializacion = jid_especializacion) THEN
        RAISE EXCEPTION 'Error: La especialización indicada no existe en el sistema.';
    END IF;

    -- 2. VALIDACIONES DE TEXTO
    -- Que no nos manden el nombre vacío
    IF jnom_kit IS NULL OR TRIM(jnom_kit) = '' THEN 
        RAISE EXCEPTION 'Error: El nombre del Kit es obligatorio.'; 
    END IF;

    -- Que tenga al menos 3 letras para que sea un nombre real
    IF LENGTH(TRIM(jnom_kit)) < 3 THEN 
        RAISE EXCEPTION 'Error: El nombre es muy corto, usa al menos 3 letras.'; 
    END IF;

    -- Revisamos que no tenga caracteres raros (permitimos letras, números, puntos, comas, etc.)
    IF jnom_kit !~ '^[a-zA-Z0-9ñÑáéíóúÁÉÍÓÚ\s\.\-\(\)\,\:\;\#]+$' THEN 
        RAISE EXCEPTION 'Error: El nombre tiene caracteres extraños no permitidos.'; 
    END IF;

    -- 3. VALIDACIONES NUMÉRICAS
    -- La cantidad no puede ser negativa
    IF jcant_disp IS NULL OR jcant_disp < 0 THEN 
        RAISE EXCEPTION 'Error: La cantidad disponible no puede ser menor a cero.'; 
    END IF;

    -- Los stocks tampoco pueden ser negativos
    IF jstock_min < 0 OR jstock_max < 0 THEN
        RAISE EXCEPTION 'Error: Los valores de stock no pueden ser negativos.'; 
    END IF;

    -- Validar tipo de material (1=Specialized/Acero, 2=Special/Aluminio)
    IF jtipo_mat IS NULL OR jtipo_mat NOT IN (1, 2) THEN
        RAISE EXCEPTION 'Error: Tipo de material inválido. Debe ser 1 (Specialized/Acero) o 2 (Special/Aluminio).';
    END IF;

    -- 4. GENERAR ID DEL KIT
    -- Como la tabla no es autoincremental, calculamos el siguiente ID disponible
    SELECT COALESCE(MAX(id_kit), 0) + 1 INTO jid_nuevo 
    FROM tab_kits;

    -- 5. GUARDAR EL KIT
    -- Insertamos los datos principales en la tabla de Kits
    INSERT INTO tab_kits (id_kit, id_especializacion, nom_kit, cant_disp, tipo_mat, stock_min, stock_max, img_url) 
    VALUES (jid_nuevo, jid_especializacion, TRIM(jnom_kit), jcant_disp, jtipo_mat, COALESCE(jstock_min, 0), COALESCE(jstock_max, 0), TRIM(jimg_url));

    -- 6. GUARDAR LOS INSTRUMENTOS
    -- Si nos enviaron instrumentos, los recorremos uno por uno para guardarlos
    IF jinstruments IS NOT NULL AND array_length(jinstruments, 1) > 0 THEN
        
        -- Buscamos cual es el ultimo ID de la tabla intermedia para seguir la secuencia
        SELECT COALESCE(MAX(id_instrumento_kit), 0) INTO j_check_val 
        FROM tab_instrumentos_kit;

        FOREACH j_inst_id IN ARRAY jinstruments
        LOOP
            -- Aumentamos el contador del ID para el siguiente registro
            j_check_val := j_check_val + 1;

            -- Seguridad: Verificamos que el instrumento realmente exista antes de guardarlo
            IF NOT EXISTS (SELECT 1 FROM tab_instrumentos WHERE id_instrumento = j_inst_id) THEN
                 RAISE EXCEPTION 'Error: Intentas agregar un instrumento que no existe (ID %).', j_inst_id;
            END IF;

            -- Guardamos la relación
            INSERT INTO tab_instrumentos_kit (id_instrumento_kit, id_kit, id_instrumento, cant_instrumento)
            VALUES (j_check_val, jid_nuevo, j_inst_id, 1);
        END LOOP;
    END IF;

    RAISE NOTICE '¡Listo! Kit guardado correctamente con sus instrumentos.';
    
    -- Automatización: Registrar en historial de fabricación si hay stock inicial
    IF jcant_disp > 0 THEN
        PERFORM fun_kardex_productos(2, jid_nuevo, 1, jcant_disp, 'Carga inicial por creación');
    END IF;

    RETURN TRUE;

EXCEPTION
    -- Capturamos errores conocidos para dar mensajes amigables
    WHEN unique_violation THEN 
        RAISE EXCEPTION 'Error: Ya existe un Kit con ese mismo nombre.'; 
    WHEN foreign_key_violation THEN
        RAISE EXCEPTION 'Error: Hay un problema de referencia (quizás la especialización no es válida).';
    WHEN OTHERS THEN 
        -- Si pasa algo raro, mostramos el error técnico de la base de datos
        RAISE EXCEPTION 'Ocurrió un error inesperado: %', SQLERRM; 
END;
$$ 
LANGUAGE plpgsql;

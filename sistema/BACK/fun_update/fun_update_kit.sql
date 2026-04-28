/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Kit Nulo:          SELECT fun_update_kits(NULL, 1, 'Kit', 10, 5, 20, 'url');
   2.  ID Kit Negativo:      SELECT fun_update_kits(-1, 1, 'Kit', 10, 5, 20, 'url');
   3.  Espec Nulo:           SELECT fun_update_kits(1, NULL, 'Kit', 10, 5, 20, 'url');
   4.  Espec Inexistente:    SELECT fun_update_kits(1, 99999, 'Kit', 10, 5, 20, 'url');
   5.  Nombre Vacío:         SELECT fun_update_kits(1, 1, '', 10, 5, 20, 'url');
   6.  Cant Negativa:        SELECT fun_update_kits(1, 1, 'Kit', -10, 5, 20, 'url');
   7.  Stock Min Neg:        SELECT fun_update_kits(1, 1, 'Kit', 10, -5, 20, 'url');
   8.  Stock Max < Min:      SELECT fun_update_kits(1, 1, 'Kit', 10, 20, 5, 'url');
   9.  ID Inexistente (999): SELECT fun_update_kits(99999, 1, 'Kit', 10, 5, 20, 'url');
   10. CASO EXITOSO:         SELECT fun_update_kits(1, 1, 'Kit Ortodoncia Premium', 50, 10, 100, 'updated_kit.png');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_kits  (jid_kit tab_kits.id_kit%TYPE,
                                            jid_especializacion tab_kits.id_especializacion%TYPE,
                                            jnom_kit tab_kits.nom_kit%TYPE,
                                            jcant_disp tab_kits.cant_disp%TYPE,
                                            jtipo_mat tab_kits.tipo_mat%TYPE,
                                            jstock_min tab_kits.stock_min%TYPE,
                                            jstock_max tab_kits.stock_max%TYPE,
                                            jimg_url tab_kits.img_url%TYPE,
                                            jinstruments INTEGER[] DEFAULT '{}')
                                            RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_inst_id INTEGER;
            j_check_id_inst_kit INTEGER;
BEGIN
    -- 1. VERIFICACIONES INICIALES
    -- Revisamos que el ID del kit sea válido
    IF jid_kit IS NULL OR jid_kit <= 0 THEN 
        RAISE EXCEPTION 'Error: El ID del Kit no es válido.'; 
    END IF;

    -- Buscamos si el Kit existe y si está activo
    SELECT ind_vivo INTO j_ind_vivo FROM tab_kits WHERE id_kit = jid_kit;

    IF j_ind_vivo IS NULL THEN
        RAISE EXCEPTION 'Error: No encontramos ningún Kit con ese ID.';
    END IF;

    IF j_ind_vivo = FALSE THEN
        RAISE EXCEPTION 'Error: Este Kit fue eliminado anteriormente, no se puede editar.';
    END IF;

    -- 2. VALIDAR ESPECIALIZACIÓN
    -- Revisamos que la especialización que nos mandan sea correcta
    IF jid_especializacion IS NULL OR jid_especializacion <= 0 THEN 
        RAISE EXCEPTION 'Error: Debes elegir una especialización válida.'; 
    END IF;
    
    PERFORM 1 FROM tab_tipo_especializacion WHERE id_especializacion = jid_especializacion AND ind_vivo = TRUE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Error: La especialización seleccionada no existe o está inactiva.'; 
    END IF;

    -- 3. VALIDAR DATOS DEL FORMULARIO
    -- El nombre no puede estar vacío
    IF jnom_kit IS NULL OR TRIM(jnom_kit) = '' THEN 
        RAISE EXCEPTION 'Error: El Kit debe tener un nombre.'; 
    END IF;

    -- Nombre muy corto
    IF LENGTH(TRIM(jnom_kit)) < 3 THEN 
        RAISE EXCEPTION 'Error: El nombre es muy corto (mínimo 3 letras).'; 
    END IF;

    -- Validamos caracteres extraños en el nombre
    IF jnom_kit !~ '^[a-zA-Z0-9ñÑáéíóúÁÉÍÓÚ\s\.\-\(\)\,\:\;\#]+$' THEN 
        RAISE EXCEPTION 'Error: El nombre contiene caracteres no permitidos.'; 
    END IF;

    -- Validamos cantidades positivas
    IF jcant_disp < 0 THEN 
        RAISE EXCEPTION 'Error: La cantidad no puede ser negativa.'; 
    END IF;

    IF jstock_min < 0 OR jstock_max < 0 THEN 
        RAISE EXCEPTION 'Error: Los stocks no pueden ser negativos.'; 
    END IF;

    -- Lógica de negocio: el máximo debe ser mayor que el mínimo
    IF jstock_max < jstock_min THEN 
        RAISE EXCEPTION 'Error: El stock máximo no puede ser menor al mínimo.'; 
    END IF;

    IF jimg_url IS NULL OR TRIM(jimg_url) = '' THEN 
        RAISE EXCEPTION 'Error: Se requiere una imagen para el Kit.'; 
    END IF;

    -- Validar tipo de material (1=Specialized/Acero, 2=Special/Aluminio)
    IF jtipo_mat IS NULL OR jtipo_mat NOT IN (1, 2) THEN
        RAISE EXCEPTION 'Error: Tipo de material inválido. Debe ser 1 (Specialized/Acero) o 2 (Special/Aluminio).';
    END IF;

    -- 4. ACTUALIZAR DATOS PRINCIPALES
    -- Guardamos los cambios en la tabla de Kits
    UPDATE tab_kits SET
        id_especializacion = jid_especializacion,
        nom_kit = TRIM(jnom_kit),
        cant_disp = jcant_disp,
        tipo_mat = jtipo_mat,
        stock_min = COALESCE(jstock_min, 0),
        stock_max = COALESCE(jstock_max, 0),
        img_url = TRIM(jimg_url),
        user_update = current_user,
        fec_update = NOW()
    WHERE id_kit = jid_kit;

    -- 5. ACTUALIZAR INSTRUMENTOS
    -- Estrategia: Borrón y cuenta nueva. Eliminamos los antiguos y ponemos los nuevos.
    DELETE FROM tab_instrumentos_kit WHERE id_kit = jid_kit;

    IF jinstruments IS NOT NULL AND array_length(jinstruments, 1) > 0 THEN
        
        -- Buscamos el ID secuencial disponible para la tabla intermedia
        SELECT COALESCE(MAX(id_instrumento_kit), 0) INTO j_check_id_inst_kit FROM tab_instrumentos_kit;

        -- Recorremos la lista de instrumentos que nos enviaron
        FOREACH j_inst_id IN ARRAY jinstruments
        LOOP
             -- EVITAR DUPLICADOS: Si ya guardamos este instrumento en este ciclo, lo saltamos
             -- (Esto protege por si en el array vienen IDs repetidos)
             PERFORM 1 FROM tab_instrumentos_kit WHERE id_kit = jid_kit AND id_instrumento = j_inst_id;
             IF FOUND THEN
                CONTINUE; 
             END IF;

             -- Verificar que el instrumento exista en el sistema
             PERFORM 1 FROM tab_instrumentos WHERE id_instrumento = j_inst_id;
             IF NOT FOUND THEN
                RAISE EXCEPTION 'Error: El instrumento ID % no existe, verifica la lista.', j_inst_id;
             END IF;
             
             -- Incrementamos el ID y guardamos
             j_check_id_inst_kit := j_check_id_inst_kit + 1;

             INSERT INTO tab_instrumentos_kit (id_instrumento_kit, id_kit, id_instrumento, cant_instrumento)
             VALUES (j_check_id_inst_kit, jid_kit, j_inst_id, 1);
        END LOOP;
    END IF;
    
    RAISE NOTICE '¡Actualización exitosa!';
    RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    -- Si falla algo no controlado, avisamos con el error real
    RAISE EXCEPTION 'Ocurrió un error inesperado al actualizar: %', SQLERRM; 
END;
$$ LANGUAGE plpgsql;

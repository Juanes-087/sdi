-- Select fun_insert_instrum_kit (1,1,10);
CREATE OR REPLACE FUNCTION fun_insert_instrum_kit   (jid_kit tab_instrumentos_kit.id_kit%TYPE,
                                                    jid_instrumento tab_instrumentos_kit.id_instrumento%TYPE,
                                                    jcant_instrumento tab_instrumentos_kit.cant_instrumento%TYPE)
                                                    RETURNS BOOLEAN AS
$$
    DECLARE 
        nvo_id tab_instrumentos_kit.id_instrumento_kit%TYPE;
        j_check_val INTEGER; -- Variable auxiliar para validaciones
    BEGIN 
    -- Validaciones Inputs
        IF jid_kit IS NULL OR jid_kit <= 0 THEN
                RAISE NOTICE 'Error: ID de Kit inválido.';
                RETURN FALSE;
        END IF;

        IF jid_instrumento IS NULL OR jid_instrumento <= 0 THEN
                RAISE NOTICE 'Error: ID de Instrumento inválido.';
                RETURN FALSE;
        END IF;

        IF jcant_instrumento IS NULL OR jcant_instrumento <= 0 THEN
                RAISE NOTICE 'Error: Cantidad inválida.';
                RETURN FALSE;
        END IF;

        IF jcant_instrumento > 20 THEN -- Tope logico
                RAISE NOTICE 'Error: Cantidad excesiva para un kit.';
                RETURN FALSE;
        END IF;

    -- Validar existencia FKs
        SELECT 1 INTO j_check_val From tab_kits WHERE id_kit = jid_kit LIMIT 1;
        IF NOT FOUND THEN
                RAISE NOTICE 'Error: El Kit no existe.';
                RETURN FALSE;
        END IF;

        SELECT 1 INTO j_check_val From tab_instrumentos WHERE id_instrumento = jid_instrumento LIMIT 1;
        IF NOT FOUND THEN
                RAISE NOTICE 'Error: El Instrumento no existe.';
                RETURN FALSE;
        END IF;

    -- Generar ID
        SELECT COALESCE(MAX(id_instrumento_kit), 0) + 1 INTO nvo_id 
        FROM tab_instrumentos_kit;

    -- Insertar en tab_instrumentos_kit
        INSERT INTO tab_instrumentos_kit(id_instrumento_kit, id_kit, id_instrumento, cant_instrumento)
        VALUES (nvo_id, jid_kit, jid_instrumento, jcant_instrumento);

        RAISE NOTICE 'Instrumento-Kit agregado exitosamente con ID %', nvo_id;
        RETURN TRUE;

EXCEPTION
    WHEN unique_violation THEN
        RAISE NOTICE 'Error: Esta combinación Kit-Instrumento ya existe.';
        RETURN FALSE;
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Error: Referencia inválida.';
        RETURN FALSE;
    WHEN OTHERS THEN
        RAISE NOTICE 'Error inesperado: %', SQLERRM;
        RETURN FALSE;
END;
$$
Language plpgsql;

/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Prov Nulo:         SELECT fun_update_proveedores(NULL, 1, 1, '123', 'Nom', 300, 'm@m.com', 'D', 'C');
   2.  ID Prov Negativo:     SELECT fun_update_proveedores(-1, 1, 1, '123', 'Nom', 300, 'm@m.com', 'D', 'C');
   3.  ID Doc Invalido:      SELECT fun_update_proveedores(1, -1, 1, '123', 'Nom', 300, 'm@m.com', 'D', 'C');
   4.  ID Ciudad Invalido:   SELECT fun_update_proveedores(1, 1, -1, '123', 'Nom', 300, 'm@m.com', 'D', 'C');
   5.  Email Inexistente:    SELECT fun_update_proveedores(1, 1, 1, '123', 'Nom', 300, '', 'D', 'C');
   6.  Nombre Vacío:         SELECT fun_update_proveedores(1, 1, 1, '123', '', 300, 'm@m.com', 'D', 'C');
   7.  Num Doc Vacío:        SELECT fun_update_proveedores(1, 1, 1, '', 'Nom', 300, 'm@m.com', 'D', 'C');
   8.  Dir Vacía:            SELECT fun_update_proveedores(1, 1, 1, '123', 'Nom', 300, 'm@m.com', '', 'C');
   9.  ID Inexistente (999): SELECT fun_update_proveedores(99999, 1, 1, '123', 'Nom', 300, 'm@m.com', 'D', 'C');
   10. CASO EXITOSO:         SELECT fun_update_proveedores(1, 1, 1, '900123456', 'Distribuidora Medica SAS', 3101234567, 'contacto@distmedica.com', 'Bogota DC', 'Excelente');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_proveedores   (jid_prov tab_proveedores.id_prov%TYPE,
                                                    jid_documento tab_proveedores.id_documento%TYPE,
                                                    jid_ciudad tab_proveedores.id_ciudad%TYPE,
                                                    jnum_documento tab_proveedores.num_documento%TYPE,
                                                    jnom_prov tab_proveedores.nom_prov%TYPE,
                                                    jtel_prov tab_proveedores.tel_prov%TYPE,
                                                    jmail_prov tab_proveedores.mail_prov%TYPE,
                                                    jdir_prov tab_proveedores.dir_prov%TYPE,
                                                    jind_calidad tab_proveedores.ind_calidad%TYPE)
                                                    RETURNS BOOLEAN AS 
$$
    DECLARE j_ind_vivo BOOLEAN;
            j_ind_vivo_fk BOOLEAN;
            existe_duplicado BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_prov IS NULL OR jid_prov <= 0 THEN 
            RAISE NOTICE 'Error: ID Proveedor inválido.'; 
            RETURN FALSE; 
        END IF;

    -- Optimización: Obtener estado
        SELECT ind_vivo INTO j_ind_vivo FROM tab_proveedores WHERE id_prov = jid_prov;

    -- 1. Verificar existencia física
        IF j_ind_vivo IS NULL THEN
            RAISE NOTICE 'Error: Proveedor con ID % no encontrado.', jid_prov;
            RETURN FALSE;
        END IF;

    -- 2. Verificar estado lógico
        IF j_ind_vivo = FALSE THEN
            RAISE NOTICE 'Error: El proveedor con ID % se encuentra eliminado. No se puede actualizar.', jid_prov;
            RETURN FALSE;
        END IF;

    -- FKs
        IF jid_documento IS NULL OR jid_documento <= 0 THEN 
            RAISE NOTICE 'Error: ID Tipo Doc inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_tipo_documentos WHERE id_documento = jid_documento;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Tipo doc no existe o inactivo.'; 
            RETURN FALSE; 
        END IF;

        IF jid_ciudad IS NULL OR jid_ciudad <= 0 THEN 
            RAISE NOTICE 'Error: ID Ciudad inválido.'; 
            RETURN FALSE; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_fk FROM tab_ciudades WHERE id_ciudad = jid_ciudad;
        
        IF j_ind_vivo_fk IS NULL OR j_ind_vivo_fk = FALSE THEN 
            RAISE NOTICE 'Error: Ciudad no existe o inactiva.'; 
            RETURN FALSE; 
        END IF;

    -- Strings
        IF jnom_prov IS NULL OR TRIM(jnom_prov) = '' THEN 
            RAISE NOTICE 'Error: Nombre proveedor vacío.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnom_prov)) < 3 THEN 
            RAISE NOTICE 'Error: Nombre del proveedor muy corto (Mínimo 3 caracteres).'; 
            RETURN FALSE; 
        END IF;

        IF jnom_prov !~ '^[a-zA-Z0-9ñÑáéíóúÁÉÍÓÚ\s.,\-&()]+$' THEN 
            RAISE NOTICE 'Error: Nombre del proveedor contiene caracteres prohibidos.'; 
            RETURN FALSE; 
        END IF;

        IF jnum_documento IS NULL OR TRIM(jnum_documento) = '' THEN 
            RAISE NOTICE 'Error: Num documento vacío.'; 
            RETURN FALSE; 
        END IF;

        IF LENGTH(TRIM(jnum_documento)) < 5 THEN 
            RAISE NOTICE 'Error: NIT muy corto.'; 
            RETURN FALSE; 
        END IF;

        IF jnum_documento !~ '^[0-9\-\.]+$' THEN 
            RAISE NOTICE 'Error: NIT solo permite números, puntos y guiones.'; 
            RETURN FALSE; 
        END IF;

        IF jmail_prov IS NULL OR TRIM(jmail_prov) = '' THEN 
            RAISE NOTICE 'Error: Email vacío.'; 
            RETURN FALSE; 
        END IF;

        IF jmail_prov !~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' THEN 
            RAISE NOTICE 'Error: Formato de Email inválido.'; 
            RETURN FALSE; 
        END IF;

        IF jdir_prov IS NULL OR TRIM(jdir_prov) = '' THEN 
            RAISE NOTICE 'Error: Dirección vacía.'; 
            RETURN FALSE; 
        END IF;

    -- Unicidad Nombre
        SELECT EXISTS(SELECT 1 FROM tab_proveedores WHERE nom_prov = jnom_prov AND id_prov != jid_prov AND ind_vivo=TRUE) INTO existe_duplicado;
        IF existe_duplicado THEN 
            RAISE NOTICE 'Error: Nombre proveedor ya existe.'; 
            RETURN FALSE; 
        END IF;

        -- Teléfono
        IF jtel_prov IS NULL OR jtel_prov !~ '^[0-9]{7,10}$' THEN
            RAISE NOTICE 'Error: Teléfono inválido (debe tener entre 7 y 10 dígitos numéricos).';
            RETURN FALSE;
        END IF;

        -- Calidad (Opcional)
        IF jind_calidad IS NOT NULL AND TRIM(jind_calidad) <> '' THEN
             IF LENGTH(TRIM(jind_calidad)) < 4 THEN
                RAISE NOTICE 'Error: Descripción de calidad muy corta.'; 
                RETURN FALSE;
             END IF;
             
             IF jind_calidad !~ '^[a-zA-Z0-9ñÑáéíóúÁÉÍÓÚ\s.,;]+$' THEN 
                RAISE NOTICE 'Error: Descripción de calidad con caracteres especiales prohibidos.'; 
                RETURN FALSE;
             END IF;
        END IF;

    -- Actualizar
        UPDATE tab_proveedores SET
            id_documento = jid_documento,
            id_ciudad = jid_ciudad,
            num_documento = jnum_documento,
            nom_prov = jnom_prov,
            tel_prov = jtel_prov,
            mail_prov = jmail_prov,
            dir_prov = jdir_prov,
            ind_calidad = COALESCE(TRIM(jind_calidad), '')
        WHERE id_prov = jid_prov;

        RAISE NOTICE 'Proveedor actualizado exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE NOTICE 'Error inesperado: %', SQLERRM; 
    RETURN FALSE; 
END;
$$ LANGUAGE plpgsql;

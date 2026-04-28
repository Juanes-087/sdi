/*
   -----------------------------------------------------------------------------
   PRUEBAS DE SEGURIDAD (EJECUTAR ANTES DE USAR)
   -----------------------------------------------------------------------------
   1.  ID Emp Nulo:          SELECT fun_update_parametros(NULL, 'Emp', 'Dir', 123, 1, 10, 1, 100, 50, 'Obs');
   2.  ID Emp Negativo:      SELECT fun_update_parametros(-1, 'Emp', 'Dir', 123, 1, 10, 1, 100, 50, 'Obs');
   3.  Nom Vacío:            SELECT fun_update_parametros(1, '', 'Dir', 123, 1, 10, 1, 100, 50, 'Obs');
   4.  Dir Vacía:            SELECT fun_update_parametros(1, 'Emp', '', 123, 1, 10, 1, 100, 50, 'Obs');
   5.  Porcentaje Inv(150):  SELECT fun_update_parametros(1, 'Emp', 'Dir', 123, 1, 150, 1, 100, 50, 'Obs');
   6.  Rango Fact Inv:       SELECT fun_update_parametros(1, 'Emp', 'Dir', 123, 1, 10, 100, 50, 60, 'Obs'); -- In > Fin
   7.  Fact Act Inv:         SELECT fun_update_parametros(1, 'Emp', 'Dir', 123, 1, 10, 1, 100, 200, 'Obs'); -- Act > Fin
   8.  ID Emp Inex:          SELECT fun_update_parametros(99999, 'Emp', 'Dir', 123, 1, 10, 1, 100, 50, 'Obs');
   9.  ID Ciudad Inex:       SELECT fun_update_parametros(1, 'Emp', 'Dir', 123, 999, 10, 1, 100, 50, 'Obs');
   10. CASO EXITOSO:         SELECT fun_update_parametros(1, 'Empresa SAS', 'Cra 1 # 2-3', 3201234567, 1, 19, 1, 5000, 100, 'Actualización OK');
   -----------------------------------------------------------------------------
*/
CREATE OR REPLACE FUNCTION fun_update_parametros(jid_empresa tab_parametros.id_empresa%TYPE,
                                                jnom_empresa tab_parametros.nom_empresa%TYPE,
                                                jdir_empresa tab_parametros.dir_empresa%TYPE,
                                                jtel_empresa tab_parametros.tel_empresa%TYPE,
                                                jid_ciudad tab_parametros.id_ciudad%TYPE,
                                                jval_pordesc tab_parametros.val_pordesc%TYPE,
                                                jval_inifact tab_parametros.val_inifact%TYPE,
                                                jval_finfact tab_parametros.val_finfact%TYPE,
                                                jval_actfact tab_parametros.val_actfact%TYPE,
                                                jval_observa tab_parametros.val_observa%TYPE,
                                                jind_idle tab_parametros.ind_idle%TYPE)
                                                RETURNS BOOLEAN AS 
$$
    DECLARE existe_reg BOOLEAN;
            j_ind_vivo_ciudad BOOLEAN;
BEGIN
    -- Validar ID
        IF jid_empresa IS NULL OR jid_empresa <= 0 THEN
            RAISE EXCEPTION 'Error: ID de empresa inválido.';
        END IF;

    -- Verificar existencia (Sin soft delete, solo PK)
        SELECT EXISTS(SELECT 1 FROM tab_parametros WHERE id_empresa = jid_empresa) INTO existe_reg;
        IF NOT existe_reg THEN
            RAISE EXCEPTION 'Error: Parámetros de empresa no encontrados.';
        END IF;

    -- Validar Strings
        IF jnom_empresa IS NULL OR TRIM(jnom_empresa) = '' THEN 
            RAISE EXCEPTION 'Error: El nombre de la empresa no puede estar vacío.'; 
        END IF;
        IF jdir_empresa IS NULL OR TRIM(jdir_empresa) = '' THEN 
            RAISE EXCEPTION 'Error: La dirección de la empresa no puede estar vacía.'; 
        END IF;
        IF jval_observa IS NULL OR TRIM(jval_observa) = '' THEN 
            RAISE EXCEPTION 'Error: Las observaciones no pueden estar vacías.'; 
        END IF;

    -- Validar Numericos
        IF jtel_empresa IS NULL OR LENGTH(jtel_empresa::TEXT) < 7 OR LENGTH(jtel_empresa::TEXT) > 10 THEN 
            RAISE EXCEPTION 'Error: Teléfono de empresa inválido (Debe tener entre 7 y 10 dígitos).'; 
        END IF;

    -- Validar FK Ciudad (Con check de ind_vivo)
        IF jid_ciudad IS NULL OR jid_ciudad <= 0 THEN 
            RAISE EXCEPTION 'Error: ID de ciudad inválido.'; 
        END IF;

        SELECT ind_vivo INTO j_ind_vivo_ciudad FROM tab_ciudades WHERE id_ciudad = jid_ciudad;
        
        IF j_ind_vivo_ciudad IS NULL THEN
            RAISE EXCEPTION 'Error: La ciudad referenciada no existe.';
        END IF;
        IF j_ind_vivo_ciudad = FALSE THEN
            RAISE EXCEPTION 'Error: La ciudad referenciada está eliminada (inactiva).';
        END IF;

    -- Validar Checks Lógicos
        IF jval_pordesc IS NULL OR jval_pordesc < 0 OR jval_pordesc > 100 THEN
            RAISE EXCEPTION 'Error: Porcentaje de descuento inválido (Debe estar entre 0 y 100).';
        END IF;

    -- Validar Rango Facturacion
        IF jval_inifact IS NULL OR jval_inifact < 1 THEN 
            RAISE EXCEPTION 'Error: Inicio de facturación inválido.'; 
        END IF;
        IF jval_finfact IS NULL OR jval_finfact < jval_inifact THEN 
            RAISE EXCEPTION 'Error: Fin de facturación debe ser mayor o igual al inicio.'; 
        END IF;
        IF jval_actfact IS NULL OR jval_actfact < jval_inifact OR jval_actfact > jval_finfact THEN 
            RAISE EXCEPTION 'Error: Factura actual fuera de rango (Debe estar entre inicio y fin).'; 
        END IF;

    -- Validar Idle Time
        IF jind_idle IS NULL OR jind_idle < 5 OR jind_idle > 480 THEN
            RAISE EXCEPTION 'Error: Tiempo de inactividad inválido (Debe estar entre 5 y 480 minutos).';
        END IF;

    -- Actualizar
        UPDATE tab_parametros SET
            nom_empresa = jnom_empresa,
            dir_empresa = jdir_empresa,
            tel_empresa = jtel_empresa,
            id_ciudad = jid_ciudad,
            val_pordesc = jval_pordesc,
            val_inifact = jval_inifact,
            val_finfact = jval_finfact,
            val_actfact = jval_actfact,
            val_observa = jval_observa,
            ind_idle = jind_idle
        WHERE id_empresa = jid_empresa;
        
        RAISE NOTICE 'Parámetros de empresa actualizados exitosamente.';
        RETURN TRUE;

EXCEPTION WHEN OTHERS THEN 
    RAISE EXCEPTION 'Error inesperado: %', SQLERRM; 
END;
$$ LANGUAGE plpgsql;

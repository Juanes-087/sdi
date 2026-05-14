-- Ejecutar una por una.
CREATE OR REPLACE FUNCTION fun_audit_trail() RETURNS TRIGGER AS
$$
    BEGIN
        IF TG_OP = 'INSERT' THEN
            NEW.user_insert = COALESCE(current_setting('specialized.app_user', true), CURRENT_USER);
            NEW.fec_insert = CURRENT_TIMESTAMP;
            NEW.ind_vivo = TRUE;
            RETURN NEW;
        END IF;

        IF TG_OP = 'UPDATE' THEN
            NEW.user_update = COALESCE(current_setting('specialized.app_user', true), CURRENT_USER);
            NEW.fec_update = CURRENT_TIMESTAMP;
            RETURN NEW;
        END IF;
    END;
$$
LANGUAGE PLPGSQL;

-- 1. tab_users
CREATE OR REPLACE TRIGGER tri_audit_users BEFORE INSERT OR UPDATE ON tab_users
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 2. tab_menu
CREATE OR REPLACE TRIGGER tri_audit_menu BEFORE INSERT OR UPDATE ON tab_menu
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 3. tab_users_menu
CREATE OR REPLACE TRIGGER tri_audit_users_menu BEFORE INSERT OR UPDATE ON tab_users_menu
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 4. tab_departamentos
CREATE OR REPLACE TRIGGER tri_audit_departamentos BEFORE INSERT OR UPDATE ON tab_departamentos
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 5. tab_ciudades
CREATE OR REPLACE TRIGGER tri_audit_ciudades BEFORE INSERT OR UPDATE ON tab_ciudades
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 6. tab_tipo_documentos
CREATE OR REPLACE TRIGGER tri_audit_tipo_documentos BEFORE INSERT OR UPDATE ON tab_tipo_documentos
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 7. tab_cargos
CREATE OR REPLACE TRIGGER tri_audit_cargos BEFORE INSERT OR UPDATE ON tab_cargos
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 8. tab_tipo_sangre
CREATE OR REPLACE TRIGGER tri_audit_tipo_sangre BEFORE INSERT OR UPDATE ON tab_tipo_sangre
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 9. tab_empleados
CREATE OR REPLACE TRIGGER tri_audit_empleados BEFORE INSERT OR UPDATE ON tab_empleados
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 10. tab_bancos
CREATE OR REPLACE TRIGGER tri_audit_bancos BEFORE INSERT OR UPDATE ON tab_bancos
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 11. tab_proveedores
CREATE OR REPLACE TRIGGER tri_audit_proveedores BEFORE INSERT OR UPDATE ON tab_proveedores
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 12. tab_bancos_proveedor
CREATE OR REPLACE TRIGGER tri_audit_bancos_proveedor BEFORE INSERT OR UPDATE ON tab_bancos_proveedor
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 13. tab_clientes
CREATE OR REPLACE TRIGGER tri_audit_clientes BEFORE INSERT OR UPDATE ON tab_clientes
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 14. tab_materias_primas
CREATE OR REPLACE TRIGGER tri_audit_materias_primas BEFORE INSERT OR UPDATE ON tab_materias_primas
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 15. tab_mat_primas_prov
CREATE OR REPLACE TRIGGER tri_audit_mat_primas_prov BEFORE INSERT OR UPDATE ON tab_mat_primas_prov
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 16. tab_bodega
CREATE OR REPLACE TRIGGER tri_audit_bodega BEFORE INSERT OR UPDATE ON tab_bodega
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 17. tab_producc
CREATE OR REPLACE TRIGGER tri_audit_producc BEFORE INSERT OR UPDATE ON tab_producc
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 18. tab_tipo_especializacion
CREATE OR REPLACE TRIGGER tri_audit_tipo_especializacion BEFORE INSERT OR UPDATE ON tab_tipo_especializacion
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 19. tab_instrumentos
CREATE OR REPLACE TRIGGER tri_audit_instrumentos BEFORE INSERT OR UPDATE ON tab_instrumentos
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 20. tab_kits
CREATE OR REPLACE TRIGGER tri_audit_kits BEFORE INSERT OR UPDATE ON tab_kits
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 21. tab_instrumentos_kit
CREATE OR REPLACE TRIGGER tri_audit_instrumentos_kit BEFORE INSERT OR UPDATE ON tab_instrumentos_kit
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- Maximo 10 instrumentos por kit
Create or replace function max_instrum_kit()
Returns TRIGGER as 
$$
DECLARE
    v_conteo INT;
BEGIN
    -- Si es un UPDATE y el kit no ha cambiado, permitimos la actualización sin validar el límite
    IF (TG_OP = 'UPDATE' AND OLD.id_kit = NEW.id_kit) THEN
        RETURN NEW;
    END IF;

    -- Contamos instrumentos activos en el kit de destino
    SELECT count(1) INTO v_conteo
    FROM tab_instrumentos_kit 
    WHERE id_kit = NEW.id_kit 
    AND ind_vivo = true;

    IF v_conteo >= 10 THEN
        Raise Exception 'Un kit no puede tener más de 10 instrumentos diferentes';
    END IF;
    
    RETURN NEW;
END;
$$
Language plpgsql;

Create or replace TRIGGER max_instrumento_kit
Before insert or update on tab_instrumentos_kit
For each row execute function max_instrum_kit();

-- 22. tab_productos
CREATE OR REPLACE TRIGGER tri_audit_productos BEFORE INSERT OR UPDATE ON tab_productos
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 23. tab_facturas
CREATE OR REPLACE TRIGGER tri_audit_facturas BEFORE INSERT OR UPDATE ON tab_facturas
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 24. tab_dev
CREATE OR REPLACE TRIGGER tri_audit_dev BEFORE INSERT OR UPDATE ON tab_dev
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 24.1. tab_devol_reparable
CREATE OR REPLACE TRIGGER tri_audit_devol_reparable BEFORE INSERT OR UPDATE ON tab_devol_reparable
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 25. tab_detalle_facturas
CREATE OR REPLACE TRIGGER tri_audit_detalle_facturas BEFORE INSERT OR UPDATE ON tab_detalle_facturas
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 26. tab_cat_mat_prim
CREATE OR REPLACE TRIGGER tri_audit_cat_mat_prim BEFORE INSERT OR UPDATE ON tab_cat_mat_prim
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 27. tab_kardex_mat_prima
CREATE OR REPLACE TRIGGER tri_audit_kardex_mat_prima BEFORE INSERT OR UPDATE ON tab_kardex_mat_prima
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 28. tab_historico_mat_prima
CREATE OR REPLACE TRIGGER tri_audit_historico_mat_prima BEFORE INSERT OR UPDATE ON tab_historico_mat_prima
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 29. tab_kardex_productos (OJO: Usando el nombre correcto)
CREATE OR REPLACE TRIGGER tri_audit_kardex_productos BEFORE INSERT OR UPDATE ON tab_kardex_productos
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- 30. tab_estado_fact
CREATE OR REPLACE TRIGGER tri_audit_estado_fact BEFORE INSERT OR UPDATE ON tab_estado_fact
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

drop trigger if exists tri_audit_generos on tab_generos;

-- 32. tab_unidades_medida
CREATE OR REPLACE TRIGGER tri_audit_unidades_medida BEFORE INSERT OR UPDATE ON tab_unidades_medida
FOR EACH ROW EXECUTE FUNCTION fun_audit_trail();

-- Para juanes del futuro:Para hacer un borrado fisico hay que tener una tabla para guardar los registros borrados, con la mayor cantidad de campos posibles

-- Triggers para hacer actualizaciones automaticas despues de una transaccion(insert y update)

-- VER TRIGGERS
SELECT 
    trigger_name as nombre_trigger,
    event_object_table as tabla,
    event_manipulation as operacion,
    action_statement as funcion
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY tabla, operacion;
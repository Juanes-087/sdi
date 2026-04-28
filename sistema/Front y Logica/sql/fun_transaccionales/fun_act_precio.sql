/*
SELECT fun_act_precio_mat_prima(1, 1, 135000, 'Aumento anual IPC 2024');
SELECT fun_act_precio_mat_prima(NULL, NULL, NULL, NULL);
SELECT fun_act_precio_mat_prima(1, 1, -5000, 'Descuento ilegal');
SELECT fun_act_precio_mat_prima(1, 1, 50000, '   ');
SELECT fun_act_precio_mat_prima(99999, 1, 50000, 'Prueba MP Inexistente');
SELECT fun_act_precio_mat_prima(1, 99999, 50000, 'Prueba Prov Inexistente');
SELECT fun_act_precio_mat_prima(1, 1, 140000, 'Ajuste IPC 2026 - Validado');

SELECT id_historico, precio_anterior, precio_nuevo, motivo, user_insert 
FROM tab_historico_mat_prima 
ORDER BY id_historico DESC LIMIT 1;
*/


CREATE OR REPLACE FUNCTION fun_act_precio_mat_prima(jid_materia     tab_materias_primas.id_mat_prima%TYPE,
                                                                        jid_proveedor   tab_proveedores.id_prov%TYPE,
                                                                        jnuevo_precio   tab_historico_mat_prima.precio_nuevo%TYPE,
                                                                        jmotivo         tab_historico_mat_prima.motivo%TYPE
                                                                        ) RETURNS BOOLEAN AS
$$
        DECLARE
            -- Variables para datos
            jprecio_anterior tab_historico_mat_prima.precio_anterior%TYPE;
            jid_nuevo_hist   tab_historico_mat_prima.id_historico%TYPE;
    
            -- Variables para validación (Nombres para mensajes de error claros)
            jnom_mp          tab_materias_primas.nom_materia_prima%TYPE;
            jnom_prov        tab_proveedores.nom_prov%TYPE;;

        BEGIN
            BEGIN
            -- VALIDACIÓN DE ENTRADA (NULOS)
                IF jid_materia IS NULL OR jid_proveedor IS NULL OR jnuevo_precio IS NULL THEN
                    RAISE NOTICE 'Error de Datos: No se permiten valores nulos en los parámetros.';
                    RAISE EXCEPTION USING ERRCODE = 'P0002';
                END IF;

                IF jmotivo IS NULL OR TRIM(jmotivo) = '' THEN
                    RAISE NOTICE 'Error de Datos: Debe especificar un motivo para el cambio de precio.';
                    RAISE EXCEPTION USING ERRCODE = 'P0002';
                END IF;

            -- VALIDACIÓN LÓGICA (NEGATIVOS Y EXAGERADOS)
                IF jnuevo_precio < 0 THEN
                    RAISE NOTICE 'Error de Negocio: El precio no puede ser negativo.';
                    RAISE EXCEPTION USING ERRCODE = 'P0002';
                END IF;

            -- Opcional: Alerta si el precio es sospechosamente alto (ej. > 10 millones)
                IF jnuevo_precio > 10000000 THEN
                    RAISE NOTICE 'Alerta de Seguridad: El precio ingresado parece excesivo.';
                    RAISE EXCEPTION USING ERRCODE = 'P0002';
                END IF;

            -- VALIDACIÓN DE EXISTENCIA (MATERIA PRIMA)
            -- Usamos tab_materias_primas del script de instalación
                SELECT nom_materia_prima INTO jnom_mp 
                FROM tab_materias_primas 
                WHERE id_mat_prima = jid_materia AND ind_vivo = TRUE;

                IF NOT FOUND THEN
                    RAISE NOTICE 'Error de Integridad: La materia prima ID % no existe.', jid_materia;
                    RAISE EXCEPTION USING ERRCODE = 'P0001';
                END IF;

            -- VALIDACIÓN DE EXISTENCIA (PROVEEDOR)
            -- Usamos tab_proveedores del script de instalación
                SELECT nom_prov INTO jnom_prov 
                FROM tab_proveedores 
                WHERE id_prov = jid_proveedor AND ind_vivo = TRUE;

                IF NOT FOUND THEN
                    RAISE NOTICE 'Error de Integridad: El proveedor ID % no existe.', jid_proveedor;
                    RAISE EXCEPTION USING ERRCODE = 'P0001';
                END IF;

            -- OBTENER PRECIO ANTERIOR
            -- Buscamos en el histórico el último precio registrado
                SELECT precio_nuevo INTO jprecio_anterior FROM tab_historico_mat_prima 
                WHERE id_materia_prima = jid_materia AND id_proveedor = jid_proveedor AND ind_vivo = TRUE
                ORDER BY fecha_cambio DESC LIMIT 1;
        
            -- Si no hay historial, asumimos 0
                IF jprecio_anterior IS NULL THEN 
                    jprecio_anterior := 0; 
                END IF;

            -- GENERAR ID MANUAL
                SELECT COALESCE(MAX(id_historico), 0) + 1 INTO jid_nuevo_hist 
                FROM tab_historico_mat_prima;

            -- INSERTAR REGISTRO
                INSERT INTO tab_historico_mat_prima (id_historico, 
                                                                id_materia_prima, 
                                                                id_proveedor, 
                                                                precio_anterior, 
                                                                precio_nuevo, 
                                                                fecha_cambio, 
                                                                motivo) VALUES (jid_nuevo_hist, 
                                                                                    jid_materia, 
                                                                                    jid_proveedor, 
                                                                                    jprecio_anterior, 
                                                                                    jnuevo_precio, 
                                                                                    NOW(), 
                                                                                    jmotivo);
        
        RAISE NOTICE 'Precio actualizado correctamente para % (Prov: %). Histórico #%', jnom_mp, jnom_prov, jid_nuevo_hist;
        RETURN TRUE;

    EXCEPTION
        -- Errores Controlados
        WHEN SQLSTATE 'P0001' OR SQLSTATE 'P0002' THEN
            RAISE NOTICE 'Operación cancelada por validación (Rollback).';
            RETURN FALSE;
            
        -- Errores de Base de Datos
        WHEN foreign_key_violation THEN
            RAISE NOTICE 'Error de Integridad Referencial: Datos inconsistentes.';
            RETURN FALSE;

        -- Errores Técnicos Generales
        WHEN OTHERS THEN
            RAISE NOTICE 'Error del Sistema (SQLERRM): %', SQLERRM;
            RETURN FALSE;
    END;
END;
$$ 
LANGUAGE plpgsql;
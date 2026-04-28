CREATE OR REPLACE FUNCTION fun_insert_banco_prov  (jid_prov tab_bancos_proveedor.id_prov%TYPE,
                                                 jid_banco tab_bancos_proveedor.id_banco%TYPE,
                                                 jnum_cuenta tab_bancos_proveedor.num_cuenta%TYPE) 
                                                 RETURNS BOOLEAN AS
$$
    DECLARE j_check_val INTEGER;
    
BEGIN
    -- Validaciones
        IF jid_prov IS NULL OR jid_prov <= 0 THEN 
            RAISE NOTICE 'Error: ID Proveedor inválido.'; 
            RETURN FALSE; 
        END IF;

        IF jid_banco IS NULL OR jid_banco <= 0 THEN 
            RAISE NOTICE 'Error: ID Banco inválido.'; 
            RETURN FALSE; 
        END IF;

        IF jnum_cuenta IS NULL OR jnum_cuenta !~ '^[0-9]{10,20}$' THEN 
            RAISE NOTICE 'Error: El número de cuenta es obligatorio y debe tener entre 10 y 20 dígitos numéricos.'; 
            RETURN FALSE; 
        END IF;

    -- Validar Existencia
        SELECT 1 INTO j_check_val FROM tab_proveedores WHERE id_prov = jid_prov LIMIT 1;
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: Proveedor no existe.';
            RETURN FALSE;
        END IF;

        SELECT 1 INTO j_check_val FROM tab_bancos WHERE id_banco = jid_banco LIMIT 1;
        IF NOT FOUND THEN
            RAISE NOTICE 'Error: Banco no existe.';
            RETURN FALSE;
        END IF;

    -- Insertar Relación
        INSERT INTO tab_bancos_proveedor (id_prov, id_banco, num_cuenta) VALUES (jid_prov, jid_banco, TRIM(jnum_cuenta));

        RAISE NOTICE 'Asociación Proveedor-Banco registrada.';
        RETURN TRUE;

EXCEPTION
    WHEN unique_violation THEN 
        RAISE NOTICE 'Error: Esta asociación ya existe.'; 
        RETURN FALSE;
    WHEN OTHERS THEN 
        RAISE NOTICE 'Error inesperado: %', SQLERRM; 
        RETURN FALSE;
END;
$$ 
LANGUAGE plpgsql;

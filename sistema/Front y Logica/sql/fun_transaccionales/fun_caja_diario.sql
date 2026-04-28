/*
SELECT fun_reporte_caja_cursor();
*/

CREATE OR REPLACE FUNCTION fun_reporte_caja_cursor() RETURNS BOOLEAN AS
$$
    DECLARE 
        jcursor_caja    REFCURSOR;
        jreg_caja       RECORD;
        jquery_caja     VARCHAR;
        
        jtotal_dia      DECIMAL(12,2);
        jnom_pago       VARCHAR;
        jfecha_hoy      DATE;

    BEGIN
        jtotal_dia = 0;
        jfecha_hoy = CURRENT_DATE;

        -- Armo el query agrupando por forma de pago
        jquery_caja = 'SELECT ind_forma_pago, COUNT(*) as cant_facturas, SUM(val_tot_fact) as total_venta
                       FROM tab_facturas 
                       WHERE DATE(fecha_venta) = ' || QUOTE_LITERAL(jfecha_hoy) || 
                       ' AND ind_vivo = TRUE 
                       GROUP BY ind_forma_pago';

        Raise notice '=============================================================';
        Raise notice '           REPORTE DE CAJA DIARIO: %', jfecha_hoy;
        Raise notice '=============================================================';

        -- INICIA EL PROCESO DE CURSOR
        OPEN jcursor_caja FOR EXECUTE jquery_caja;

            FETCH jcursor_caja INTO jreg_caja;
            
            -- Validación si no hay ventas hoy
            IF NOT FOUND THEN
                Raise notice ' No se registraron ventas activas en la fecha.';
            END IF;

            WHILE FOUND LOOP
                
                -- Traducir el ID de forma de pago a Texto
                IF jreg_caja.ind_forma_pago = 1 THEN jnom_pago = 'EFECTIVO';
                ELSIF jreg_caja.ind_forma_pago = 2 THEN jnom_pago = 'TRANSFERENCIA';
                ELSIF jreg_caja.ind_forma_pago = 3 THEN jnom_pago = 'TARJETA';
                ELSE jnom_pago = 'OTRO';
                END IF;

                Raise notice ' MEDIO: % | TRANSACCIONES: % | TOTAL: %', 
                             RPAD(jnom_pago, 15, ' '), 
                             jreg_caja.cant_facturas, 
                             jreg_caja.total_venta;

                jtotal_dia = jtotal_dia + jreg_caja.total_venta;

                FETCH jcursor_caja INTO jreg_caja;
            END LOOP;
        
        CLOSE jcursor_caja; -- Libero memoria

        Raise notice '-------------------------------------------------------------';
        Raise notice ' TOTAL CIERRE CAJA: %', jtotal_dia;
        Raise notice '=============================================================';

        Return TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error en reporte de caja: %', SQLERRM;
            RETURN FALSE;
    END;
$$
Language plpgsql;
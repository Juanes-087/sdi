/*
SELECT fun_listar_fact();
UPDATE tab_facturas SET ind_vivo = FALSE WHERE id_factura = 1;

SELECT fun_listar_fact(); -- Sin la primera factura
UPDATE tab_facturas SET ind_vivo = TRUE WHERE id_factura = 1;

*/

CREATE OR REPLACE FUNCTION fun_listar_fact() RETURNS BOOLEAN AS
$$
    DECLARE jcursor_enc REFCURSOR;
    DECLARE jreg_enc    RECORD;
    DECLARE jcursor_det REFCURSOR;
    DECLARE jreg_det    RECORD;
    DECLARE jsum_fact_bruto DECIMAL(12,2);
    DECLARE jsum_fact_neto  DECIMAL(12,2);
    DECLARE jgran_total     DECIMAL(14,2);
    DECLARE jquery_enc  VARCHAR;
    DECLARE jquery_det  VARCHAR;
    DECLARE jnom_cli    VARCHAR;

    BEGIN
        jgran_total = 0;
        jsum_fact_bruto = 0;
        jsum_fact_neto = 0;

        -- QUERY ENCABEZADO
        jquery_enc = 'SELECT f.id_factura, f.fecha_venta, f.val_tot_fact, 
                             c.prim_nom, c.prim_apell, 
                             e.nom_estado_fact
                      FROM tab_facturas f, tab_clientes c, tab_estado_fact e
                      WHERE f.id_cliente = c.id_cliente 
                      AND f.id_estado_fact = e.id_estado_fact
                      AND f.ind_vivo = TRUE
                      AND c.ind_vivo = TRUE
                      AND e.ind_vivo = TRUE
                      ORDER BY f.id_factura ASC';

        Raise notice '==================================================================================';
        Raise notice '                           REPORTE GENERAL DE VENTAS                              ';
        Raise notice '==================================================================================';

        OPEN jcursor_enc FOR EXECUTE jquery_enc;
            FETCH jcursor_enc INTO jreg_enc;
                WHILE FOUND LOOP
                
                jnom_cli = jreg_enc.prim_nom || ' ' || jreg_enc.prim_apell;
                
                Raise notice '----------------------------------------------------------------------------------';
                Raise notice 'FACTURA: %  |  FECHA: %  |  ESTADO: %', jreg_enc.id_factura, jreg_enc.fecha_venta, jreg_enc.nom_estado_fact;
                Raise notice 'CLIENTE: %', jnom_cli;
                Raise notice '----------------------------------------------------------------------------------';
                Raise notice '   ITEM | PRODUCTO                       | CANT |   PRECIO |    BRUTO |     NETO';

                -- QUERY DETALLE
                jquery_det = 'SELECT p.nombre_producto, d.cantidad, d.precio_unitario, d.val_bruto, d.val_neto 
                              FROM tab_detalle_facturas d, tab_productos p
                              WHERE d.id_producto = p.id_producto 
                              AND d.id_factura = ' || QUOTE_LITERAL(jreg_enc.id_factura) ||
                              ' AND d.ind_vivo = TRUE
                                AND p.ind_vivo = TRUE';

                    OPEN jcursor_det FOR EXECUTE jquery_det;
                        FETCH jcursor_det INTO jreg_det;
                            WHILE FOUND LOOP
                                Raise notice '   >    | % |  % | % | % | %', 
                                         RPAD(SUBSTRING(jreg_det.nombre_producto FROM 1 FOR 30), 30, ' '),
                                         jreg_det.cantidad, jreg_det.precio_unitario, jreg_det.val_bruto, jreg_det.val_neto;
                            
                            jsum_fact_neto = jsum_fact_neto + jreg_det.val_neto;
                            FETCH jcursor_det INTO jreg_det;
                        END LOOP;
                    CLOSE jcursor_det;
                    
                    Raise notice '                                                    ----------------------------';
                    Raise notice '                                                    TOTAL FACTURA: %', jreg_enc.val_tot_fact;
                    
                    jgran_total = jgran_total + jreg_enc.val_tot_fact;
                    jsum_fact_neto = 0;

                FETCH jcursor_enc INTO jreg_enc;
            END LOOP;
        CLOSE jcursor_enc;

        Raise notice '==================================================================================';
        Raise notice ' GRAN TOTAL VENTAS REPORTADAS: %', jgran_total;
        Raise notice '==================================================================================';
        Return TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error generando reporte: %', SQLERRM;
            RETURN FALSE;
    END;
$$
Language plpgsql;
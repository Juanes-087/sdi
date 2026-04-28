--SELECT fun_fact2(10,ARRAY[1,2],ARRAY[10,5],ARRAY[TRUE,TRUE],TRUE,5);
--SELECT id_producto FROM tab_det_fact;
--SELECT * FROM tab_clientes;
--SELECT * from tab_enc_fact;
--SELECT * FROM tab_pmtros;
--SELECT * FROM tab_det_fact;
--SELECT id_producto,nombre_producto,total_existencias,val_venta FROM tab_productos WHERE id_producto = 1 OR id_producto = 2 OR id_producto = 60;
CREATE OR REPLACE FUNCTION fun_fact2(wid_cliente tab_clientes.id_cliente%TYPE,
                                    wproductos              INTEGER[],
                                    wcantidades             INTEGER[],
                                    wind_descuento          BOOLEAN[],
                                    wind_forma_pago tab_enc_fact.ind_forma_pago%TYPE,
                                    wnum_caja tab_enc_fact.num_caja%TYPE) RETURNS BOOLEAN AS
$$
    DECLARE wnom_completo           VARCHAR;
    DECLARE wreg_pmtros             RECORD;   
    DECLARE wval_venta              tab_productos.val_venta%TYPE;
    DECLARE wtotal_existencias      tab_productos.total_existencias%TYPE;
    DECLARE wnombre_producto        tab_productos.nombre_producto%TYPE;
    DECLARE wreg_clientes           RECORD;
    DECLARE wid_factura             tab_enc_fact.id_factura%TYPE;
    wval_descuento                  tab_det_fact.val_descuento%TYPE;
    wval_iva                        tab_det_fact.val_iva%TYPE;
    wval_bruto                      tab_det_fact.val_bruto%TYPE;
    wval_neto                       tab_det_fact.val_neto%TYPE;
	dif_puntos					    INTEGER;

	BEGIN
		BEGIN
-- TRAEMOS LOS ATRIBUTOS DE PARÁMETROS PARA TENERLOS SIEMPRE PRESENTE EN LA FUNCIÓN PRINCIPAL
       SELECT a.id_empresa,a.nom_empresa,a.dir_empresa,a.val_poriva,a.val_pordesc,a.val_puntos,a.val_inifact,a.val_finfact,
               a.val_actfact,a.id_ciudad,b.nom_ciudad INTO wreg_pmtros  FROM tab_pmtros a, tab_ciudades b
        WHERE a.id_ciudad = b.id_ciudad;
		IF NOT FOUND THEN
			RAISE NOTICE ' No hay parametros en la tabla de parametros';
			RETURN FALSE;
		END IF;
-- VALIDACION DE CLIENTE
        SELECT id_cliente,nom_cliente,ape_cliente,ind_estado INTO wreg_clientes FROM tab_clientes
        WHERE id_cliente = wid_cliente;
        IF FOUND THEN
            IF wreg_clientes.ind_estado IS FALSE THEN
                RAISE 'Ese cliente nos debe plata o es una rata... no le facturamos...';
                RETURN FALSE;
			ELSE
				wnom_completo = wreg_clientes.nom_cliente || ' ' || wreg_clientes.ape_cliente;
            END IF;
        ELSE
            SELECT id_cliente,nom_cliente,ape_cliente,ind_estado INTO wreg_clientes FROM tab_clientes
            WHERE id_cliente = 22222222;
            IF FOUND THEN
                wnom_completo = wreg_clientes.nom_cliente || ' ' || wreg_clientes.ape_cliente;
                RAISE NOTICE 'Nombre del Cliente es %',wnom_completo;
            ELSE
                RAISE NOTICE 'Hay un error grave.. eL CÓDIGO 22222222 NO EXISTE... Vaya BRUTO QUE SOS';
                RETURN FALSE;
            END IF;
        END IF;
        IF array_length(wproductos, 1) IS NULL THEN
        RAISE EXCEPTION 'La lista de productos está vacía';
        RETURN FALSE;
    END IF;
--  VALIDAMOS QUE LOS ARRAYS TENGAN LA MISMA CANTIDAD DE DATOS
	dif_puntos = array_length(wproductos, 1) - array_length(wcantidades, 1);
    IF dif_puntos > 0 THEN
		RAISE NOTICE 'Hay % productos sin indicar cantidades',dif_puntos;
		RETURN FALSE;
		ELSE IF dif_puntos < 0 THEN
			dif_puntos = -(dif_puntos);
			RAISE NOTICE 'Faltan % productos ',dif_puntos;
			RETURN FALSE;
			END IF;
		END IF;
	dif_puntos = array_length(wproductos, 1) - array_length(wind_descuento, 1);
	IF dif_puntos > 0 THEN
		RAISE NOTICE 'Hay % productos sin indicar si aplica descuento',dif_puntos;
		RETURN FALSE;
	ELSE
        IF dif_puntos < 0 THEN
			dif_puntos:= -(dif_puntos);
			RAISE NOTICE 'Faltan % productos',dif_puntos;
			RETURN FALSE;
		END IF;
	END IF;
-- ARMAR EL ENCABEZADO DE LA FACTURA        
    IF wreg_pmtros.val_actfact >= wreg_pmtros.val_finfact THEN
        RAISE NOTICE '¡¡ ALERTA... UYYYYY ÚLTIMA FACTURA !!, no podrá seguir facturando... Vaya a la DIAN';
    END IF;
    wid_factura = wreg_pmtros.val_actfact;
                wreg_pmtros.val_actfact = wreg_pmtros.val_actfact + 1;
                UPDATE tab_pmtros SET val_actfact = wreg_pmtros.val_actfact;
                IF FOUND THEN
                    RAISE NOTICE 'Número de fact. % actualizada en Pmtros. Vamos bien, dijo el borracho',wreg_pmtros.val_actfact;
                ELSE
                    RAISE NOTICE 'Se totió la vuelta al actualizar pmtros...';
                    RETURN FALSE;
                END IF;
-- INSERT INTO tab_enc_fact VALUES 
                INSERT INTO tab_enc_fact VALUES(wid_factura,CURRENT_DATE,CURRENT_TIME,wreg_clientes.id_cliente,
                                                wreg_pmtros.id_ciudad,wnum_caja,0,TRUE,TRUE);
                IF FOUND THEN
                    RAISE NOTICE 'Encabezado de la factura % para el cliente %.% quedó listo...',wid_factura,
                                 wreg_clientes.id_cliente,wnom_completo;
                ELSE
                    RAISE NOTICE 'ERROR armando el Encabezado de la factura. Vaya para la nocturna y aprenda.....';
                    RETURN FALSE;
                END IF;

--          Iteramos la lista de productos
            FOR i IN 1..array_length(wproductos, 1) LOOP
--             Guardo cada nombre y valor de venta
               SELECT nombre_producto, val_venta INTO wnombre_producto,wval_venta 
				FROM tab_productos WHERE id_producto = wproductos[i];
				IF NOT FOUND THEN
					RAISE NOTICE 'Producto % no encontrado',wnombre_producto;
					CONTINUE;
				END IF;
    
-- 				Valido la cantidad del producto
				IF wcantidades[i] < 1 THEN
					RAISE NOTICE 'Error fatal nos quieren hacer el gol de la cantidad negativa, como hptas?';
	   				RAISE EXCEPTION USING ERRCODE = 'P0001';
			END IF;
                IF (SELECT fun_valida_cantidad(wproductos[i], wcantidades[i])) = FALSE THEN
					CONTINUE;
					ELSE
--              Calculo los valores para la tabla detalles
                wval_bruto := wval_venta * wcantidades[i];
                wval_iva   := (wval_bruto * (wreg_pmtros.val_poriva/100));
                IF wind_descuento[i] IS TRUE THEN
                    wval_descuento := wval_bruto*(wreg_pmtros.val_pordesc/100);
                ELSE
                    wval_descuento:= 0;
                END IF;
                wval_neto:= (wval_bruto - wval_descuento) + wval_iva;
--                  Hago la insercion en la tabla de detalles para cada producto en el arreglo
                    INSERT INTO tab_det_fact VALUES(wid_factura,wproductos[i],wcantidades[i],wval_descuento,wval_iva,wval_bruto,wval_neto);
                    IF NOT FOUND THEN
                        RAISE NOTICE 'Ha fallado en la insercion de detalles del producto';
                        RETURN FALSE;
--                   Si no hay problemas en la insercion llamo la funcion para actualizar el valor total de tab_enc_fact   
						ELSE
                        RAISE NOTICE 'Producto % facturado',wnombre_producto;
						IF (SELECT fun_update_valtotal(wid_factura,wval_neto)) = TRUE THEN
--                          Realizo la actualizacion al kardex de salida por venta
							IF (SELECT fun_act_kardex(wproductos[i],wcantidades[i],FALSE,2)) = TRUE THEN
						    RAISE NOTICE 'Kardex actualizado';
                            ELSE
                            RAISE NOTICE 'Kardex de producto % no se actualizo correctamente',wnombre_producto;							
							END IF;
						ELSE
                            RAISE NOTICE 'No se actualizo el total de la factura';
						 	RETURN FALSE;
						END IF;
					END IF;
				END IF;
            END LOOP;
--  Realizo la actualizacion de los puntos del cliente llamando la funcion
	IF (SELECT fun_update_puntos(wid_factura)) IS TRUE THEN 
        RAISE NOTICE 'Proceso de facturacion finalizado';
    ELSE
        RAISE NOTICE 'Algo fallo en el la actualizacion de puntos';
        RETURN FALSE;
   	 END IF;
-- Validamos que en  la tabla de detalles haya productos asociados a la factura encabezada
	IF (SELECT valida_end(wid_factura)) IS TRUE THEN
			RETURN TRUE;
	ELSE
		RAISE NOTICE 'No hay productos error fatal';
		RAISE EXCEPTION USING ERRCODE = 'P0001';
	END IF;
EXCEPTION
	WHEN SQLSTATE 'P0001' THEN
	RAISE NOTICE 'ROLLBACK';
	RETURN FALSE;
	END;
END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION valida_end(wid_factura		tab_det_fact.id_factura%TYPE) RETURNS BOOLEAN AS
$$
	DECLARE wid_producto			tab_det_fact.id_producto%TYPE;
	BEGIN
		SELECT a.id_producto INTO wid_producto FROM tab_det_fact a WHERE a.id_factura = wid_factura;
			IF FOUND THEN 
				RAISE NOTICE 'Hay datos en el encabezado de la factura';
				RETURN TRUE;
			ELSE 
				RAISE NOTICE 'No hay productos asociados en tab_detalles a la id de la factura';
				RETURN FALSE;
			END IF;
	END;
$$
LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION fun_valida_cantidad(wproducto  tab_productos.id_producto%TYPE,
                                               wcant      tab_productos.total_existencias%TYPE)RETURNS BOOLEAN AS
$$
DECLARE wtotal_existencias  tab_productos.total_existencias%TYPE;
DECLARE wnombre_producto    tab_productos.nombre_producto%TYPE;
BEGIN
--	 VALIDAMOS EL PRODUCTO Y TODO LO REFERENTE A EL PARA FACTURAR
	SELECT total_existencias,nombre_producto INTO wtotal_existencias,wnombre_producto FROM tab_productos
	WHERE id_producto = wproducto;
       IF FOUND THEN
            IF wcant <= wtotal_existencias THEN
            RETURN TRUE;
            ELSE
				RAISE NOTICE 'No hay suficiente stock para el producto %',wnombre_producto;
            RETURN FALSE;
			END IF;
		ELSE
			RAISE NOTICE 'Producto no encontrado %',wproducto;
			RETURN FALSE;
	END IF;
END;
$$
LANGUAGE PLPGSQL;



CREATE OR REPLACE FUNCTION fun_update_valtotal(wfactura   tab_enc_fact.id_factura%TYPE,
							wtotal     tab_enc_fact.val_tot_fact%TYPE) RETURNS BOOLEAN AS
$$
DECLARE
	wwfactura				tab_enc_fact.id_factura%TYPE;
BEGIN
SELECT wfactura INTO wwfactura FROM tab_enc_fact WHERE id_factura = wfactura;
IF FOUND THEN
	UPDATE tab_enc_fact
	SET val_tot_fact = val_tot_fact + wtotal
	WHERE id_factura = wfactura;
	IF FOUND THEN
	 RETURN TRUE;
	 ELSE RETURN FALSE;
	 END IF;
ELSE
	RAISE NOTICE 'Actualizacion de valor total en tab_enc_fact no fue exitosa, no se encontro la factura';
	RETURN FALSE;
	END IF;
END;
$$
LANGUAGE PLPGSQL;


CREATE OR REPLACE FUNCTION fun_update_puntos(wfactura    tab_enc_fact.id_factura%TYPE)
RETURNS BOOLEAN AS
$$
DECLARE
wid_cliente         tab_enc_fact.id_cliente%TYPE;
wtotalfact          tab_enc_fact.val_tot_fact%TYPE;
wpuntos             tab_clientes.val_puntos%TYPE;
    BEGIN 
        SELECT id_cliente,val_tot_fact INTO wid_cliente,wtotalfact 
        FROM tab_enc_fact
        WHERE id_factura = wfactura;
        wpuntos := (wtotalfact *10)/1000;
		IF wid_cliente = 22222222 THEN
			RETURN TRUE;
		ELSE
            UPDATE tab_clientes SET val_puntos = val_puntos + wpuntos
            WHERE id_cliente = wid_cliente;
            IF FOUND THEN
                RAISE NOTICE 'Puntos actualizados';
                RETURN TRUE;
            ELSE
                RAISE NOTICE 'No se actualizaron los puntos';
                RETURN FALSE;
            END IF;
	    END IF;
    END;
$$
LANGUAGE PLPGSQL;
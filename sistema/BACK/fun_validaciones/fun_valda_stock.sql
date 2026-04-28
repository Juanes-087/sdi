Create or replace function fun_verificar_stock_producto    (jid_producto tab_productos.id_producto%TYPE,
                                                                              jcantidad INT
                                                                              ) Returns Boolean As 
$$
      Declare
            jid_instrumento tab_instrumentos.id_instrumento%TYPE;
            jid_instrumento_kit tab_instrumentos_kit.id_instrumento_kit%TYPE;
            jid_kit tab_kits.id_kit%TYPE;

      Begin

-- Validación
      If jid_producto is NULL Then
            Raise Notice 'El id del producto está vacío.';
            Return False;
      End If;

      If jcantidad is NULL Then
            Raise Notice 'La cantidad no debe ser nula.';
            Return False;
      End If;

      If jcantidad <= 0 Then
            Raise Notice 'La cantidad debe ser mayor a 0.';
            Return False;
      End If;

      If jcantidad > 100 Then
            Raise Notice 'Cantidad exagerada, revise lo que desea facturar.';
            Return False;
      End If;

-- Mirar el tipo de producto que es, si es individual o kit armado
      Select id_instrumento, id_instrumento_kit Into jid_instrumento, jid_instrumento_kit
      From tab_productos 
      Where id_producto = jid_producto
      And ind_vivo = True;

-- Verificar si encontró el producto
      If not found Then
            Raise Notice 'Producto ID % no encontrado.', jid_producto;
            Return False;
      End If;

-- Decidir qué función llamar
      If jid_instrumento is not NULL Then
            -- Si es un instrumento individual entonces
            Return fun_valida_instrum(jid_instrumento, jcantidad);
      Else
            -- Si no es instrumento, debe ser kit entonces
            If jid_instrumento_kit is not NULL Then
                  Select id_kit Into jid_kit
                  From tab_instrumentos_kit 
                  Where id_instrumento_kit = jid_instrumento_kit
                  And ind_vivo = True;
            
                  If not found Then
                        Raise Notice 'Relación kit no encontrada para instrumento_kit ID: %.', jid_instrumento_kit;
                        Return False;
                  End If;
            
                  Return fun_valida_kit(jid_kit, jcantidad);
      Else
                  -- Caso inválido (ambos son NULL xd)
                  Raise Notice 'Producto ID % inválido - ambos IDs son NULL.', jid_producto;
                  Return False;
            End If;
      End If;


-- Excepciones
EXCEPTION
      When NO_DATA_FOUND Then
            Raise Notice 'Producto ID % no existe en la base de datos.', jid_producto;
            Return False;
        
      When TOO_MANY_ROWS Then
            Raise Notice 'Múltiples productos encontrados con ID % - error de integridad.', jid_producto;
            Return False;
        
      When NUMERIC_VALUE_OUT_OF_RANGE Then
            Raise Notice 'Error numérico en los datos del producto ID %.', jid_producto;
            Return False;
        
      When OTHERS Then
            Raise Notice 'Error inesperado al verificar stock del producto ID %: %.', jid_producto, SQLERRM;
            Return False;
      End;

$$
LANGUAGE plpgsql;
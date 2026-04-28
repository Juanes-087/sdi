Create or replace function fun_valida_kit (jid_kit tab_kits.id_kit%TYPE,
                                                      jcantidad tab_kits.cant_disp%TYPE
                                                      ) Returns Boolean As 
$$
      Declare
            jstock_actual INT;
      
      Begin

-- Validación 
      If jid_kit is NULL Then
            Raise Notice 'El id del kit está vacío, no se puede proceder con la validación de stock';
            Return False;
      End If;

      If jcantidad is NULL Then
            Raise Notice 'La cantidad del kit está vacía, no se puede proceder con la validación de stock';
            Return False;
      End If;

      If jcantidad <= 0 Then
            Raise Notice 'Valor inválido en la cantidad, tiene que ser mayor a 0';
            Return False;
      End If;

      If jcantidad > 50 Then
            Raise Notice 'Cantidad exagerada, revise lo que desea facturar.';
            Return False;
      End If;

-- Buscar cantidad disponible del kit
      Select cant_disp Into jstock_actual
      From tab_kits
      Where id_kit = jid_kit
      And ind_vivo = True;

-- Si no encuentra el kit, retorna false
      If not found Then
            Raise Notice 'Kit ID % no encontrado', jid_kit;
            Return False;
      End If;
    
      If jstock_actual >= jcantidad Then
            Raise Notice 'Stock suficiente: Kit %, Disponible: %, Solicitado: %', jid_kit, jstock_actual, jcantidad;  
            Return True;
      Else
            Raise Notice 'Stock insuficiente: Kit %, Disponible: %, Solicitado: %', jid_kit, jstock_actual, jcantidad;
            Return False;
      End If;

-- Excepciones
EXCEPTION
      When NO_DATA_FOUND Then
            Raise Notice 'Kit ID % no existe en la base de datos', jid_kit;
            Return False;
        
      When TOO_MANY_ROWS Then
            Raise Notice 'Múltiples kits encontrados con ID % - error de integridad', jid_kit;
            Return False;
        
      When NUMERIC_VALUE_OUT_OF_RANGE Then
            Raise Notice 'Error numérico en los datos del kit ID %', jid_kit;
            Return False;
        
      When OTHERS Then
            Raise Notice 'Error inesperado al verificar stock del kit ID %: %', jid_kit, SQLERRM;
            Return False;
      End;

$$ 
LANGUAGE plpgsql;
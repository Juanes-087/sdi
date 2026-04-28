-- Validacion para instrumentos individuales
Create or replace function fun_valida_instrum (jid_instrumento tab_instrumentos.id_instrumento%TYPE,
                                                            jcantidad tab_instrumentos.cant_disp%TYPE
                                                            ) Returns Boolean As 
$$
      Declare
            jstock_actual INT;
      
      Begin
    
-- Validacion 
      If jid_instrumento is NULL Then
            Raise Notice 'El id del instrumento está vacio, no se puede proceder con la validación de stock';
            Return False;
      End If;

      If jcantidad is NULL Then
            Raise Notice 'La cantidad del instrumento esta vacia, no se puede proceder con la validación de stock';
            Return False;
      End If;

      If jcantidad <= 0 Then
            Raise Notice 'Valor invalido en la cantidad, tiene que ser mayor a 0';
            Return False;
      End If;

      If jcantidad > 100 Then
            Raise Notice 'Cantidad exagerada, revise lo que desea facturar.';
            Return False;
      End If;

-- Buscar cantidad disponible del instrumento
      Select cant_disp Into jstock_actual
      From tab_instrumentos
      Where id_instrumento = jid_instrumento
      And ind_vivo = True;

-- Si no encuentra el instrumento o stock insuficiente, se retorna false
      If not found Then
            Raise Notice 'Instrumento ID % no encontrado', jid_instrumento;
            Return False;
      End If;
    
      If jstock_actual >= jcantidad Then
            Raise Notice 'Stock suficiente: Instrumento %, Disponible: %, Solicitado: %', jid_instrumento,jstock_actual, jcantidad;  
            Return True;
      Else
            Raise Notice 'Stock insuficiente: Instrumento %, Disponible: %, Solicitado: %', jid_instrumento, jstock_actual, jcantidad;
        Return False;
      End If;

-- Excepciones
EXCEPTION
      When NO_DATA_FOUND Then
            Raise Notice 'Instrumento ID % no existe en la base de datos', jid_instrumento;
            Return False;
        
      When TOO_MANY_ROWS Then
            Raise Notice 'Múltiples instrumentos encontrados con ID % - error de integridad', jid_instrumento;
            Return False;
        
      When NUMERIC_VALUE_OUT_OF_RANGE Then
            Raise Notice 'Error numérico en los datos del instrumento ID %', jid_instrumento;
            Return False;
        
      When OTHERS Then
            Raise Notice 'Error inesperado al verificar stock del instrumento ID %: %', jid_instrumento, SQLERRM;
            Return False;
      End;

$$ 
LANGUAGE plpgsql;
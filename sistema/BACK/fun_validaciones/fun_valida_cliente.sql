-- Select fun_valida_cliente(1);
-- Select fun_valida_cliente(NULL);
-- Select fun_valida_cliente(9999);
-- Select fun_valida_cliente(2);  -- Si existe uno con ind_vivo = false

Create or replace function fun_valida_cliente  (jid_cliente tab_clientes.id_cliente%TYPE
                                                ) Returns Boolean As
$$
    Declare
        jestado_cliente BOOLEAN;

    Begin
    
-- Validación
    If jid_cliente is NULL Then
        Raise notice 'El ID del cliente está vacío.';
        Return False;
    End If;

    If jid_cliente <= 0 Then
        Raise notice 'Ingrese un valor válido, el id tiene que ser mayor a 0.';
        Return False;
    End If;

-- Validar que el cliente exista y esté activo
    Select ind_vivo, TRUE Into jestado_cliente
    From tab_clientes 
    Where id_cliente = jid_cliente;

-- Si no encuentra el cliente
    If not found Then
        Raise notice 'Cliente ID % no existe en la base de datos.', jid_cliente;
        Return False;
    End If;

-- Validar que el cliente esté activo
    If jestado_cliente = False Then
        Raise notice 'Cliente ID % está inactivo (ind_vivo = FALSE).', jid_cliente;
        Return False;
    End If;


    Raise notice 'Cliente ID % validado correctamente.', jid_cliente;
    Return True;


-- Excepciones
EXCEPTION
    When NO_DATA_FOUND Then
        Raise notice 'Cliente ID % no encontrado.', jid_cliente;
        Return False;
        
    When TOO_MANY_ROWS Then
        Raise notice 'Múltiples clientes con ID % - error de integridad.', jid_cliente;
        Return False;
        
    When NUMERIC_VALUE_OUT_OF_RANGE Then
        Raise notice 'Error numérico en ID cliente: %.', jid_cliente;
        Return False;
        
    When OTHERS Then
        Raise notice 'Error inesperado validando cliente ID %: %.', jid_cliente, SQLERRM;
        Return False;
    End;
$$ 
LANGUAGE plpgsql;
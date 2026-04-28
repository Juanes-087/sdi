Drop table if exists tab_dev;
Drop table if exists tab_detalle_facturas;
Drop table if exists tab_facturas;
Drop table if exists tab_estado_fact;
Drop table if exists tab_productos;
Drop table if exists tab_instrumentos_kit;
Drop table if exists tab_kardex_productos;
Drop table if exists tab_kits;
Drop table if exists tab_instrumentos;
Drop table if exists tab_tipo_especializacion;
Drop table if exists tab_historico_mat_prima;
Drop table if exists tab_kardex_mat_prima;
Drop table if exists tab_producc;
Drop table if exists tab_bodega;
Drop table if exists tab_mat_primas_prov;
Drop table if exists tab_materias_primas;
Drop table if exists tab_cat_mat_prim;
Drop table if exists tab_clientes;
Drop table if exists tab_bancos_proveedor;
Drop table if exists tab_proveedores;
Drop table if exists tab_empleados;
Drop table if exists tab_bancos;
Drop table if exists tab_tipo_sangre;
Drop table if exists tab_cargos;
Drop table if exists tab_estado_empleados;
Drop table if exists tab_tipo_documentos;
Drop table if exists tab_unidades_medida;

Drop table if exists tab_ciudades;
Drop table if exists tab_departamentos;
Drop table if exists tab_users_menu;
Drop table if exists tab_menu;
Drop table if exists tab_users;
Drop table if exists tab_parametros;

-- Documentación completada: Todos los campos tienen comentarios inline
-- Agregar checks

-- Tabla de parametros generales
Create table tab_parametros 
(
        id_empresa DECIMAL(10, 0) NOT NULL, -- Identificador único de la empresa (NIT)
        nom_empresa VARCHAR NOT NULL, -- Nombre o razón social de la empresa
        dir_empresa VARCHAR NOT NULL, -- Dirección de la sede principal
        tel_empresa VARCHAR(10) NOT NULL, -- Teléfono principal de la empresa
        id_ciudad INT NOT NULL, -- Ciudad donde se ubica la sede principal
        val_pordesc DECIMAL(3, 0) NOT NULL DEFAULT 10 CHECK (
            val_pordesc >= 0
            AND val_pordesc <= 100), -- Porcentaje de descuento general aplicable a facturas (0-100)

        val_inifact DECIMAL(12) NOT NULL CHECK (
            val_inifact >= 1
            AND val_inifact <= val_finfact), -- Número inicial del rango de facturación autorizado

        val_finfact DECIMAL(12) NOT NULL CHECK (val_finfact >= val_inifact), -- Número final del rango de facturación autorizado
        val_actfact DECIMAL(12) NOT NULL CHECK (
            val_actfact >= val_inifact
            AND val_actfact <= val_finfact), -- Número actual de factura dentro del rango autorizado

        val_observa TEXT NOT NULL, -- Observaciones generales de la empresa
        ind_idle INT NOT NULL DEFAULT 30 CHECK (ind_idle >= 5 AND ind_idle <= 480), -- Timeout de sesión en minutos (5min - 8hrs) configurable por el administrador
        ind_salario DECIMAL(10, 2) NOT NULL DEFAULT 1423500.00, -- Salario base global
        reg_invima VARCHAR NOT NULL DEFAULT 'PENDIENTE', -- Registro INVIMA global
        Primary Key (id_empresa)
);

-- Tabla de usuarios
Create table tab_users 
(
        id_user INT NOT NULL, -- Identificador único del usuario
        nom_user VARCHAR NOT NULL, -- Nombre de usuario para login
        pass_user VARCHAR NOT NULL, -- Contraseña del usuario (hash)
        tel_user VARCHAR(10) NOT NULL, -- Teléfono de contacto del usuario (Solo números)
        mail_user VARCHAR(255) NOT NULL, -- Correo electrónico del usuario
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_user)
);

-- Tabla de menus
Create table tab_menu 
(
        id_menu INT NOT NULL, -- Identificador único del menú
        nom_menu VARCHAR NOT NULL, -- Nombre del módulo o sección del sistema
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_menu)
);

-- Tabla de usuarios por menu
Create table tab_users_menu
(
        id_user INT NOT NULL, -- FK al usuario
        id_menu INT NOT NULL, -- FK al menú
        nom_prog VARCHAR NOT NULL, -- nom del programa al que el usuario puede entrar o ejecutar
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_user, id_menu),
        Foreign Key (id_user) References tab_users (id_user),
        Foreign Key (id_menu) References tab_menu (id_menu)
);

-- Tabla de departamentos
Create table tab_departamentos 
(
        id_depart INT NOT NULL, -- Identificador del departamento (codigo del depart segun la DIAN)
        nom_depart VARCHAR NOT NULL, -- Nombre del departamento
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_depart)
);

-- Tabla de ciudades
Create table tab_ciudades 
(
        id_ciudad INT NOT NULL, -- Identificador de la ciudad (Codigo postal)
        id_depart INT NOT NULL, -- FK al departamento al cual pertenece la ciudad
        nom_ciudad VARCHAR NOT NULL, -- Nombre de la ciudad
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_ciudad),
        Foreign Key (id_depart) References tab_departamentos (id_depart)
);


-- Tabla de unidades de medida
Create table tab_unidades_medida
(
        id_unidad_medida INT NOT NULL, -- Identificador único de la unidad de medida
        nom_unidad VARCHAR NOT NULL, -- Nombre de la unidad (metros, milímetros, unidades, etc.)
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_unidad_medida)
);

-- Tabla de tipos de documentos
Create table tab_tipo_documentos 
(
        id_documento INT NOT NULL, -- Identificador único del tipo de documento
        nom_tipo_docum VARCHAR NOT NULL, -- Identificador de tipo de documento (Si es cedula, o tarjeta de identidad, documento extranjero, etc)
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_documento)
);

-- Tabla de estados de los empleados (Borrada corregir modelo relacional)
-- Se borro porque para que tengo el "ind_vivo" en los Audit Trail, si no es para eso mismo.
/*
Create table tab_estado_empleados
(
id_estado_empleado          INT         NOT NULL,
nom_estado                  VARCHAR     NOT NULL, -- Identifica el estado del empleado, Incapacitado, Inactivo, Licencia (Maternidad/Paternidad o Vacaciones), Suspendido(Temas disciplinarios/Investigaciones internas), Jubilado, Contrato terminado.
-- Audit Trail
Primary Key (id_estado_empleado)
);
 */

-- Tabla de cargos
Create table tab_cargos 
(
        id_cargo INT NOT NULL, -- Identificador único del cargo
        nom_cargo VARCHAR NOT NULL, -- Identificador de tipo de cargo (Si es Operario, Contador, Director Tecnico, Servicios generales)
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_cargo)
);

-- Tabla de tipos de sangre
Create table tab_tipo_sangre 
(
        id_tipo_sangre INT NOT NULL, -- Identificador único del tipo de sangre
        nom_tip_sang VARCHAR NOT NULL, -- Identificador de tipo de sangre (Si es A+, A-, B+, B-, O+, O-, AB+, AB-)
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_tipo_sangre)
);

-- Tabla de bancos
Create table tab_bancos 
(
        id_banco INT NOT NULL, -- Identificador único del banco
        id_ciudad INT NOT NULL, -- FK a la ciudad donde está ubicado el banco
        nom_banco VARCHAR NOT NULL, -- Nombre del banco
        dir_banco VARCHAR NOT NULL, -- Dirección de la sucursal bancaria
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_banco),
        Foreign Key (id_ciudad) References tab_ciudades (id_ciudad)
);

-- Tabla de empleados
Create table tab_empleados 
(
        id_empleado INT NOT NULL, -- Identificador único del empleado
        id_documento INT NOT NULL, -- FK al tipo de documento del empleado
        id_ciudad INT NOT NULL, -- FK a la ciudad de residencia del empleado
        id_cargo INT NOT NULL, -- Operario, Contador, Director Tecnico, Servicios generales, Gerente
        id_tipo_sangre INT NOT NULL, -- FK al tipo de sangre del empleado
        ind_genero INT NOT NULL CHECK (ind_genero IN (1, 2, 3)), -- 1=Masculino, 2=Femenino, 3=Otro
        num_documento VARCHAR(20) NOT NULL, -- Número de documento de identidad
        prim_nom VARCHAR(30) NOT NULL, -- Primer nombre del empleado
        segun_nom VARCHAR(30) NULL DEFAULT '', -- Segundo nombre del empleado (opcional)
        prim_apell VARCHAR(30) NOT NULL, -- Primer apellido del empleado
        segun_apell VARCHAR(30) NULL DEFAULT '', -- Segundo apellido del empleado (opcional)
        mail_empleado VARCHAR(255) NOT NULL, -- Correo electrónico del empleado
        tel_empleado VARCHAR(10) NOT NULL, -- Teléfono de contacto del empleado (Solo números)
        dir_emple VARCHAR(100) NOT NULL, -- Dirección de residencia del empleado
        ind_fecha_contratacion DATE NOT NULL, -- Fecha en la que fue contratado el empleado
        ind_peso DECIMAL(5, 2) NOT NULL CHECK (ind_peso > 40 AND ind_peso < 200), -- Peso del empleado en kilogramos (examen ocupacional)
        ind_altura DECIMAL(3, 2) NOT NULL CHECK (ind_altura > 1.30 AND ind_altura < 2.50), -- Altura en metros (1.70, 1.80, etc)
        ult_fec_exam DATE NOT NULL CHECK (ult_fec_exam <= CURRENT_DATE), -- Última fecha del examen médico ocupacional
        observ TEXT NOT NULL DEFAULT 'N/A', -- Por si tiene algun llamado de atencion, reconocimientos o esta incapacitado.
        -- Cuentas
        id_banco INT NOT NULL, -- Banco donde se consigna
        num_cuenta VARCHAR(20) NOT NULL, -- Número de cuenta bancaria para nómina (Solo números)
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_empleado),
        --Foreign Key (id_estado_empleado)    References tab_estado_empleados(id_estado_empleado),/
        Foreign Key (id_documento) References tab_tipo_documentos (id_documento),
        Foreign Key (id_ciudad) References tab_ciudades (id_ciudad),
        Foreign Key (id_cargo) References tab_cargos (id_cargo),
        Foreign Key (id_tipo_sangre) References tab_tipo_sangre (id_tipo_sangre),
        Foreign Key (id_banco) References tab_bancos (id_banco)
);

-- Tabla de proveedores
Create table tab_proveedores
(
        id_prov INT NOT NULL, -- Identificador único del proveedor
        id_documento INT NOT NULL, -- FK al tipo de documento del proveedor
        id_ciudad INT NOT NULL, -- FK a la ciudad del proveedor
        num_documento VARCHAR(20) NOT NULL, -- Número de documento del proveedor (NIT o CC)
        nom_prov VARCHAR NOT NULL, -- Nombre o razón social del proveedor
        tel_prov VARCHAR(10) NOT NULL, -- Teléfono de contacto del proveedor (Solo números)
        mail_prov VARCHAR NOT NULL, -- Correo electrónico del proveedor
        dir_prov VARCHAR NOT NULL, -- Dirección del proveedor
        ind_calidad TEXT NOT NULL DEFAULT 'N/A', -- Atributo para ingresar comentarios de calidad al proveedor  
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary key (id_prov),
        Foreign Key (id_documento) References tab_tipo_documentos (id_documento),
        Foreign Key (id_ciudad) References tab_ciudades (id_ciudad)
);

-- Tabla de bancos por proveedor
Create table tab_bancos_proveedor 
(
        id_prov INT NOT NULL, -- FK al proveedor
        id_banco INT NOT NULL, -- FK al banco
        num_cuenta VARCHAR(20) NOT NULL, -- Número de cuenta bancaria del proveedor (Solo números)
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_prov, id_banco),
        Foreign Key (id_prov) References tab_proveedores (id_prov),
        Foreign key (id_banco) References tab_bancos (id_banco)
);

-- Tabla de clientes
Create table tab_clientes 
(
        id_cliente INT NOT NULL, -- Identificador único del cliente
        id_documento INT NOT NULL, -- FK al tipo de documento del cliente
        id_ciudad INT NOT NULL, -- FK a la ciudad del cliente
        ind_genero INT NOT NULL CHECK (ind_genero IN (1, 2, 3)), -- 1=Masculino, 2=Femenino, 3=Otro
        prim_nom VARCHAR(30) NOT NULL, -- Primer nombre del cliente
        segun_nom VARCHAR(30) NULL, -- Segundo nombre del cliente (opcional)
        prim_apell VARCHAR(30) NOT NULL, -- Primer apellido del cliente
        segun_apell VARCHAR(30) NULL, -- Segundo apellido del cliente (opcional)
        num_documento VARCHAR(20) NOT NULL, -- Número de documento de identidad del cliente
        tel_cliente VARCHAR(10) NOT NULL, -- Teléfono de contacto del cliente (Solo números)
        dir_cliente VARCHAR(200) NOT NULL, -- Dirección de residencia del cliente
        ind_profesion VARCHAR(50) NOT NULL, -- Si es estudiante, o profesional de odontologia
        val_puntos DECIMAl(10,2) NOT NULL DEFAULT 0 CHECK (val_puntos >= 0), -- Puntos acumulados por el cliente
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_cliente),
        Foreign Key (id_documento) References tab_tipo_documentos (id_documento),
        Foreign Key (id_ciudad) References tab_ciudades (id_ciudad)
);

-- Tabla de categorias de la materia prima
Create table tab_cat_mat_prim 
(
        id_cat_mat INT NOT NULL, -- Identificador único de la categoría de materia prima
        nom_categoria VARCHAR NOT NULL, -- Varillas, Tornillos, Alambres, etc.
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_cat_mat)
);

-- Tabla de materias primas
Create table tab_materias_primas 
(
        id_mat_prima INT NOT NULL, -- Identificador único de la materia prima
        id_cat_mat INT NOT NULL, -- FK a la categoría de materia prima
        nom_materia_prima VARCHAR NOT NULL, -- Atributo para ingresar el nom de la materia prima.
        stock_min INT NOT NULL DEFAULT 0 CHECK (stock_min >= 0), -- Cantidad mínima en inventario antes de generar alerta
        stock_max INT NOT NULL DEFAULT 0 CHECK (stock_max >= 0), -- Cantidad máxima permitida en inventario
        img_url VARCHAR(255) NOT NULL, -- Imagen de la materia prima
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_mat_prima),
        Foreign Key (id_cat_mat) References tab_cat_mat_prim (id_cat_mat)
);

-- Tabla de materias primas por proveedor 
-- Ojito con las transacciones de esta tabla
Create table tab_mat_primas_prov 
(
        id_prov INT NOT NULL, -- FK al proveedor de la materia prima
        id_mat_prima INT NOT NULL, -- FK a la materia prima
        id_unidad_medida INT NOT NULL, -- FK a la unidad de medida asociada (m, mm, etc.)
        lote DECIMAl(3, 0) NOT NULL CHECK (lote >= 0),
        tipo_mat_prima VARCHAR NOT NULL, -- Para asignar el atributo si es una varilla (que tipo de varilla es: Aluminio, acero o tubing), alambre para puntas o tornillos para puntas.
        valor_medida DECIMAL(10,2) NOT NULL, -- Para ingresar la medida de la materia prima, si es una varilla su longitud (m), si es alambre su calibre (mm), si es tornillo su calibre (mm).
        cant_mat_prima DECIMAL(5, 0) NOT NULL CHECK (cant_mat_prima >= 0 AND cant_mat_prima <= 10000), -- La cantidad de materia prima que se ingreso
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_prov, id_mat_prima),
        Foreign Key (id_prov) References tab_proveedores (id_prov),
        Foreign Key (id_mat_prima) References tab_materias_primas (id_mat_prima),
        Foreign Key (id_unidad_medida) References tab_unidades_medida (id_unidad_medida)
);

-- Tabla de materia prima en bodega
Create table tab_bodega 
(
        id_movimiento INT NOT NULL, -- Identificador único del movimiento de bodega
        id_prov INT NOT NULL, -- FK al proveedor de la materia prima
        id_mat_prima INT NOT NULL, -- FK a la materia prima
        fec_ingreso TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW (), -- Fecha y hora de ingreso a bodega
        fec_salida TIMESTAMP WITHOUT TIME ZONE NULL DEFAULT NOW (), -- Fecha y hora de salida de bodega (NULL si aún está almacenada)
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_movimiento),
        Foreign Key (id_prov, id_mat_prima) References tab_mat_primas_prov
);

-- Tabla de materia prima que subio a producción
Create table tab_producc 
(
        id_producc INT NOT NULL, -- Identificador único del registro de producción
        id_movimiento INT NOT NULL, -- FK al movimiento de bodega que originó la salida a producción
        fec_ingreso TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW (), -- Fecha y hora de ingreso a producción
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_producc),
        Foreign Key (id_movimiento) References tab_bodega
);

-- Tabla para registrar movimientos y salidas del inventario de materia prima
Create table tab_kardex_mat_prima
(
        id_kardex_mat_prima INT NOT NULL, -- Identificador único del movimiento de kardex de materia prima
        id_materia_prima INT NOT NULL, -- FK a la materia prima involucrada en el movimiento
        id_unidad_medida INT NOT NULL, -- Para validar consistencia con tab_mat_primas_prov
        valor_medida DECIMAL(10,2) NOT NULL, -- Metadato del movimiento
        tipo_movimiento DECIMAL(1,0) NOT NULL 
        CHECK (tipo_movimiento > 0 AND tipo_movimiento <= 4),   -- Validar con numeros para hacer un CASE: 
                                                                                -- 1. Entrada a bodega por compra de materia prima, 
                                                                                -- 2. Salida de bodega a producción,
                                                                                -- 3. Ajuste de inventario (Re conteo), 
                                                                                -- 4. Salida del inventario por daño. 
        cantidad DECIMAL(8,2) NOT NULL CHECK (cantidad > 0),
        fecha_movimiento TIMESTAMP NOT NULL DEFAULT NOW(),
        observaciones TEXT NOT NULL DEFAULT 'N/A',
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_kardex_mat_prima),
        Foreign Key (id_materia_prima) References tab_materias_primas (id_mat_prima)
);

-- Tabla de histórico de precios de materia prima
Create table tab_historico_mat_prima
(
        id_historico INT NOT NULL, -- Identificador único del registro histórico
        id_materia_prima INT NOT NULL, -- FK a la materia prima
        id_proveedor INT NOT NULL, -- FK al proveedor
        precio_anterior DECIMAL(10,2) NOT NULL CHECK (precio_anterior >= 0), -- Precio antes del cambio
        precio_nuevo DECIMAL(10,2) NOT NULL CHECK (precio_nuevo >= 0), -- Precio después del cambio
        fecha_cambio TIMESTAMP NOT NULL DEFAULT NOW(), -- Fecha y hora en que se registró el cambio de precio
        motivo VARCHAR(100) NOT NULL DEFAULT 'N/A', -- Motivo o justificacion del cambio de precio (opcional)
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_historico),
        Foreign Key (id_materia_prima) References tab_materias_primas (id_mat_prima),
        Foreign Key (id_proveedor) References tab_proveedores (id_prov)
);

-- Tabla de especializaciones de los instrumentos
Create table tab_tipo_especializacion 
(
        id_especializacion INT NOT NULL, -- Identificador de especializacion del odontologo e instrumental (Si es de endodoncia, periodoncia, esterilizacion o es de estetica)
        nom_espec VARCHAR NOT NULL, -- Nombre de la especializacion
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_especializacion)
);

-- Esta tabla maneja los Instrumentos disponibles en el front
-- Tabla de instrumentos
Create table tab_instrumentos 
(
        id_instrumento INT NOT NULL, -- Identificador único del instrumento
        id_especializacion INT NOT NULL, -- FK a la especialización odontológica del instrumento
        nom_instrumento VARCHAR NOT NULL, -- Nombre del instrumento
        lote DECIMAL(3, 0) NOT NULL DEFAULT 0 CHECK (lote >= 0), -- Es el mismo lote de la materia prima.
        cant_disp DECIMAL(3, 0) NOT NULL CHECK (cant_disp >= 0), -- Cantidad disponible del instrumento.
        stock_min INT NOT NULL DEFAULT 0 CHECK (stock_min >= 0), -- Stock mínimo del instrumento antes de generar alerta
        stock_max INT NOT NULL DEFAULT 0 CHECK (stock_max >= 0), -- Stock máximo del instrumento
        numeral_en_kit DECIMAL(2, 0) NULL DEFAULT 0 CHECK (numeral_en_kit >= 0), -- Número de numeral en el kit
        tipo_mat INT NOT NULL CHECK (tipo_mat IN (1, 2)), -- 1 = Specialized (Acero), 2 = Special (Aluminio)
        img_url VARCHAR(255) NOT NULL, -- Atributo para cargar la imagen del instrumento.
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_instrumento),
        Foreign Key (id_especializacion) References tab_tipo_especializacion (id_especializacion)
);

-- Esta tabla maneja los Kits disponibles en el front
-- Tabla de kits
Create table tab_kits 
(
        id_kit INT NOT NULL, -- Identificador único del kit
        id_especializacion INT NOT NULL, -- Identificador de especializacion del odontologo e instrumental (Si es de endodoncia, periodoncia, esterilizacion o es de estetica)
        nom_kit VARCHAR NOT NULL, -- Nombre del kit
        cant_disp DECIMAL(3, 0) NOT NULL CHECK (cant_disp >= 0), -- Atributo para ver cuantos kits hay disponibles.
        tipo_mat INT NOT NULL CHECK (tipo_mat IN (1, 2)), -- 1 = Specialized (Acero), 2 = Special (Aluminio)
        stock_min INT NOT NULL DEFAULT 0 CHECK (stock_min >= 0), -- Stock mínimo del kit antes de generar alerta
        stock_max INT NOT NULL DEFAULT 0 CHECK (stock_max >= 0), -- Stock máximo del kit
        img_url VARCHAR(255) NOT NULL, -- Atributo para cargar la imagen del kit
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_kit),
        Foreign Key (id_especializacion) References tab_tipo_especializacion (id_especializacion)
);

-- Tabla para registrar movimientos y salidas del inventario de instrumentos / kits.
Create table tab_kardex_productos
(
        id_kardex_producto INT NOT NULL, -- Identificador único del movimiento de kardex de productos
        id_instrumento INT NULL, -- FK al instrumento involucrado (NULL si es un kit)
        id_kit INT NULL, CHECK ((id_instrumento IS NOT NULL AND id_kit IS NULL) OR (id_instrumento IS NULL AND id_kit IS NOT NULL)), -- FK al kit involucrado (NULL si es un instrumento)
        tipo_movimiento DECIMAL(1,0) NOT NULL 
        CHECK (tipo_movimiento > 0 AND tipo_movimiento <= 5),   -- Validar con numeros para hacer un CASE: 
                                                                                -- 1. Entrada (Producción terminada)
                                                                                -- 2. Salida (Venta)
                                                                                -- 3. Ajuste (+/-)
                                                                                -- 4. Pérdida/Daño    
                                                                                -- 5. Devolución
        cantidad DECIMAL(8,2) NOT NULL CHECK (cantidad > 0),
        fecha_movimiento TIMESTAMP NOT NULL DEFAULT NOW(),
        observaciones TEXT NOT NULL DEFAULT 'N/A',
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_kardex_producto),
        Foreign Key (id_instrumento) References tab_instrumentos (id_instrumento),
        Foreign Key (id_kit) References tab_kits (id_kit)
);

-- Tabla que maneja la relación muchos a muchos entre instrumentos y kits
-- Tabla instrumentos por kit
Create table tab_instrumentos_kit 
(
        id_instrumento_kit INT NOT NULL, -- Identificador único de la relación instrumento-kit
        id_kit INT NOT NULL, -- FK al kit
        id_instrumento INT NOT NULL, -- FK al instrumento que compone el kit
        cant_instrumento DECIMAl(2, 0) NOT NULL CHECK (cant_instrumento > 0 AND cant_instrumento <= 10), -- Atributo para ingresar la cantidad de instrumentos que van en un kit.
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_instrumento_kit),
        Foreign Key (id_kit) References tab_kits (id_kit),
        Foreign Key (id_instrumento) References tab_instrumentos (id_instrumento)
);

-- En fabricación por pedido no tiene sentido stock_min/max.
-- Tabla de productos
Create table tab_productos 
(
        id_producto INT NOT NULL, -- Identificador único del producto
        id_instrumento INT NULL, -- FK al instrumento (NULL si el producto es un kit)
        id_kit INT NULL, -- FK al kit (NULL si el producto es un instrumento)
        nombre_producto VARCHAR(30) NOT NULL, -- Nombre comercial del producto
        precio_producto DECIMAL(6, 0) NOT NULL CHECK (precio_producto >= 0), -- Precio unitario del producto xd
        img_url VARCHAR(255) NOT NULL, -- Imagen del producto
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_producto),
        Foreign Key (id_instrumento) References tab_instrumentos (id_instrumento),
        Foreign Key (id_kit) References tab_kits (id_kit),
        CHECK(
            (id_kit IS NOT NULL AND id_instrumento IS NULL) OR 
            (id_kit IS NULL AND id_instrumento IS NOT NULL)
        )
);

-- Tabla de estados de la factura
Create table tab_estado_fact
( 
    id_estado_fact INT NOT NULL CHECK (id_estado_fact > 0 AND id_estado_fact <= 4), -- Identificador del estado de la factura (1-4)
    nom_estado_fact VARCHAR(15) NOT NULL, -- 1 Pagada, 2 Pendiente, 3 Anulada, 4 Devuelta.
    -- Audit Trail
    user_insert VARCHAR NULL,
    fec_insert TIMESTAMP NULL,
    user_update VARCHAR NULL,
    fec_update TIMESTAMP NULL,
    user_delete VARCHAR NULL,
    fec_delete TIMESTAMP NULL,
    ind_vivo BOOLEAN NULL DEFAULT TRUE,
    Primary Key (id_estado_fact)
);

-- Tabla de encabezado de factura
Create table tab_facturas 
(
        id_factura INT NOT NULL, -- Identificador único de la factura (consecutivo del rango autorizado)
        id_cliente INT NOT NULL, -- FK al cliente que realiza la compra
        id_estado_fact INT NOT NULL, -- FK al estado actual de la factura
        ind_forma_pago INT NOT NULL 
        CHECK (ind_forma_pago > 0 AND ind_forma_pago <= 3), -- 1 Efectivo
                                                            -- 2 Transferencia
                                                            -- 3 Tarjeta
        fecha_venta TIMESTAMP WITHOUT TIME ZONE NOT NULL, -- Fecha y hora de emisión de la factura
        val_tot_fact DECIMAL(8) NOT NULL CHECK (val_tot_fact >= 0), -- Valor total de la factura
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_factura),
        Foreign Key (id_cliente) References tab_clientes (id_cliente),
        Foreign Key (id_estado_fact) References tab_estado_fact (id_estado_fact)
);

-- Tabla de devoluciones, Se debe agregar otra tabla para manejar los productos devueltos y evaluar si están en condición de agregarse
-- a la cantidad disponible del producto, pero como son kits los que se venden, complicado, problema para juan del futuro.
Create table tab_dev 
(
        id_factura INT NOT NULL, -- FK a la factura que se devuelve (también es PK)
        ind_observaciones VARCHAR NOT NULL DEFAULT 'N/A', -- Motivo o descripcion de la devolucion
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_factura),
        Foreign Key (id_factura) References tab_facturas
);

-- Tabla de detalles de facturas
Create table tab_detalle_facturas 
(
        id_detalle_factura INT NOT NULL, -- Identificador único del detalle de factura
        id_factura INT NOT NULL, -- FK a la factura a la que pertenece este detalle
        id_producto INT NOT NULL, -- FK al producto vendido
        cantidad DECIMAL(3, 0) NOT NULL CHECK (cantidad >= 0), -- Cantidad de unidades del producto en este detalle
        precio_unitario DECIMAL(10, 2) NOT NULL CHECK (precio_unitario >= 0), -- Precio unitario del producto al momento de la venta
        val_descuento DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (val_descuento >= 0), -- Valor del descuento aplicado a este detalle
        val_bruto DECIMAL (12,2) NOT NULL DEFAULT 0 CHECK (val_bruto >= 0), -- Valor bruto del detalle (cantidad * precio_unitario)
        val_neto DECIMAL (12,2) NOT NULL DEFAULT 0 CHECK (val_neto >= 0), -- Valor neto del detalle (val_bruto - val_descuento)
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_detalle_factura),
        Foreign Key (id_producto) References tab_productos (id_producto),
        Foreign Key (id_factura) References tab_facturas (id_factura)
);

-- Indices
Create unique index idx_nom_prov on tab_proveedores (nom_prov);
-- Create unique index idx_lote_instrumental on tab_instrumentos (lote); -- COMENTADO: El lote es opcional (default 0), esto impide crear mas de un instrumento sin lote.
Create unique index idx_nom_espec_instrumentos on tab_tipo_especializacion (nom_espec);
Create unique index idx_productos_nombre ON tab_productos(nombre_producto);
Create unique index idx_empleados_documento ON tab_empleados(id_documento, num_documento);

Create index idx_detalle_factura_producto ON tab_detalle_facturas(id_producto); -- Porque un producto puede estar en múltiples facturas
Create index idx_facturas_cliente_fecha ON tab_facturas(id_cliente, fecha_venta); -- Porque un cliente puede tener múltiples facturas en diferentes fechas  
Create index idx_kardex_fecha_tipo ON tab_kardex_mat_prima(fecha_movimiento, tipo_movimiento); -- Por múltiples movimientos del mismo tipo en la misma fechas


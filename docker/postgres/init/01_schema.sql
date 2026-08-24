-- ============================================================================
-- SCRIPT DE INICIALIZACIÓN 01: ESTRUCTURA DE TABLAS E ÍNDICES (DDL)
-- SPECIALIZED INSTRUMENTAL DENTAL
-- ============================================================================

Drop table if exists tab_detalle_facturas cascade;
Drop table if exists tab_devol_reparable cascade;
Drop table if exists tab_dev cascade;
Drop table if exists tab_facturas cascade;
Drop table if exists tab_estado_fact cascade;
Drop table if exists tab_productos cascade;
Drop table if exists tab_instrumentos_kit cascade;
Drop table if exists tab_kardex_productos cascade;
Drop table if exists tab_kits cascade;
Drop table if exists tab_instrumentos cascade;
Drop table if exists tab_tipo_especializacion cascade;
Drop table if exists tab_historico_mat_prima cascade;
Drop table if exists tab_kardex_mat_prima cascade;
Drop table if exists tab_producc cascade;
Drop table if exists tab_bodega cascade;
Drop table if exists tab_mat_primas_prov cascade;
Drop table if exists tab_materias_primas cascade;
Drop table if exists tab_cat_mat_prim cascade;
Drop table if exists tab_clientes cascade;
Drop table if exists tab_bancos_proveedor cascade;
Drop table if exists tab_proveedores cascade;
Drop table if exists tab_empleados cascade;
Drop table if exists tab_bancos cascade;
Drop table if exists tab_tipo_sangre cascade;
Drop table if exists tab_cargos cascade;
Drop table if exists tab_tipo_documentos cascade;
Drop table if exists tab_unidades_medida cascade;
Drop table if exists tab_ciudades cascade;
Drop table if exists tab_departamentos cascade;
Drop table if exists tab_users_menu cascade;
Drop table if exists tab_menu cascade;
Drop table if exists tab_users cascade;
Drop table if exists tab_parametros cascade;

-- Tabla de parametros generales
Create table tab_parametros 
(
        id_empresa DECIMAL(10, 0) NOT NULL,
        nom_empresa VARCHAR NOT NULL,
        dir_empresa VARCHAR NOT NULL,
        tel_empresa VARCHAR(10) NOT NULL CHECK (tel_empresa ~ '^[0-9]+$'),
        id_ciudad INT NOT NULL,
        val_pordesc DECIMAL(3, 0) NOT NULL DEFAULT 10 CHECK (val_pordesc >= 0 AND val_pordesc <= 100),
        val_inifact DECIMAL(12) NOT NULL CHECK (val_inifact >= 1 AND val_inifact <= val_finfact),
        val_finfact DECIMAL(12) NOT NULL CHECK (val_finfact >= val_inifact),
        val_actfact DECIMAL(12) NOT NULL CHECK (val_actfact >= val_inifact AND val_actfact <= val_finfact),
        val_observa TEXT NOT NULL,
        ind_idle INT NOT NULL DEFAULT 30 CHECK (ind_idle >= 5 AND ind_idle <= 480),
        ind_salario DECIMAL(10, 2) NOT NULL DEFAULT 1423500.00,
        reg_invima VARCHAR NOT NULL DEFAULT 'PENDIENTE',
        ind_tema BOOLEAN NOT NULL DEFAULT TRUE,
        ind_idioma VARCHAR(5) NOT NULL DEFAULT 'ES',
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_empresa)
);

-- Tabla de usuarios
Create table tab_users 
(
        id_user INT NOT NULL,
        nom_user VARCHAR NOT NULL CHECK (length(trim(nom_user)) > 0),
        pass_user VARCHAR NOT NULL,
        tel_user VARCHAR(10) NOT NULL CHECK (tel_user ~ '^[0-9]+$'),
        mail_user VARCHAR(255) NOT NULL CHECK (mail_user ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_user)
);

-- Tabla de menus
Create table tab_menu 
(
        id_menu INT NOT NULL,
        nom_menu VARCHAR NOT NULL,
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_menu)
);

-- Tabla de usuarios por menu
Create table tab_users_menu
(
        id_user INT NOT NULL,
        id_menu INT NOT NULL,
        nom_prog VARCHAR NOT NULL,
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_user, id_menu),
        Foreign Key (id_user) References tab_users (id_user),
        Foreign Key (id_menu) References tab_menu (id_menu)
);

-- Tabla de departamentos
Create table tab_departamentos 
(
        id_depart INT NOT NULL,
        nom_depart VARCHAR NOT NULL,
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_depart)
);

-- Tabla de ciudades
Create table tab_ciudades 
(
        id_ciudad INT NOT NULL,
        id_depart INT NOT NULL,
        nom_ciudad VARCHAR NOT NULL,
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_ciudad),
        Foreign Key (id_depart) References tab_departamentos (id_depart)
);

-- Tabla de unidades de medida
Create table tab_unidades_medida
(
        id_unidad_medida INT NOT NULL,
        nom_unidad VARCHAR NOT NULL,
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_unidad_medida)
);

-- Tabla de tipos de documentos
Create table tab_tipo_documentos 
(
        id_documento INT NOT NULL,
        nom_tipo_docum VARCHAR NOT NULL,
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_documento)
);

-- Tabla de cargos
Create table tab_cargos 
(
        id_cargo INT NOT NULL,
        nom_cargo VARCHAR NOT NULL,
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_cargo)
);

-- Tabla de tipos de sangre
Create table tab_tipo_sangre 
(
        id_tipo_sangre INT NOT NULL,
        nom_tip_sang VARCHAR NOT NULL,
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_tipo_sangre)
);

-- Tabla de bancos
Create table tab_bancos 
(
        id_banco INT NOT NULL,
        id_ciudad INT NOT NULL,
        nom_banco VARCHAR NOT NULL,
        dir_banco VARCHAR NOT NULL,
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_banco),
        Foreign Key (id_ciudad) References tab_ciudades (id_ciudad)
);

-- Tabla de empleados
Create table tab_empleados 
(
        id_empleado INT NOT NULL,
        id_documento INT NOT NULL,
        id_ciudad INT NOT NULL,
        id_cargo INT NOT NULL,
        id_tipo_sangre INT NOT NULL,
        ind_genero INT NOT NULL CHECK (ind_genero IN (1, 2, 3)),
        num_documento VARCHAR(20) NOT NULL CHECK (num_documento ~ '^[0-9]+$'),
        prim_nom VARCHAR(30) NOT NULL CHECK (length(trim(prim_nom)) >= 2),
        segun_nom VARCHAR(30) NULL DEFAULT '',
        prim_apell VARCHAR(30) NOT NULL CHECK (length(trim(prim_apell)) >= 2),
        segun_apell VARCHAR(30) NULL DEFAULT '',
        mail_empleado VARCHAR(255) NOT NULL CHECK (mail_empleado ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
        tel_empleado VARCHAR(10) NOT NULL CHECK (tel_empleado ~ '^[0-9]+$'),
        dir_emple VARCHAR(100) NOT NULL CHECK (length(trim(dir_emple)) > 0),
        ind_fecha_contratacion DATE NOT NULL CHECK (ind_fecha_contratacion <= CURRENT_DATE),
        ind_peso DECIMAL(5, 2) NOT NULL CHECK (ind_peso > 40 AND ind_peso < 200),
        ind_altura DECIMAL(3, 2) NOT NULL CHECK (ind_altura > 1.30 AND ind_altura < 2.50),
        ult_fec_exam DATE NOT NULL CHECK (ult_fec_exam <= CURRENT_DATE),
        observ TEXT NOT NULL DEFAULT 'N/A',
        id_banco INT NOT NULL,
        num_cuenta VARCHAR(20) NOT NULL CHECK (num_cuenta ~ '^[0-9]+$'),
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_empleado),
        Foreign Key (id_documento) References tab_tipo_documentos (id_documento),
        Foreign Key (id_ciudad) References tab_ciudades (id_ciudad),
        Foreign Key (id_cargo) References tab_cargos (id_cargo),
        Foreign Key (id_tipo_sangre) References tab_tipo_sangre (id_tipo_sangre),
        Foreign Key (id_banco) References tab_bancos (id_banco)
);

-- Tabla de proveedores
Create table tab_proveedores
(
        id_prov INT NOT NULL,
        id_documento INT NOT NULL,
        id_ciudad INT NOT NULL,
        num_documento VARCHAR(20) NOT NULL CHECK (num_documento ~ '^[0-9]+$'),
        nom_prov VARCHAR NOT NULL CHECK (length(trim(nom_prov)) > 0),
        tel_prov VARCHAR(10) NOT NULL CHECK (tel_prov ~ '^[0-9]+$'),
        mail_prov VARCHAR NOT NULL CHECK (mail_prov ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
        dir_prov VARCHAR NOT NULL CHECK (length(trim(dir_prov)) > 0),
        ind_calidad TEXT NOT NULL DEFAULT 'N/A',
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary key (id_prov),
        Foreign Key (id_documento) References tab_tipo_documentos (id_documento),
        Foreign Key (id_ciudad) References tab_ciudades (id_ciudad)
);

-- Tabla de bancos por proveedor
Create table tab_bancos_proveedor 
(
        id_prov INT NOT NULL,
        id_banco INT NOT NULL,
        num_cuenta VARCHAR(20) NOT NULL CHECK (num_cuenta ~ '^[0-9]+$'),
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_prov, id_banco),
        Foreign Key (id_prov) References tab_proveedores (id_prov),
        Foreign key (id_banco) References tab_bancos (id_banco)
);

-- Tabla de clientes
Create table tab_clientes 
(
        id_cliente INT NOT NULL,
        id_documento INT NOT NULL,
        id_ciudad INT NOT NULL,
        ind_genero INT NOT NULL CHECK (ind_genero IN (1, 2, 3)),
        prim_nom VARCHAR(30) NOT NULL CHECK (length(trim(prim_nom)) >= 2),
        segun_nom VARCHAR(30) NULL,
        prim_apell VARCHAR(30) NOT NULL CHECK (length(trim(prim_apell)) >= 2),
        segun_apell VARCHAR(30) NULL,
        num_documento VARCHAR(20) NOT NULL CHECK (num_documento ~ '^[0-9]+$'),
        tel_cliente VARCHAR(10) NOT NULL CHECK (tel_cliente ~ '^[0-9]+$'),
        dir_cliente VARCHAR(200) NOT NULL CHECK (length(trim(dir_cliente)) > 0),
        ind_profesion VARCHAR(50) NOT NULL CHECK (length(trim(ind_profesion)) > 0),
        val_puntos DECIMAl(10,2) NOT NULL DEFAULT 0 CHECK (val_puntos >= 0),
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_cliente),
        Foreign Key (id_documento) References tab_tipo_documentos (id_documento),
        Foreign Key (id_ciudad) References tab_ciudades (id_ciudad)
);

-- Tabla de categorias de la materia prima
Create table tab_cat_mat_prim 
(
        id_cat_mat INT NOT NULL,
        nom_categoria VARCHAR NOT NULL,
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_cat_mat)
);

-- Tabla de materias primas
Create table tab_materias_primas 
(
        id_mat_prima INT NOT NULL,
        id_cat_mat INT NOT NULL,
        nom_materia_prima VARCHAR NOT NULL,
        stock_min INT NOT NULL DEFAULT 0 CHECK (stock_min >= 0),
        stock_max INT NOT NULL DEFAULT 0 CHECK (stock_max >= 0 AND stock_min <= stock_max),
        img_url VARCHAR(255) NOT NULL,
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_mat_prima),
        Foreign Key (id_cat_mat) References tab_cat_mat_prim (id_cat_mat)
);

-- Tabla de materias primas por proveedor 
Create table tab_mat_primas_prov 
(
        id_prov INT NOT NULL,
        id_mat_prima INT NOT NULL,
        id_unidad_medida INT NOT NULL,
        lote DECIMAl(3, 0) NOT NULL CHECK (lote >= 0),
        tipo_mat_prima VARCHAR NOT NULL,
        valor_medida DECIMAL(10,2) NOT NULL,
        cant_mat_prima DECIMAL(5, 0) NOT NULL CHECK (cant_mat_prima >= 0 AND cant_mat_prima <= 10000),
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_prov, id_mat_prima),
        Foreign Key (id_prov) References tab_proveedores (id_prov),
        Foreign Key (id_mat_prima) References tab_materias_primas (id_mat_prima),
        Foreign Key (id_unidad_medida) References tab_unidades_medida (id_unidad_medida)
);

-- Tabla de materia prima en bodega
Create table tab_bodega 
(
        id_movimiento INT NOT NULL,
        id_prov INT NOT NULL,
        id_mat_prima INT NOT NULL,
        fec_ingreso TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW (),
        fec_salida TIMESTAMP WITHOUT TIME ZONE NULL DEFAULT NOW (),
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_movimiento),
        Foreign Key (id_prov, id_mat_prima) References tab_mat_primas_prov
);

-- Tabla de materia prima que subio a producción
Create table tab_producc 
(
        id_producc INT NOT NULL,
        id_movimiento INT NOT NULL,
        fec_ingreso TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW (),
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_producc),
        Foreign Key (id_movimiento) References tab_bodega
);

-- Tabla para registrar movimientos y salidas del inventario de materia prima
Create table tab_kardex_mat_prima
(
        id_kardex_mat_prima INT NOT NULL,
        id_materia_prima INT NOT NULL,
        id_unidad_medida INT NOT NULL,
        valor_medida DECIMAL(10,2) NOT NULL,
        tipo_movimiento DECIMAL(1,0) NOT NULL CHECK (tipo_movimiento > 0 AND tipo_movimiento <= 4),
        cantidad DECIMAL(8,2) NOT NULL CHECK (cantidad > 0),
        fecha_movimiento TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        observaciones TEXT NOT NULL DEFAULT 'N/A',
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_kardex_mat_prima),
        Foreign Key (id_materia_prima) References tab_materias_primas (id_mat_prima),
        Foreign Key (id_unidad_medida) References tab_unidades_medida (id_unidad_medida)
);

-- Tabla de histórico de precios de materia prima
Create table tab_historico_mat_prima
(
        id_historico INT NOT NULL,
        id_materia_prima INT NOT NULL,
        id_proveedor INT NOT NULL,
        precio_anterior DECIMAL(10,2) NOT NULL CHECK (precio_anterior >= 0),
        precio_nuevo DECIMAL(10,2) NOT NULL CHECK (precio_nuevo >= 0),
        fecha_cambio TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        motivo VARCHAR(100) NOT NULL DEFAULT 'N/A',
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_historico),
        Foreign Key (id_materia_prima) References tab_materias_primas (id_mat_prima),
        Foreign Key (id_proveedor) References tab_proveedores (id_prov)
);

-- Tabla de especializaciones de los instrumentos
Create table tab_tipo_especializacion 
(
        id_especializacion INT NOT NULL,
        nom_espec VARCHAR NOT NULL,
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_especializacion)
);

-- Tabla de instrumentos
Create table tab_instrumentos 
(
        id_instrumento INT NOT NULL,
        id_especializacion INT NOT NULL,
        nom_instrumento VARCHAR NOT NULL,
        lote DECIMAL(3, 0) NOT NULL DEFAULT 0 CHECK (lote >= 0),
        cant_disp DECIMAL(3, 0) NOT NULL CHECK (cant_disp >= 0),
        stock_min INT NOT NULL DEFAULT 0 CHECK (stock_min >= 0),
        stock_max INT NOT NULL DEFAULT 0 CHECK (stock_max >= 0 AND stock_min <= stock_max),
        numeral_en_kit DECIMAL(2, 0) NULL DEFAULT 0 CHECK (numeral_en_kit >= 0),
        tipo_mat INT NOT NULL CHECK (tipo_mat IN (1, 2)),
        img_url VARCHAR(255) NOT NULL,
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_instrumento),
        Foreign Key (id_especializacion) References tab_tipo_especializacion (id_especializacion)
);

-- Tabla de kits
Create table tab_kits 
(
        id_kit INT NOT NULL,
        id_especializacion INT NOT NULL,
        nom_kit VARCHAR NOT NULL,
        cant_disp DECIMAL(3, 0) NOT NULL CHECK (cant_disp >= 0),
        tipo_mat INT NOT NULL CHECK (tipo_mat IN (1, 2)),
        stock_min INT NOT NULL DEFAULT 0 CHECK (stock_min >= 0),
        stock_max INT NOT NULL DEFAULT 0 CHECK (stock_max >= 0 AND stock_min <= stock_max),
        img_url VARCHAR(255) NOT NULL,
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_kit),
        Foreign Key (id_especializacion) References tab_tipo_especializacion (id_especializacion)
);

-- Tabla para registrar movimientos y salidas del inventario de instrumentos / kits.
Create table tab_kardex_productos
(
        id_kardex_producto INT NOT NULL,
        id_instrumento INT NULL,
        id_kit INT NULL, CHECK ((id_instrumento IS NOT NULL AND id_kit IS NULL) OR (id_instrumento IS NULL AND id_kit IS NOT NULL)),
        tipo_movimiento DECIMAL(1,0) NOT NULL CHECK (tipo_movimiento > 0 AND tipo_movimiento <= 5),
        cantidad DECIMAL(8,2) NOT NULL CHECK (cantidad > 0),
        fecha_movimiento TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
        observaciones TEXT NOT NULL DEFAULT 'N/A',
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_kardex_producto),
        Foreign Key (id_instrumento) References tab_instrumentos (id_instrumento),
        Foreign Key (id_kit) References tab_kits (id_kit)
);

-- Tabla instrumentos por kit
Create table tab_instrumentos_kit 
(
        id_instrumento_kit INT NOT NULL,
        id_kit INT NOT NULL,
        id_instrumento INT NOT NULL,
        cant_instrumento DECIMAl(2, 0) NOT NULL CHECK (cant_instrumento >= 1 AND cant_instrumento <= 10),
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_instrumento_kit),
        Foreign Key (id_kit) References tab_kits (id_kit),
        Foreign Key (id_instrumento) References tab_instrumentos (id_instrumento)
);

-- Tabla de productos
Create table tab_productos 
(
        id_producto INT NOT NULL,
        id_instrumento INT NULL,
        id_kit INT NULL,
        nombre_producto VARCHAR(30) NOT NULL,
        precio_producto DECIMAL(6, 0) NOT NULL CHECK (precio_producto >= 0),
        img_url VARCHAR(255) NOT NULL,
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
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
    id_estado_fact INT NOT NULL CHECK (id_estado_fact > 0 AND id_estado_fact <= 4),
    nom_estado_fact VARCHAR(15) NOT NULL,
    -- Audit Trail
    user_insert VARCHAR NULL,
    fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
    user_update VARCHAR NULL,
    fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
    user_delete VARCHAR NULL,
    fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
    ind_vivo BOOLEAN NULL DEFAULT TRUE,
    Primary Key (id_estado_fact)
);

-- Tabla de encabezado de factura
Create table tab_facturas 
(
        id_factura INT NOT NULL,
        id_cliente INT NOT NULL,
        id_estado_fact INT NOT NULL,
        ind_forma_pago INT NOT NULL CHECK (ind_forma_pago > 0 AND ind_forma_pago <= 3),
        fecha_venta TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        val_tot_fact DECIMAL(8) NOT NULL CHECK (val_tot_fact >= 0),
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_factura),
        Foreign Key (id_cliente) References tab_clientes (id_cliente),
        Foreign Key (id_estado_fact) References tab_estado_fact (id_estado_fact)
);

-- Tabla de devoluciones
Create table tab_dev 
(
        id_factura INT NOT NULL,
        ind_observaciones VARCHAR NOT NULL DEFAULT 'N/A',
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_factura),
        Foreign Key (id_factura) References tab_facturas
);

-- Tabla de devoluciones pendientes
Create table tab_devol_reparable
(
        id_devol_reparable INT,
        id_factura INT NOT NULL,
        id_producto INT NOT NULL,
        cantidad DECIMAL(3,0) NOT NULL CHECK (cantidad > 0),
        id_estado_devol INT NOT NULL DEFAULT 1 CHECK (id_estado_devol IN (1, 2, 3)),
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_devol_reparable),
        Foreign Key (id_factura) References tab_facturas (id_factura),
        Foreign Key (id_producto) References tab_productos (id_producto)
);

-- Tabla de detalles de facturas
Create table tab_detalle_facturas 
(
        id_detalle_factura INT NOT NULL,
        id_factura INT NOT NULL,
        id_producto INT NOT NULL,
        cantidad DECIMAL(3, 0) NOT NULL CHECK (cantidad >= 0),
        precio_unitario DECIMAL(10, 2) NOT NULL CHECK (precio_unitario >= 0),
        val_descuento DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (val_descuento >= 0),
        val_bruto DECIMAL (12,2) NOT NULL DEFAULT 0 CHECK (val_bruto >= 0),
        val_neto DECIMAL (12,2) NOT NULL DEFAULT 0 CHECK (val_neto >= 0),
        -- Audit Trail
        user_insert VARCHAR NULL,
        fec_insert TIMESTAMP WITHOUT TIME ZONE NULL,
        user_update VARCHAR NULL,
        fec_update TIMESTAMP WITHOUT TIME ZONE NULL,
        user_delete VARCHAR NULL,
        fec_delete TIMESTAMP WITHOUT TIME ZONE NULL,
        ind_vivo BOOLEAN NOT NULL DEFAULT TRUE,
        Primary Key (id_detalle_factura),
        Foreign Key (id_producto) References tab_productos (id_producto),
        Foreign Key (id_factura) References tab_facturas (id_factura)
);

-- Índices de Rendimiento y Unicidad
Create unique index idx_nom_prov on tab_proveedores (nom_prov);
Create unique index idx_nom_espec_instrumentos on tab_tipo_especializacion (nom_espec);
Create unique index idx_productos_nombre ON tab_productos(nombre_producto);
Create unique index idx_empleados_documento ON tab_empleados(id_documento, num_documento);

Create index idx_detalle_factura_producto ON tab_detalle_facturas(id_producto);
Create index idx_facturas_cliente_fecha ON tab_facturas(id_cliente, fecha_venta);
Create index idx_kardex_fecha_tipo ON tab_kardex_mat_prima(fecha_movimiento, tipo_movimiento);

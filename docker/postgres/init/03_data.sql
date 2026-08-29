-- ============================================================================
-- SCRIPT DE INICIALIZACIÓN 03: DATOS MAESTROS INDISPENSABLES PARA PRODUCCIÓN
-- SPECIALIZED INSTRUMENTAL DENTAL
-- ============================================================================

-- 1. Parámetros de la Empresa
INSERT INTO tab_parametros (id_empresa, nom_empresa, dir_empresa, tel_empresa, id_ciudad, val_pordesc, val_inifact, val_finfact, val_actfact, val_observa, ind_idle, ind_salario, reg_invima, ind_tema, ind_idioma) VALUES 
(1, 'Specialized Instrumental Dental', 'Cl. 45 #28-15, Bucaramanga', 3006438791, 68077, 0, 1000, 9999, 1500, 'Fabricantes de instrumentación odontológica especializada', 30, 1423500.00, 'INVIMA-2024-GLOBAL', TRUE, 'ES')
ON CONFLICT (id_empresa) DO NOTHING;

-- 2. Tipos de Documentos
INSERT INTO tab_tipo_documentos (id_documento, nom_tipo_docum) VALUES 
(1, 'Cédula de Ciudadanía'),
(2, 'Tarjeta de Identidad'),
(3, 'Cédula de Extranjería'),
(4, 'NIT'),
(5, 'Pasaporte')
ON CONFLICT (id_documento) DO NOTHING;

-- 3. Departamentos Principales
INSERT INTO tab_departamentos (id_depart, nom_depart) VALUES 
(5, 'Antioquia'),
(8, 'Atlántico'),
(11, 'Bogotá D.C.'),
(13, 'Bolívar'),
(15, 'Boyacá'),
(17, 'Caldas'),
(18, 'Caquetá'),
(19, 'Cauca'),
(20, 'Cesar'),
(23, 'Córdoba'),
(25, 'Cundinamarca'),
(27, 'Chocó'),
(41, 'Huila'),
(44, 'La Guajira'),
(47, 'Magdalena'),
(50, 'Meta'),
(52, 'Nariño'),
(54, 'Norte de Santander'),
(63, 'Quindío'),
(66, 'Risaralda'),
(68, 'Santander'),
(70, 'Sucre'),
(76, 'Valle del Cauca')
ON CONFLICT (id_depart) DO NOTHING;

-- 4. Ciudades Principales
INSERT INTO tab_ciudades (id_ciudad, id_depart, nom_ciudad) VALUES
(5001, 5, 'Medellín'),
(8001, 8, 'Barranquilla'),
(11001, 11, 'Bogotá'),
(13001, 13, 'Cartagena'),
(15001, 15, 'Tunja'),
(17001, 17, 'Manizales'),
(18001, 18, 'Florencia'),
(19001, 19, 'Popayán'),
(20001, 20, 'Valledupar'),
(23001, 23, 'Montería'),
(25001, 25, 'Bogotá'),
(27001, 27, 'Quibdó'),
(41001, 41, 'Neiva'),
(44001, 44, 'Riohacha'),
(47001, 47, 'Santa Marta'),
(50001, 50, 'Villavicencio'),
(52001, 52, 'Pasto'),
(54001, 54, 'Cúcuta'),
(63001, 63, 'Armenia'),
(66001, 66, 'Pereira'),
(68001, 68, 'Bucaramanga'),
(68077, 68, 'Floridablanca'),
(68132, 68, 'Girón'),
(68573, 68, 'Piedecuesta'),
(76001, 76, 'Cali')
ON CONFLICT (id_ciudad) DO NOTHING;

-- 5. Tipos de Sangre
INSERT INTO tab_tipo_sangre (id_tipo_sangre, nom_tip_sang) VALUES
(1, 'O+'),
(2, 'O-'),
(3, 'A+'),
(4, 'A-'),
(5, 'B+'),
(6, 'B-'),
(7, 'AB+'),
(8, 'AB-')
ON CONFLICT (id_tipo_sangre) DO NOTHING;

-- 6. Unidades de Medida
INSERT INTO tab_unidades_medida (id_unidad_medida, nom_unidad) VALUES
(1, 'g'),
(2, 'kg'),
(3, 'mm'),
(4, 'cm'),
(5, 'm'),
(6, 'unidades')
ON CONFLICT (id_unidad_medida) DO NOTHING;

-- 7. Especializaciones Odontológicas
INSERT INTO tab_tipo_especializacion (id_especializacion, nom_espec) VALUES
(1, 'Estética'),
(2, 'Endodoncia'),
(3, 'Periodoncia'),
(4, 'Pediátrico'),
(5, 'Rehabilitación'),
(6, 'Laboratorio'),
(7, 'Cirugía Oral'),
(8, 'Operatoria'),
(9, 'Ortodoncia'),
(10, 'Examen')
ON CONFLICT (id_especializacion) DO NOTHING;

-- 8. Estados de Factura
INSERT INTO tab_estado_fact (id_estado_fact, nom_estado_fact) VALUES
(1, 'Pagada'),
(2, 'Pendiente'),
(3, 'Anulada'),
(4, 'Devuelta')
ON CONFLICT (id_estado_fact) DO NOTHING;

-- 9. Menús del Sistema
INSERT INTO tab_menu (id_menu, nom_menu) VALUES
(1, 'Gestión de Usuarios'),
(2, 'Gestión de Productos'),
(3, 'Gestión de Ventas'),
(4, 'Reportes'),
(5, 'Inventario'),
(6, 'Compras'),
(7, 'Producción'),
(8, 'Clientes'),
(9, 'Proveedores'),
(10, 'Empleados'),
(11, 'Facturación'),
(12, 'Kardex'),
(13, 'Bodega'),
(14, 'Estadísticas'),
(15, 'Auditoría'),
(16, 'Configuración'),
(17, 'Backup'),
(18, 'Catálogos'),
(19, 'Dashboard'),
(20, 'Ayuda')
ON CONFLICT (id_menu) DO NOTHING;

-- 10. Cargos Organizacionales
INSERT INTO tab_cargos (id_cargo, nom_cargo) VALUES
(1, 'Operario de Producción'),
(2, 'Oficios Varios'),
(3, 'Supervisor de Producción'),
(4, 'Jefe de Producción'),
(5, 'Auxiliar de Bodega'),
(6, 'Coordinador de Calidad'),
(7, 'Analista de Control Calidad'),
(8, 'Asistente Administrativo'),
(9, 'Auxiliar Contable'),
(10, 'Analista de Compras'),
(11, 'Coordinador de Ventas'),
(12, 'Asesor Comercial'),
(13, 'Recepcionista'),
(14, 'Auxiliar de Sistemas'),
(15, 'Coordinador de Logística'),
(16, 'Gerente General'),
(17, 'Subgerente Operativo'),
(18, 'Auditor Interno'),
(19, 'Coordinador de Producción'),
(20, 'Aprendiz SENA')
ON CONFLICT (id_cargo) DO NOTHING;

-- 11. Bancos
INSERT INTO tab_bancos (id_banco, id_ciudad, nom_banco, dir_banco) VALUES
(1, 68001, 'Bancolombia', 'Cl. 50 #42-20, Bucaramanga'),
(2, 11001, 'Banco de Bogotá', 'Cra 7 #14-78, Bogotá'),
(3, 5001, 'Banco Popular', 'Cl. 52 #45-10, Medellín'),
(4, 8001, 'BBVA Colombia', 'Cra 54 #68-120, Barranquilla'),
(5, 13001, 'Davivienda', 'Centro, Cra 8 #12-65, Cartagena')
ON CONFLICT (id_banco) DO NOTHING;

-- 12. Categorías de Materia Prima
INSERT INTO tab_cat_mat_prim (id_cat_mat, nom_categoria) VALUES
(1, 'Varillas'),
(2, 'Tornillos'),
(3, 'Alambres')
ON CONFLICT (id_cat_mat) DO NOTHING;

-- 13. Usuario Administrador Inicial
-- Contraseña hash bcrypt o texto plano temporal según esquema: 'Admin123*'
INSERT INTO tab_users (id_user, nom_user, pass_user, tel_user, mail_user) VALUES
(1, 'admin', '$2y$12$eImiTXuWVxfM37uY4JANjOL.PbgFek7qM9hK9uH0N5mHhE1bWvG6O', '3001234567', 'admin@dental.com')
ON CONFLICT (id_user) DO NOTHING;

-- 14. Asignación de Permisos para el Administrador
INSERT INTO tab_users_menu (id_user, id_menu, nom_prog) VALUES
(1, 1, 'usuarios.php'),
(1, 2, 'productos.php'),
(1, 3, 'ventas.php'),
(1, 4, 'reportes.php'),
(1, 5, 'inventario.php'),
(1, 6, 'compras.php'),
(1, 7, 'produccion.php'),
(1, 8, 'clientes.php'),
(1, 9, 'proveedores.php'),
(1, 10, 'empleados.php'),
(1, 19, 'dashboard.php')
ON CONFLICT (id_user, id_menu) DO NOTHING;

-- 15. Cliente Genérico por Defecto (Para ventas sin identificación formal)
INSERT INTO tab_clientes (id_cliente, id_documento, id_ciudad, ind_genero, prim_nom, segun_nom, prim_apell, segun_apell, num_documento, tel_cliente, dir_cliente, ind_profesion, val_puntos) VALUES
(99999, 1, 68573, 3, 'Cliente', NULL, 'Genérico', NULL, '999999999', '3009999999', 'Cra #1 Calle Genérica 2', 'Profesión nula', 0)
ON CONFLICT (id_cliente) DO NOTHING;

-- ============================================================================
-- NOTA PARA PRODUCCIÓN: 
-- Los datos de prueba y semillas (empleados adicionales, facturas simuladas, 
-- proveedores de prueba) se encuentran en '04_seeds_opcional.sql.example'.
-- ============================================================================

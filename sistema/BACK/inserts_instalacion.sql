-- SCRIPT COMPLETO DE INSERTS - SPECIALIZED INSTRUMENTAL DENTAL
-- VERSIÓN CORREGIDA - Audit Trail automático

-- 1. tab_parametros (1 registro)
INSERT INTO tab_parametros (id_empresa, nom_empresa, dir_empresa, tel_empresa, id_ciudad, val_pordesc, val_inifact, val_finfact, val_actfact, val_observa, ind_idle, ind_salario, reg_invima, ind_tema, ind_idioma) VALUES 
(1, 'Specialized Instrumental Dental', 'Cl. 45 #28-15, Bucaramanga', 3006438791, 68077, 0, 1000, 9999, 1500, 'Fabricantes de instrumentación odontológica especializada', 30, 1423500.00, 'INVIMA-2024-GLOBAL', TRUE, 'ES');

-- 2. tab_tipo_documentos (5 tipos)
INSERT INTO tab_tipo_documentos (id_documento, nom_tipo_docum) VALUES 
(1, 'Cédula de Ciudadanía'),
(2, 'Tarjeta de Identidad'),
(3, 'Cédula de Extranjería'),
(4, 'NIT'),
(5, 'Pasaporte');

-- 3. tab_departamentos (23 departamentos Colombia)
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
(76, 'Valle del Cauca');

-- 4. tab_ciudades (25 ciudades principales Colombia)
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
(76001, 76, 'Cali');

-- 5. tab_users (20 usuarios)
INSERT INTO tab_users (id_user, nom_user, pass_user, tel_user, mail_user) VALUES
(1, 'admin', 'admin123', 3001234567, 'admin@dental.com'),
(2, 'recepcion', 'rece123', 3007654321, 'recepcion@dental.com'),
(3, 'ventas', 'ventas123', 3001112233, 'ventas@dental.com'),
(4, 'inventario', 'inv123', 3004445566, 'inventario@dental.com'),
(5, 'produccion', 'prod123', 3007778899, 'produccion@dental.com'),
(6, 'calidad', 'cal123', 3002223344, 'calidad@dental.com'),
(7, 'compras', 'comp123', 3005556677, 'compras@dental.com'),
(8, 'gerencia', 'ger123', 3008889900, 'gerencia@dental.com'),
(9, 'contabilidad', 'cont123', 3003334455, 'contabilidad@dental.com'),
(10, 'soporte', 'sop123', 3006667788, 'soporte@dental.com'),
(11, 'operario1', 'op123', 3009990011, 'operario1@dental.com'),
(12, 'operario2', 'op123', 3004441122, 'operario2@dental.com'),
(13, 'operario3', 'op123', 3007772233, 'operario3@dental.com'),
(14, 'operario4', 'op123', 3008883344, 'operario4@dental.com'),
(15, 'operario5', 'op123', 3001114455, 'operario5@dental.com'),
(16, 'supervisor', 'sup123', 3002225566, 'supervisor@dental.com'),
(17, 'auditor', 'aud123', 3003336677, 'auditor@dental.com'),
(18, 'asesor', 'ase123', 3004447788, 'asesor@dental.com'),
(19, 'coordinador', 'coord123', 3005558899, 'coordinador@dental.com'),
(20, 'auxiliar', 'aux123', 3006669900, 'auxiliar@dental.com');

-- 6. tab_menu (20 menús)
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
(20, 'Ayuda');

-- 7. tab_users_menu (20 asignaciones)
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
(2, 3, 'ventas.php'),
(2, 8, 'clientes.php'),
(3, 2, 'productos.php'),
(3, 3, 'ventas.php'),
(4, 5, 'inventario.php'),
(4, 12, 'kardex.php'),
(5, 7, 'produccion.php'),
(6, 15, 'auditoria.php'),
(7, 6, 'compras.php'),
(8, 19, 'dashboard.php');

-- 8. tab_cargos (20 cargos)
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
(20, 'Aprendiz SENA');

-- 10. tab_tipo_sangre (8 tipos de sangre)
INSERT INTO tab_tipo_sangre (id_tipo_sangre, nom_tip_sang) VALUES
(1, 'O+'),
(2, 'O-'),
(3, 'A+'),
(4, 'A-'),
(5, 'B+'),
(6, 'B-'),
(7, 'AB+'),
(8, 'AB-');

-- 10. tab_bancos (20 bancos colombianos - MOVIDO POR FK)
INSERT INTO tab_bancos (id_banco, id_ciudad, nom_banco, dir_banco) VALUES
(1, 68001, 'Bancolombia', 'Cl. 50 #42-20, Bucaramanga'),
(2, 11001, 'Banco de Bogotá', 'Cra 7 #14-78, Bogotá'),
(3, 5001, 'Banco Popular', 'Cl. 52 #45-10, Medellín'),
(4, 8001, 'BBVA Colombia', 'Cra 54 #68-120, Barranquilla'),
(5, 13001, 'Davivienda', 'Centro, Cra 8 #12-65, Cartagena'),
(6, 76001, 'Banco de Occidente', 'Av. 4N #6N-45, Cali'),
(7, 66001, 'Banco Caja Social', 'Cra 8 #18-55, Pereira'),
(8, 63001, 'Banco AV Villas', 'Centro, Cra 14 #15-42, Armenia'),
(9, 54001, 'Bancoomeva', 'Av. 5 #15-27, Cúcuta'),
(10, 52001, 'Scotiabank Colpatria', 'Cra 25 #15-40, Pasto'),
(11, 50001, 'Banco Falabella', 'Centro Comercial Unicentro, Villavicencio'),
(12, 47001, 'Banco Pichincha', 'Cl. 17 #4-84, Santa Marta'),
(13, 41001, 'Banco Finandina', 'Cra 5 #10-40, Neiva'),
(14, 23001, 'Bancamia', 'Cra 4 #16-35, Montería'),
(15, 20001, 'Banco Serfinanza', 'Cl. 16 #7-35, Valledupar'),
(16, 17001, 'Banco Mundo Mujer', 'Cra 22 #19-25, Manizales'),
(17, 15001, 'Banco Cooperativo Coopcentral', 'Cl. 18 #9-50, Tunja'),
(18, 19001, 'Banco W', 'Cra 6 #4-38, Popayán'),
(19, 44001, 'Banco Agrario', 'Cl. 15 #5-40, Riohacha'),
(20, 18001, 'Banco ProCredit', 'Cra 11 #12-45, Florencia');


-- 11. tab_empleados (20 empleados)
INSERT INTO tab_empleados (id_empleado, id_documento, id_ciudad, id_cargo, id_tipo_sangre, ind_genero, num_documento, prim_nom, segun_nom, prim_apell, segun_apell, mail_empleado, tel_empleado, dir_emple, ind_fecha_contratacion, ind_peso, ind_altura, ult_fec_exam, observ, id_banco, num_cuenta) VALUES
(1, 1, 68001, 1, 1, 1, '123456789', 'Carlos', 'Andrés', 'Gómez', 'Pérez', 'c.gomez@dental.com', 3001112233, 'Dirección pendiente', '2023-01-15', 70.5, 1.75, '2023-06-20', 'N/A', 1, '1000000001'),
(2, 1, 68077, 3, 3, 2, '987654321', 'Ana', 'María', 'López', 'García', 'a.lopez@dental.com', 3002223344, 'Dirección pendiente', '2022-03-10', 65.2, 1.68, '2023-05-15', 'N/A', 2, '1000000002'),
(3, 1, 68132, 4, 2, 1, '456789123', 'Pedro', 'Rodríguez', 'Martínez', NULL, 'p.rodriguez@dental.com', 3003334455, 'Dirección pendiente', '2021-11-20', 80.1, 1.82, '2023-07-10', 'N/A', 3, '1000000003'),
(4, 1, 68573, 1, 4, 2, '789123456', 'Laura', 'Isabel', 'Hernández', NULL, 'l.hernandez@dental.com', 3004445566, 'Dirección pendiente', '2023-02-28', 58.7, 1.65, '2023-08-05', 'N/A', 4, '1000000004'),
(5, 1, 68001, 5, 1, 1, '321654987', 'Miguel', 'Ángel', 'Díaz', 'Silva', 'm.diaz@dental.com', 3005556677, 'Dirección pendiente', '2020-09-15', 75.3, 1.78, '2023-04-12', 'N/A', 5, '1000000005'),
(6, 1, 68077, 6, 3, 2, '654987321', 'Sofia', 'Morales', 'Rojas', NULL, 's.morales@dental.com', 3006667788, 'Dirección pendiente', '2022-07-22', 62.8, 1.70, '2023-09-18', 'N/A', 1, '1000000006'),
(7, 1, 68132, 7, 5, 1, '987321654', 'David', 'Esteban', 'Castillo', 'Vargas', 'd.castillo@dental.com', 3007778899, 'Dirección pendiente', '2021-05-30', 68.9, 1.73, '2023-10-22', 'N/A', 2, '1000000007'),
(8, 1, 68573, 8, 2, 2, '147258369', 'Carmen', 'Elena', 'Ramírez', 'Ortega', 'c.ramirez@dental.com', 3008889900, 'Dirección pendiente', '2023-04-05', 55.4, 1.62, '2023-11-15', 'N/A', 3, '1000000008'),
(9, 1, 68001, 9, 4, 1, '258369147', 'Jorge', 'Luis', 'Torres', 'Mendoza', 'j.torres@dental.com', 3009990011, 'Dirección pendiente', '2020-12-10', 72.6, 1.76, '2023-03-08', 'N/A', 4, '1000000009'),
(10, 1, 68077, 10, 1, 2, '369147258', 'Patricia', 'Navarro', 'Castro', NULL, 'p.navarro@dental.com', 3000001122, 'Dirección pendiente', '2022-08-14', 61.2, 1.67, '2023-12-01', 'N/A', 5, '1000000010'),
(11, 1, 68132, 1, 6, 1, '741852963', 'Fernando', 'José', 'Guerrero', 'Peña', 'f.guerrero@dental.com', 3001112233, 'Dirección pendiente', '2021-06-25', 77.8, 1.80, '2023-02-14', 'N/A', 1, '1000000011'),
(12, 1, 68573, 11, 3, 2, '852963741', 'Gabriela', 'Marcela', 'Reyes', 'Santos', 'g.reyes@dental.com', 3002223344, 'Dirección pendiente', '2023-03-18', 59.1, 1.64, '2023-07-30', 'N/A', 2, '1000000012'),
(13, 1, 68001, 12, 5, 1, '963741852', 'Ricardo', 'Vega', 'Fuentes', NULL, 'r.vega@dental.com', 3003334455, 'Dirección pendiente', '2020-10-08', 74.5, 1.79, '2023-05-25', 'N/A', 3, '1000000013'),
(14, 1, 68077, 13, 2, 2, '159263748', 'Monica', 'Patricia', 'Medina', 'Arias', 'm.medina@dental.com', 3004445566, 'Dirección pendiente', '2022-01-12', 56.3, 1.61, '2023-09-10', 'N/A', 4, '1000000014'),
(15, 1, 68132, 14, 4, 1, '263748159', 'Oscar', 'Alberto', 'Parra', 'Miranda', 'o.parra@dental.com', 3005556677, 'Dirección pendiente', '2021-07-07', 69.7, 1.74, '2023-11-28', 'N/A', 5, '1000000015'),
(16, 1, 68573, 15, 1, 2, '374815926', 'Tatiana', 'Cardenas', 'Pacheco', NULL, 't.cardenas@dental.com', 3006667788, 'Dirección pendiente', '2023-05-20', 63.4, 1.69, '2023-04-17', 'N/A', 1, '1000000016'),
(17, 1, 68001, 16, 7, 1, '481592637', 'Santiago', 'Manuel', 'Jiménez', 'Rios', 's.jimenez@dental.com', 3007778899, 'Dirección pendiente', '2020-04-03', 81.2, 1.83, '2023-08-12', 'N/A', 2, '1000000017'),
(18, 1, 68077, 17, 3, 2, '592637481', 'Natalia', 'Carolina', 'Moreno', 'Cordoba', 'n.moreno@dental.com', 3008889900, 'Dirección pendiente', '2022-11-30', 60.8, 1.66, '2023-10-05', 'N/A', 3, '1000000018'),
(19, 1, 68132, 18, 5, 1, '637481592', 'Humberto', 'Suarez', 'Londoño', NULL, 'h.suarez@dental.com', 3009990011, 'Dirección pendiente', '2021-02-14', 76.9, 1.81, '2023-06-15', 'N/A', 4, '1000000019'),
(20, 1, 68573, 19, 2, 2, '748159263', 'Verónica', 'Alejandra', 'Gutierrez', 'Marin', 'v.gutierrez@dental.com', 3000001122, 'Dirección pendiente', '2023-06-08', 57.6, 1.63, '2023-12-20', 'N/A', 5, '1000000020');


-- 12. tab_proveedores (3 proveedores)
INSERT INTO tab_proveedores (id_prov, id_documento, id_ciudad, num_documento, nom_prov, tel_prov, mail_prov, dir_prov, ind_calidad) VALUES
(6, 4, 76001, '8445556667', 'Suministros Dentales del Valle', 3002890123, 'suministros@dentalvalle.com', 'Av. 6N #25-10, Cali', 'Precios competitivos'),
(7, 4, 66001, '8556667778', 'Esterilab S.A.S.', 3006901234, 'compras@esterilab.com', 'Cra 7 #18-33, Pereira', 'Especialistas en esterilización'),
(8, 4, 63001, '8667778889', 'Dental Quindío Ltda', 3007012345, 'info@dentalquindio.com', 'Cl. 19 #12-45, Armenia', 'Materiales nacionales');

-- 12. tab_unidades_medida
INSERT INTO tab_unidades_medida (id_unidad_medida, nom_unidad) VALUES
(1, 'g'),
(2, 'kg'),
(3, 'mm'),
(4, 'cm'),
(5, 'm'),
(6, 'unidades');

-- 13. tab_cat_mat_prim (20 categorías)
INSERT INTO tab_cat_mat_prim (id_cat_mat, nom_categoria) VALUES
(1, 'Varillas'),
(2, 'Tornillos'),
(3, 'Alambres');

-- 14. tab_materias_primas (20 materias primas)
INSERT INTO tab_materias_primas (id_mat_prima, id_cat_mat, nom_materia_prima, img_url) VALUES
(1, 1, 'Varilla Acero Inox 2.0mm', '../../images/sim_imagen.png'),
(2, 1, 'Varilla Titanio 1.5mm', '../../images/sim_imagen.png'),
(3, 2, 'Tornillo Miniimplante 1.5x8mm', '../../images/sim_imagen.png'),
(4, 2, 'Tornillo Miniimplante 2.0x10mm', '../../images/sim_imagen.png'),
(5, 3, 'Alambre Níquel-Titanio 0.014', '../../images/sim_imagen.png'),
(6, 3, 'Alambre Acero Inoxidable 0.016', '../../images/sim_imagen.png');

-- 15. tab_mat_primas_prov (20 relaciones)
INSERT INTO tab_mat_primas_prov (id_prov, id_mat_prima, lote, tipo_mat_prima, valor_medida, id_unidad_medida, cant_mat_prima) VALUES
(8, 1, 115, 'Varilla Acero', 100.0, 4, 30),
(8, 2, 116, 'Varilla Titanio', 100.0, 4, 25),
(7, 3, 113, 'Tornillo Implante', 8.0, 3, 120),
(7, 4, 114, 'Tornillo Implante', 10.0, 3, 110),
(6, 5, 111, 'Alambre Orto', 20.0, 5, 90),
(6, 6, 112, 'Alambre Orto', 20.0, 5, 85);

-- 16. tab_tipo_especializacion (4 especializaciones principales)
INSERT INTO tab_tipo_especializacion (id_especializacion, nom_espec) VALUES
(1, 'Estética Dental'),
(2, 'Esterilización'),
(3, 'Endodoncia'),
(4, 'Periodoncia');

-- 17. tab_instrumentos (20 instrumentos reasignados a las 4 categorias)
INSERT INTO tab_instrumentos (id_instrumento, id_especializacion, nom_instrumento, lote, cant_disp, numeral_en_kit, tipo_mat, img_url) VALUES
(1, 1, 'Explorador Dental N°5', 201, 50, 1, 1, '../../images/sim_imagen.png'),
(2, 1, 'Explorador Dental N°23', 202, 45, 2, 1, '../../images/sim_imagen.png'),
(3, 3, 'Lima K #15', 203, 100, 3, 1, '../../images/sim_imagen.png'),
(4, 3, 'Lima K #25', 204, 95, 4, 1, '../../images/sim_imagen.png'),
(5, 4, 'Cureta Gracey 1-2', 205, 60, 5, 1, '../../images/sim_imagen.png'),
(6, 4, 'Cureta Universal 13-14', 206, 55, 6, 1, '../../images/sim_imagen.png'),
(7, 4, 'Pinza Adams', 207, 40, 7, 1, '../../images/sim_imagen.png'),
(8, 4, 'Pinza Weingart', 208, 35, 8, 1, '../../images/sim_imagen.png'),
(9, 4, 'Elevador Straight', 209, 30, 9, 1, '../../images/sim_imagen.png'),
(10, 4, 'Elevador Crane', 210, 25, 10, 1, '../../images/sim_imagen.png'),
(11, 4, 'Porta Aguja Mayo-Hegar', 211, 70, 11, 1, '../../images/sim_imagen.png'),
(12, 4, 'Tijera Metzenbaum', 212, 65, 12, 1, '../../images/sim_imagen.png'),
(13, 1, 'Speculum Pediátrico', 213, 20, 13, 1, '../../images/sim_imagen.png'),
(14, 1, 'Cepillo Prophylaxis', 214, 150, 14, 1, '../../images/sim_imagen.png'),
(15, 1, 'Micropincel Estética', 215, 80, 15, 2, '../../images/sim_imagen.png'),
(16, 1, 'Espátula de Composite', 216, 90, 16, 1, '../../images/sim_imagen.png'),
(17, 4, 'Motor de Implantes', 217, 15, 17, 2, '../../images/sim_imagen.png'),
(18, 4, 'Fresa de Osteotomía', 218, 200, 18, 1, '../../images/sim_imagen.png'),
(19, 1, 'Posicionador Radiográfico', 219, 25, 19, 2, '../../images/sim_imagen.png'),
(20, 2, 'Pinza de Esterilización', 220, 40, 20, 1, '../../images/sim_imagen.png'),
(21, 2, 'Caja de Esterilización', 221, 15, 21, 1, '../../images/sim_imagen.png'),
(22, 2, 'Rollo de Esterilización', 222, 100, 22, 2, '../../images/sim_imagen.png'),
(23, 3, 'Lima H #30', 223, 85, 23, 1, '../../images/sim_imagen.png');

-- 18. tab_kits (20 kits reasignados a las 4 categorias)
INSERT INTO tab_kits (id_kit, id_especializacion, nom_kit, cant_disp, tipo_mat, img_url) VALUES
(1, 1, 'Kit Operatoria Dental Básico', 25, 1, '../../images/sim_imagen.png'),
(2, 1, 'Kit Operatoria Dental Avanzado', 15, 1, '../../images/sim_imagen.png'),
(3, 3, 'Kit Endodoncia Inicial', 20, 1, '../../images/sim_imagen.png'),
(4, 3, 'Kit Endodoncia Profesional', 12, 1, '../../images/sim_imagen.png'),
(5, 4, 'Kit Periodoncia Básico', 18, 1, '../../images/sim_imagen.png'),
(6, 4, 'Kit Periodoncia Quirúrgico', 10, 1, '../../images/sim_imagen.png'),
(7, 4, 'Kit Ortodoncia Inicial', 22, 1, '../../images/sim_imagen.png'),
(8, 4, 'Kit Ortodoncia Avanzado', 14, 1, '../../images/sim_imagen.png'),
(9, 4, 'Kit Cirugía Oral Básica', 16, 1, '../../images/sim_imagen.png'),
(10, 4, 'Kit Cirugía Oral Avanzada', 8, 1, '../../images/sim_imagen.png'),
(11, 4, 'Kit Prótesis Dental', 20, 1, '../../images/sim_imagen.png'),
(12, 1, 'Kit Odontopediatría', 18, 1, '../../images/sim_imagen.png'),
(13, 1, 'Kit Estética Dental Premium', 12, 2, '../../images/sim_imagen.png'),
(14, 4, 'Kit Implantología Básico', 10, 1, '../../images/sim_imagen.png'),
(15, 1, 'Kit Radiología Dental', 15, 1, '../../images/sim_imagen.png'),
(16, 2, 'Kit Emergencias Dentales', 25, 1, '../../images/sim_imagen.png'),
(17, 2, 'Kit Esterilización Completo', 30, 1, '../../images/sim_imagen.png'),
(18, 1, 'Kit Diagnóstico Dental', 28, 1, '../../images/sim_imagen.png'),
(19, 4, 'Kit Laboratorio Dental', 12, 2, '../../images/sim_imagen.png'),
(20, 1, 'Kit Blanqueamiento Dental', 20, 2, '../../images/sim_imagen.png');

-- 19. tab_instrumentos_kit (20 relaciones conservadas)
INSERT INTO tab_instrumentos_kit (id_instrumento_kit, id_kit, id_instrumento, cant_instrumento) VALUES
(1, 1, 1, 2),
(2, 1, 2, 2),
(3, 2, 1, 3),
(4, 2, 2, 3),
(5, 3, 3, 5),
(6, 3, 4, 5),
(7, 4, 3, 8),
(8, 4, 4, 8),
(9, 5, 5, 3),
(10, 5, 6, 3),
(11, 6, 5, 5),
(12, 6, 6, 5),
(13, 7, 7, 2),
(14, 7, 8, 2),
(15, 8, 7, 4),
(16, 8, 8, 4),
(17, 9, 9, 2),
(18, 9, 10, 2),
(19, 10, 9, 4),
(20, 10, 10, 4);

-- 20. tab_productos (20 productos - CORREGIDO: usa id_kit no id_instrumento_kit)
INSERT INTO tab_productos (id_producto, id_instrumento, id_kit, nombre_producto, precio_producto, img_url) VALUES
-- Instrumentos individuales (id_instrumento NOT NULL, id_kit NULL)
(1, 1, NULL, 'Explorador Dental N°5', 45000, '../../images/sim_imagen.png'),
(2, 2, NULL, 'Explorador Dental N°23', 48000, '../../images/sim_imagen.png'),
(3, 3, NULL, 'Lima K #15', 25000, '../../images/sim_imagen.png'),
(4, 4, NULL, 'Lima K #25', 28000, '../../images/sim_imagen.png'),
(5, 5, NULL, 'Cureta Gracey 1-2', 65000, '../../images/sim_imagen.png'),
(6, 6, NULL, 'Cureta Universal', 62000, '../../images/sim_imagen.png'),
(7, 7, NULL, 'Pinza Adams', 55000, '../../images/sim_imagen.png'),
(8, 8, NULL, 'Pinza Weingart', 58000, '../../images/sim_imagen.png'),
(9, 9, NULL, 'Elevador Straight', 75000, '../../images/sim_imagen.png'),
(10, 10, NULL, 'Elevador Crane', 78000, '../../images/sim_imagen.png'),

-- Kits (id_instrumento NULL, id_kit NOT NULL)
(11, NULL, 1, 'Kit Operatoria Básico', 250000, '../../images/sim_imagen.png'),
(12, NULL, 2, 'Kit Operatoria Avanzado', 450000, '../../images/sim_imagen.png'),
(13, NULL, 3, 'Kit Endodoncia Inicial', 380000, '../../images/sim_imagen.png'),
(14, NULL, 4, 'Kit Endodoncia Profesional', 680000, '../../images/sim_imagen.png'),
(15, NULL, 5, 'Kit Periodoncia Básico', 420000, '../../images/sim_imagen.png'),
(16, NULL, 6, 'Kit Periodoncia Quirúrgico', 720000, '../../images/sim_imagen.png'),
(17, NULL, 7, 'Kit Ortodoncia Inicial', 350000, '../../images/sim_imagen.png'),
(18, NULL, 8, 'Kit Ortodoncia Avanzado', 550000, '../../images/sim_imagen.png'),
(19, NULL, 9, 'Kit Cirugía Básica', 480000, '../../images/sim_imagen.png'),
(20, NULL, 10, 'Kit Cirugía Avanzada', 850000, '../../images/sim_imagen.png');

-- 21. tab_clientes (20 clientes)
INSERT INTO tab_clientes (id_cliente, id_documento, id_ciudad, ind_genero, prim_nom, segun_nom, prim_apell, segun_apell, num_documento, tel_cliente, dir_cliente, ind_profesion, val_puntos) VALUES
(1, 1, 68001, 2, 'Ana', 'María', 'López', 'García', '987654321', 3004445566, 'Cra 45 #70-12, Bucaramanga', 'Odontóloga General', 0),
(2, 1, 68077, 1, 'Carlos', 'Eduardo', 'Martínez', 'Rodríguez', '456789123', 3005556677, 'Cl. 100 #45-23, Floridablanca', 'Ortodoncista', 0),
(3, 1, 68132, 2, 'Laura', 'Isabel', 'González', 'Pérez', '789123456', 3006667788, 'Cra 33 #28-45, Girón', 'Endodoncista', 0),
(4, 1, 68573, 1, 'Miguel', 'Ángel', 'Hernández', 'Díaz', '321654987', 3007778899, 'Av. Central #15-67, Piedecuesta', 'Cirujano Oral', 0),
(5, 1, 68001, 2, 'Sofia', NULL, 'Ramírez', 'Morales', '654987321', 3008889900, 'Cl. 55 #12-34, Bucaramanga', 'Periodoncista', 0),
(6, 1, 68077, 1, 'David', 'Esteban', 'Torres', 'Castillo', '987321654', 3009990011, 'Cra 27 #45-78, Floridablanca', 'Odontopediatra', 0),
(7, 1, 68132, 2, 'Carmen', 'Elena', 'Navarro', 'Reyes', '147258369', 3000001122, 'Cl. 68 #23-12, Girón', 'Prostodoncista', 0),
(8, 1, 68573, 1, 'Jorge', 'Luis', 'Guerrero', 'Vega', '258369147', 3001112233, 'Cra 40 #56-34, Piedecuesta', 'Implantólogo', 0),
(9, 1, 68001, 2, 'Patricia', NULL, 'Medina', 'Parra', '369147258', 3002223344, 'Cl. 72 #18-45, Bucaramanga', 'Estomatólogo', 0),
(10, 1, 68077, 1, 'Fernando', 'José', 'Cardenas', 'Jiménez', '741852963', 3003334455, 'Cra 15 #67-23, Floridablanca', 'Odontólogo General', 0),
(11, 1, 68132, 2, 'Gabriela', 'Marcela', 'Moreno', 'Suarez', '852963741', 3004445566, 'Av. Santander #45-12, Girón', 'Endodoncista', 0),
(12, 1, 68573, 1, 'Ricardo', NULL, 'Gutierrez', 'Londoño', '963741852', 3005556677, 'Cl. 30 #25-67, Piedecuesta', 'Cirujano Maxilofacial', 0),
(13, 1, 68001, 2, 'Monica', 'Patricia', 'Arias', 'Marin', '159263748', 3006667788, 'Cra 22 #34-56, Bucaramanga', 'Odontóloga Estética', 0),
(14, 1, 68077, 1, 'Oscar', 'Alberto', 'Miranda', 'Pacheco', '263748159', 3007778899, 'Cl. 85 #45-23, Floridablanca', 'Ortodoncista', 0),
(15, 1, 68132, 2, 'Tatiana', NULL, 'Rios', 'Cordoba', '374815926', 3008889900, 'Cra 18 #12-78, Girón', 'Periodoncista', 0),
(16, 1, 68573, 1, 'Santiago', 'Manuel', 'Fuentes', 'Santos', '481592637', 3009990011, 'Av. Las Américas #23-45, Piedecuesta', 'Implantólogo', 0),
(17, 1, 68001, 2, 'Natalia', 'Carolina', 'Ortega', 'Peña', '592637481', 3000001122, 'Cl. 42 #67-34, Bucaramanga', 'Odontopediatra', 0),
(18, 1, 68077, 1, 'Humberto', NULL, 'Silva', 'Castro', '637481592', 3001112233, 'Cra 35 #28-56, Floridablanca', 'Prostodoncista', 0),
(19, 1, 68132, 2, 'Verónica', 'Alejandra', 'Rojas', 'Vargas', '748159263', 3002223344, 'Cl. 25 #45-67, Girón', 'Odontóloga General', 0),
(20, 1, 68573, 1, 'Alejandro', 'Javier', 'Mendoza', 'Mendoza', '815926374', 3003334455, 'Cra 50 #34-12, Piedecuesta', 'Cirujano Oral', 0),
(99999, 1, 68573, 3, 'Cliente', NULL, 'Genérico', NULL, '999999999', 3009999999, 'Cra #1 Calle Genérica 2', 'Profesión nula', 0);

-- 22. tab_estado_fact (4 estados)
INSERT INTO tab_estado_fact (id_estado_fact, nom_estado_fact) VALUES
(1, 'Pagada'),
(2, 'Pendiente'),
(3, 'Anulada'),
(4, 'Devuelta');

-- 23. tab_facturas (20 facturas)
INSERT INTO tab_facturas (id_factura, id_cliente, id_estado_fact, ind_forma_pago, fecha_venta, val_tot_fact) VALUES
(1, 1, 1, 1, '2023-11-15 09:30:00', 295000),
(2, 2, 1, 2, '2023-11-16 10:15:00', 680000),
(3, 3, 1, 3, '2023-11-17 11:20:00', 450000),
(4, 4, 1, 3, '2023-11-18 14:45:00', 850000),
(5, 5, 2, 1, '2023-11-19 16:30:00', 420000),
(6, 6, 1, 2, '2023-11-20 08:15:00', 250000),
(7, 7, 1, 3, '2023-11-21 10:45:00', 380000),
(8, 8, 1, 2, '2023-11-22 13:20:00', 720000),
(9, 9, 2, 1, '2023-11-23 15:10:00', 480000),
(10, 10, 1, 2, '2023-11-24 09:55:00', 550000),
(11, 11, 1, 3, '2023-11-25 11:40:00', 350000),
(12, 12, 1, 2, '2023-11-26 14:25:00', 45000),
(13, 13, 2, 1, '2023-11-27 16:50:00', 65000),
(14, 14, 1, 2, '2023-11-28 08:35:00', 28000),
(15, 15, 1, 3, '2023-11-29 10:20:00', 75000),
(16, 16, 1, 1, '2023-11-30 12:15:00', 58000),
(17, 17, 2, 1, '2023-12-01 14:40:00', 62000),
(18, 18, 1, 2, '2023-12-02 09:25:00', 78000),
(19, 19, 1, 3, '2023-12-03 11:10:00', 48000),
(20, 20, 1, 2, '2023-12-04 13:55:00', 25000);

-- 24. tab_detalle_facturas (20 detalles - CORREGIDO: campos completos)
INSERT INTO tab_detalle_facturas (id_detalle_factura, id_factura, id_producto, cantidad, precio_unitario, val_descuento, val_bruto, val_neto) VALUES
(1, 1, 11, 1, 250000.00, 0, 250000.00, 250000.00),
(2, 1, 1, 1, 45000.00, 0, 45000.00, 45000.00),
(3, 2, 14, 1, 680000.00, 0, 680000.00, 680000.00),
(4, 3, 12, 1, 450000.00, 0, 450000.00, 450000.00),
(5, 4, 20, 1, 850000.00, 0, 850000.00, 850000.00),
(6, 5, 15, 1, 420000.00, 0, 420000.00, 420000.00),
(7, 6, 11, 1, 250000.00, 0, 250000.00, 250000.00),
(8, 7, 13, 1, 380000.00, 0, 380000.00, 380000.00),
(9, 8, 16, 1, 720000.00, 0, 720000.00, 720000.00),
(10, 9, 19, 1, 480000.00, 0, 480000.00, 480000.00),
(11, 10, 18, 1, 550000.00, 0, 550000.00, 550000.00),
(12, 11, 17, 1, 350000.00, 0, 350000.00, 350000.00),
(13, 12, 1, 1, 45000.00, 0, 45000.00, 45000.00),
(14, 13, 5, 1, 65000.00, 0, 65000.00, 65000.00),
(15, 14, 4, 1, 28000.00, 0, 28000.00, 28000.00),
(16, 15, 9, 1, 75000.00, 0, 75000.00, 75000.00),
(17, 16, 8, 1, 58000.00, 0, 58000.00, 58000.00),
(18, 17, 6, 1, 62000.00, 0, 62000.00, 62000.00),
(19, 18, 10, 1, 78000.00, 0, 78000.00, 78000.00),
(20, 19, 2, 1, 48000.00, 0, 48000.00, 48000.00);

-- 25. tab_bodega (20 movimientos)
INSERT INTO tab_bodega (id_movimiento, id_prov, id_mat_prima, fec_ingreso, fec_salida) VALUES
(1, 8, 1, '2023-11-15 15:50:00', NULL),
(2, 8, 2, '2023-11-16 17:05:00', NULL),
(3, 7, 3, '2023-11-13 13:20:00', NULL),
(4, 7, 4, '2023-11-14 14:35:00', NULL),
(5, 6, 5, '2023-11-11 10:50:00', NULL),
(6, 6, 6, '2023-11-12 12:05:00', NULL);

-- 26. tab_producc (20 producciones)
INSERT INTO tab_producc (id_producc, id_movimiento, fec_ingreso) VALUES
(1, 1, '2023-11-24 12:25:00'),
(2, 2, '2023-11-25 13:40:00'),
(3, 3, '2023-11-22 09:55:00'),
(4, 4, '2023-11-23 11:10:00'),
(5, 5, '2023-11-20 17:05:00'),
(6, 6, '2023-11-21 08:40:00');

-- 27. tab_kardex_mat_prima (20 movimientos kardex)
INSERT INTO tab_kardex_mat_prima (id_kardex_mat_prima, id_materia_prima, id_unidad_medida, valor_medida, tipo_movimiento, cantidad, fecha_movimiento, observaciones) VALUES
(1, 1, 4, 100.0, 1, 30.00, '2023-11-15 15:50:00', 'Entrada varilla acero'),
(2, 2, 4, 100.0, 1, 25.00, '2023-11-16 17:05:00', 'Entrada varilla titanio'),
(3, 3, 3, 8.0, 1, 120.00, '2023-11-13 13:20:00', 'Entrada tornillo 1.5'),
(4, 4, 3, 10.0, 1, 110.00, '2023-11-14 14:35:00', 'Entrada tornillo 2.0'),
(5, 5, 5, 20.0, 1, 90.00, '2023-11-11 10:50:00', 'Entrada alambre NiTi'),
(6, 6, 5, 20.0, 1, 85.00, '2023-11-12 12:05:00', 'Entrada alambre Acero');

-- 28. tab_historico_mat_prima (20 históricos)
INSERT INTO tab_historico_mat_prima (id_historico, id_materia_prima, id_proveedor, precio_anterior, precio_nuevo, fecha_cambio, motivo) VALUES
(1, 1, 8, 42000.00, 43000.00, '2023-10-29 15:50:00', 'Ajuste por calidad'),
(2, 2, 8, 45000.00, 46000.00, '2023-10-30 17:05:00', 'Incremento importación'),
(3, 3, 7, 28000.00, 29000.00, '2023-10-27 13:20:00', 'Ajuste por demanda'),
(4, 4, 7, 30000.00, 31000.00, '2023-10-28 14:35:00', 'Aumento costo material'),
(5, 5, 6, 32000.00, 33000.00, '2023-10-25 10:50:00', 'Ajuste menor costo'),
(6, 6, 6, 35000.00, 36000.00, '2023-10-26 12:05:00', 'Incremento producción');

-- 29. tab_bancos_proveedor (20 relaciones)
INSERT INTO tab_bancos_proveedor (id_prov, id_banco, num_cuenta) VALUES
(6, 11, '74185296374'),
(6, 12, '85296374185'),
(7, 13, '96374185296'),
(7, 14, '15926374815'),
(8, 15, '26374815926'),
(8, 16, '37481592637');

-- 30. tab_dev (5 devoluciones)
INSERT INTO tab_dev (id_factura, ind_observaciones) VALUES
(3, 'Producto con defecto de fabricación'),
(5, 'Cliente no satisfecho con el producto'),
(12, 'Error en el pedido del cliente'),
(15, 'Producto dañado en transporte'),
(19, 'Cambio por modelo diferente');
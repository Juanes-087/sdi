<?php
/**
 * ============================================================
 * CAPA DE ACCESO A DATOS (QUERYS)
 * ============================================================
 * 
 * PROPÓSITO:
 * Centraliza TODAS las consultas a la base de datos.
 * En lugar de escribir SQL directamente en cada archivo,
 * se llaman métodos de esta clase.
 * 
 * ESTRUCTURA:
 * - Consultas GET: Métodos que traen listados (getClientes, etc.)
 * - Inserciones: Métodos que crean registros (insertCliente, etc.)
 *   → Usan funciones SQL almacenadas en la BD (fun_insert_...)
 * - Actualizaciones: Métodos que modifican registros
 *   → Genérico (updateGeneric) o específico por tipo
 * - Eliminaciones: Borrado lógico (deleteGeneric)
 *   → Marca ind_vivo = false, no borra físicamente
 * - Kardex: Registro de movimientos de inventario
 * 
 * SEGURIDAD:
 * - Todas las consultas usan sentencias preparadas (PDO)
 *   para prevenir inyección SQL.
 * - Las funciones SQL de la base de datos realizan
 *   validaciones adicionales.
 * ============================================================
 */
require_once __DIR__ . '/conexion.php';

class CQuerys
{
    private $conn;

    // Constructor: se conecta a la base de datos automáticamente
    public function __construct()
    {
        $conexion = new CConexion();
        $this->conn = $conexion->conexionBD();

        if ($this->conn) {
            // Asegurar que el punto decimal siempre sea '.' para evitar errores de locale (ej: 1.7 -> 17)
            $this->conn->exec("SET lc_numeric = 'C'");

            // Configurar el usuario de la aplicación para el Audit Trail
            if (session_status() !== PHP_SESSION_NONE && isset($_SESSION['nom_user'])) {
                $user = $_SESSION['nom_user'];
                $this->conn->exec("SET specialized.app_user = " . $this->conn->quote($user));
            }
        }
    }

    // Devuelve la conexión activa (para transacciones manuales)
    public function getConn()
    {
        return $this->conn;
    }

    // ══════════════════════════════════════════════════════════
    // SECCIÓN 1: CONSULTAS DE DATOS AUXILIARES
    // ══════════════════════════════════════════════════════════
    // Trae listas de referencia (ciudades, tipos de documento,
    // cargos, etc.) que se usan en los formularios del panel.

    // Obtiene todas las tablas auxiliares en un solo JSON
    // para llenar los selectores (dropdowns) de los formularios.
    public function getAuxiliaresJSON()
    {
        $sql = "SELECT fun_obtener_auxiliares() as json_data";
        $stmt = $this->conn->query($sql);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        return $row ? $row['json_data'] : '{}';
    }

    // Busca el ID de un registro a partir de su nombre.
    // Por ejemplo: busca el ID de la ciudad "Bogotá" en tab_ciudades.
    // Si el valor ya es numérico, lo retorna directamente.
    public function getIdByName($table, $colId, $colName, $val)
    {
        if (empty($val))
            return null;

        if (is_numeric($val))
            return $val;

        $sql = "SELECT $colId FROM $table WHERE LOWER($colName) = LOWER(:val) LIMIT 1";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':val' => trim($val)]);
        $res = $stmt->fetch(PDO::FETCH_ASSOC);

        return $res ? $res[$colId] : null;
    }

    // ══════════════════════════════════════════════════════════
    // SECCIÓN 2: CONSULTAS DE TABLAS PRINCIPALES
    // ══════════════════════════════════════════════════════════
    // Cada método trae los registros de una tabla específica,
    // incluyendo datos de tablas relacionadas (JOINs) para
    // mostrar nombres en lugar de IDs en las tablas del panel.
    // Solo se muestran registros activos (ind_vivo = true).

    // Lista de clientes con su documento, ciudad y datos personales
    public function getClientes()
    {
        $sql = "SELECT c.id_cliente, c.id_cliente as id, c.prim_nom || ' ' || c.prim_apell as nombre_completo, 
                       c.num_documento, c.tel_cliente, c.dir_cliente, c.ind_profesion,
                       c.prim_nom, c.segun_nom, c.prim_apell, c.segun_apell,
                       td.nom_tipo_docum as nom_documento, ci.nom_ciudad,
                       c.id_documento, c.id_ciudad, c.ind_genero, 
                       CASE c.ind_genero WHEN 1 THEN 'Masculino' WHEN 2 THEN 'Femenino' ELSE 'Otro' END as nom_genero
                FROM tab_clientes c
                LEFT JOIN tab_tipo_documentos td ON c.id_documento = td.id_documento
                LEFT JOIN tab_ciudades ci ON c.id_ciudad = ci.id_ciudad
                WHERE c.ind_vivo = true 
                ORDER BY c.id_cliente ASC LIMIT 100";
        return $this->conn->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    }

    // Lista de empleados con cargo, documento, ciudad, tipo de sangre y banco
    public function getEmpleados()
    {
        $sql = "SELECT e.id_empleado, e.id_empleado as id, e.prim_nom || ' ' || e.prim_apell as nombre_completo, 
                       c.nom_cargo, e.tel_empleado, e.mail_empleado,
                       e.num_documento, e.prim_nom, e.segun_nom, e.prim_apell, e.segun_apell,
                       e.ind_fecha_contratacion, e.dir_emple, e.num_cuenta,
                       e.ind_peso, e.ind_altura, e.ult_fec_exam, e.observ,
                       td.nom_tipo_docum as nom_documento, ci.nom_ciudad,
                       ts.nom_tip_sang as nom_tipo_sangre, b.nom_banco,
                       e.id_documento, e.id_ciudad, e.id_cargo, e.id_tipo_sangre, e.id_banco,
                       e.ind_genero, CASE e.ind_genero WHEN 1 THEN 'Masculino' WHEN 2 THEN 'Femenino' ELSE 'Otro' END as nom_genero
                FROM tab_empleados e 
                LEFT JOIN tab_cargos c ON e.id_cargo = c.id_cargo 
                LEFT JOIN tab_tipo_documentos td ON e.id_documento = td.id_documento
                LEFT JOIN tab_ciudades ci ON e.id_ciudad = ci.id_ciudad
                LEFT JOIN tab_tipo_sangre ts ON e.id_tipo_sangre = ts.id_tipo_sangre
                LEFT JOIN tab_bancos b ON e.id_banco = b.id_banco
                WHERE e.ind_vivo = true 
                ORDER BY e.id_empleado ASC LIMIT 100";
        return $this->conn->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    }

    // Lista de proveedores con documento y ciudad
    public function getProveedores()
    {
        $sql = "SELECT p.id_prov, p.nom_prov, p.num_documento, p.tel_prov, p.mail_prov, 
                       p.dir_prov, p.ind_calidad,
                       td.nom_tipo_docum as nom_documento, ci.nom_ciudad,
                       p.id_documento, p.id_ciudad
                FROM tab_proveedores p
                LEFT JOIN tab_tipo_documentos td ON p.id_documento = td.id_documento
                LEFT JOIN tab_ciudades ci ON p.id_ciudad = ci.id_ciudad
                WHERE p.ind_vivo = true 
                ORDER BY p.id_prov ASC LIMIT 100";
        return $this->conn->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    }

    // Lista de usuarios del sistema (para gestión de cuentas)
    public function getUsuarios()
    {
        $sql = "SELECT u.id_user, u.nom_user, u.mail_user, u.tel_user 
                FROM tab_users u WHERE u.ind_vivo = true ORDER BY u.id_user ASC LIMIT 100";
        return $this->conn->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    }

    // Lista de instrumentos médicos con su especialización
    public function getInstrumentos($soloHabilitados = true)
    {
        $sql = "SELECT i.id_instrumento, i.nom_instrumento, e.nom_espec as especializacion, i.id_especializacion, i.cant_disp, i.lote,  
                       i.stock_min, i.stock_max, i.img_url, i.tipo_mat, i.ind_vivo,
                       CASE i.tipo_mat WHEN 1 THEN 'Specialized (Acero)' WHEN 2 THEN 'Special (Aluminio)' END as nom_tipo_mat
                FROM tab_instrumentos i 
                LEFT JOIN tab_tipo_especializacion e ON i.id_especializacion = e.id_especializacion 
                WHERE i.ind_vivo = :estado
                ORDER BY i.id_instrumento ASC LIMIT 100";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':estado' => $soloHabilitados ? 'true' : 'false']);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // Lista de kits (conjuntos de instrumentos) con su especialización
    public function getKits($soloHabilitados = true)
    {
        $sql = "SELECT k.id_kit, k.nom_kit, e.nom_espec as nom_especializacion, 
                       k.id_especializacion, k.cant_disp, k.tipo_mat, k.ind_vivo,
                       CASE k.tipo_mat WHEN 1 THEN 'Specialized (Acero)' WHEN 2 THEN 'Special (Aluminio)' END as nom_tipo_mat,
                       k.stock_min, k.stock_max, k.img_url 
                FROM tab_kits k 
                LEFT JOIN tab_tipo_especializacion e ON k.id_especializacion = e.id_especializacion 
                WHERE k.ind_vivo = :estado
                ORDER BY k.id_kit ASC LIMIT 100";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':estado' => $soloHabilitados ? 'true' : 'false']);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // Lista de categorías de materia prima
    public function getCategoriesMateriaPrima($soloHabilitados = true)
    {
        $sql = "SELECT id_cat_mat, nom_categoria, ind_vivo FROM tab_cat_mat_prim WHERE ind_vivo = :estado ORDER BY nom_categoria ASC";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':estado' => $soloHabilitados ? 'true' : 'false']);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // Lista de instrumentos que pertenecen a un kit específico
    public function getInstrumentsByKit($id_kit)
    {
        $sql = "SELECT i.id_instrumento, i.nom_instrumento, ki.cant_instrumento as cantidad 
                FROM tab_instrumentos_kit ki
                JOIN tab_instrumentos i ON ki.id_instrumento = i.id_instrumento
                WHERE ki.id_kit = :id";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':id' => $id_kit]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }


    // ══════════════════════════════════════════════════════════
    // SECCIÓN 3: ESTADÍSTICAS Y BÚSQUEDAS
    // ══════════════════════════════════════════════════════════
    // Métodos que usan funciones SQL para cálculos complejos.

    /**
     * MÉTODO: getStats
     * PROPÓSITO: Obtiene las métricas globales para el Dashboard.
     * FLUJO: Se llama automáticamente al cargar el panel de control.
     * TÉCNICO:
     *   - $this->conn: Conexión PDO activa a la base de datos PostgreSQL.
     *   - query(): Ejecuta la función SQL fun_obtener_stats() de forma directa.
     */
    public function getStats()
    {
        try {
            $sql = "SELECT total_usuarios, usuarios_mes, total_admins, total_clientes, total_productos, 
                           total_instrumentos, total_kits, mayor_venta_nombre, mayor_venta_total, 
                           menor_stock_nombre, menor_stock_cant, total_ventas, ventas_diarias, total_proveedores,
                           alerta_stock_critico, val_pordesc, ind_tema, ind_idioma
                    FROM fun_obtener_stats()";
            $stmt = $this->conn->query($sql);
            if ($stmt) {
                return $stmt->fetch(PDO::FETCH_ASSOC) ?: [];
            }
        } catch (Exception $e) {
            error_log("Error en getStats: " . $e->getMessage());
        }
        return [];
    }

    /**
     * MÉTODO: getTopVendidos
     * PROPÓSITO: Obtiene los 5 productos más vendidos para el carrusel de la landing.
     * TÉCNICO: Combina ventas de facturas y movimientos de kardex.
     */
    public function getTopVendidos($limit = 5)
    {
        try {
            $sql = "WITH sales AS (
                        -- Ventas desde detalle de facturas
                        SELECT id_producto, SUM(cantidad) as total
                        FROM tab_detalle_facturas
                        WHERE COALESCE(ind_vivo, true) = true
                        GROUP BY id_producto
                        UNION ALL
                        -- Ventas manuales desde kardex (tipo_movimiento = 2: Venta)
                        SELECT p.id_producto, SUM(k.cantidad) as total
                        FROM tab_kardex_productos k
                        JOIN tab_productos p ON (k.id_instrumento = p.id_instrumento OR k.id_kit = p.id_kit)
                        WHERE k.tipo_movimiento = 2 
                        AND COALESCE(k.ind_vivo, true) = true 
                        AND COALESCE(p.ind_vivo, true) = true
                        GROUP BY p.id_producto
                    )
                    SELECT p.id_producto, p.nombre_producto as titulo, p.precio_producto as precio, p.img_url, 
                           SUM(s.total) as total_vendido
                    FROM sales s
                    JOIN tab_productos p ON s.id_producto = p.id_producto
                    GROUP BY p.id_producto, p.nombre_producto, p.precio_producto, p.img_url
                    ORDER BY total_vendido DESC
                    LIMIT :limit";
            
            $stmt = $this->conn->prepare($sql);
            $stmt->bindValue(':limit', (int)$limit, PDO::PARAM_INT);
            $stmt->execute();
            return $stmt->fetchAll(PDO::FETCH_ASSOC);
        } catch (Exception $e) {
            error_log("Error en getTopVendidos: " . $e->getMessage());
            return [];
        }
    }

    /**
     * MÉTODO: updateParams
     * PROPÓSITO: Actualiza la configuración global del sistema (tema, idioma, etc).
     */
    public function updateParams($tema, $idioma)
    {
        $sql = "UPDATE tab_parametros SET ind_tema = :tema, ind_idioma = :idioma WHERE id_empresa = 1";
        $stmt = $this->conn->prepare($sql);
        return $stmt->execute([
            ':tema' => $tema ? 1 : 0,
            ':idioma' => $idioma
        ]);
    }

    /**
     * MÉTODO: getAlertasDetalle
     * PROPÓSITO: Trae la lista de items con stock bajo para el modal de notificaciones.
     * FLUJO: Se llama cuando el usuario hace clic en el badge rojo (círculo) del sidebar.
     */
    public function getAlertasDetalle()
    {
        $sql = "SELECT tipo, nombre, actual, minimo FROM fun_obtener_alertas_detalle()";
        $stmt = $this->conn->query($sql);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // Lista de usuarios registrados en el mes actual
    public function getNuevosUsuariosMesDetalle()
    {
        $sql = "SELECT id_user, nom_user, mail_user, tel_user, ind_vivo, fec_insert 
                FROM tab_users 
                WHERE ind_vivo = true 
                AND EXTRACT(MONTH FROM fec_insert) = EXTRACT(MONTH FROM CURRENT_DATE)
                AND EXTRACT(YEAR FROM fec_insert) = EXTRACT(YEAR FROM CURRENT_DATE)
                ORDER BY id_user DESC";
        return $this->conn->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    }

    // Busca productos por nombre (para el catálogo de la tienda)
    // Usa una función SQL que combina instrumentos y kits en productos
    public function buscarProductos($q = '')
    {
        $sql = "SELECT id, tipo, nombre, especializacion, nombre_origen, precio, img_url, categoria, descripcion FROM fun_buscar_productos(:q)";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':q' => $q]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // Lista de productos puros para gestión del administrador
    public function getProductosAdmin($soloHabilitados = true)
    {
        $sql = "SELECT p.id_producto as id, 
                       CASE WHEN p.id_instrumento IS NOT NULL THEN 'instrumento' ELSE 'kit' END as tipo,
                       p.nombre_producto as nombre, p.nombre_producto, p.precio_producto as precio, p.img_url,
                       p.id_instrumento, p.id_kit, p.ind_vivo,
                       COALESCE(i.nom_instrumento, k.nom_kit) as nombre_origen
                FROM tab_productos p
                LEFT JOIN tab_instrumentos i ON p.id_instrumento = i.id_instrumento
                LEFT JOIN tab_kits k ON p.id_kit = k.id_kit
                WHERE p.ind_vivo = :estado
                ORDER BY p.id_producto DESC LIMIT 100";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':estado' => $soloHabilitados ? 'true' : 'false']);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // Obtiene los materiales actualmente en Bodega (ingresados pero sin salida a producción ni bajas)
    public function getBodega()
    {
        $sql = "SELECT b.id_movimiento, TO_CHAR(b.fec_ingreso, 'YYYY-MM-DD HH24:MI:SS') as fec_ingreso,
                       mp.nom_materia_prima, mp.img_url,
                       p.nom_prov as proveedor,
                       mpp.lote, mpp.tipo_mat_prima, mpp.cant_mat_prima as cantidad_disponible,
                       mpp.valor_medida, um.nom_unidad
                FROM tab_bodega b
                JOIN tab_materias_primas mp ON b.id_mat_prima = mp.id_mat_prima
                JOIN tab_proveedores p ON b.id_prov = p.id_prov
                JOIN tab_mat_primas_prov mpp ON mpp.id_mat_prima = mp.id_mat_prima AND mpp.id_prov = p.id_prov
                JOIN tab_unidades_medida um ON mpp.id_unidad_medida = um.id_unidad_medida
                WHERE b.fec_salida IS NULL AND COALESCE(b.ind_vivo, true) = true
                ORDER BY b.fec_ingreso DESC";
        return $this->conn->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    }

    // Obtiene los materiales que ya pasaron a Producción (tienen fec_ingreso en tab_producc)
    public function getProduccion()
    {
        $sql = "SELECT pr.id_producc, TO_CHAR(pr.fec_ingreso, 'YYYY-MM-DD HH24:MI:SS') as fecha_produccion,
                       TO_CHAR(b.fec_ingreso, 'YYYY-MM-DD HH24:MI:SS') as fecha_bodega,
                       mp.nom_materia_prima, mp.img_url,
                       p.nom_prov as proveedor,
                       mpp.lote, mpp.tipo_mat_prima,
                       mpp.cant_mat_prima as cantidad_disponible,
                       mpp.valor_medida, um.nom_unidad
                FROM tab_producc pr
                JOIN tab_bodega b ON pr.id_movimiento = b.id_movimiento
                JOIN tab_materias_primas mp ON b.id_mat_prima = mp.id_mat_prima
                JOIN tab_proveedores p ON b.id_prov = p.id_prov
                JOIN tab_mat_primas_prov mpp ON mpp.id_mat_prima = mp.id_mat_prima AND mpp.id_prov = p.id_prov
                JOIN tab_unidades_medida um ON mpp.id_unidad_medida = um.id_unidad_medida
                WHERE COALESCE(pr.ind_vivo, true) = true
                ORDER BY pr.fec_ingreso DESC";
        return $this->conn->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    }

    // Obtiene el historial de fabricación de instrumentos (Kardex tipo 1=Entrada)
    public function getKardexInstrumentos()
    {
        $sql = "SELECT kp.id_kardex_producto, kp.cantidad, TO_CHAR(kp.fecha_movimiento, 'YYYY-MM-DD HH24:MI:SS') as fecha_movimiento, kp.observaciones,
                       i.nom_instrumento, i.img_url, i.lote, 
                       e.nom_espec as especializacion
                FROM tab_kardex_productos kp
                JOIN tab_instrumentos i ON kp.id_instrumento = i.id_instrumento
                LEFT JOIN tab_tipo_especializacion e ON i.id_especializacion = e.id_especializacion
                WHERE kp.id_instrumento IS NOT NULL AND kp.tipo_movimiento = 1 AND COALESCE(kp.ind_vivo, true) = true
                ORDER BY kp.fecha_movimiento DESC";
        return $this->conn->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    }

    // Obtiene el historial de ensamblaje de kits (Kardex tipo 1=Entrada)
    public function getKardexKits()
    {
        $sql = "SELECT kp.id_kardex_producto, kp.cantidad, TO_CHAR(kp.fecha_movimiento, 'YYYY-MM-DD HH24:MI:SS') as fecha_movimiento, kp.observaciones,
                       k.nom_kit, k.img_url,
                       e.nom_espec as especializacion
                FROM tab_kardex_productos kp
                JOIN tab_kits k ON kp.id_kit = k.id_kit
                LEFT JOIN tab_tipo_especializacion e ON k.id_especializacion = e.id_especializacion
                WHERE kp.id_kit IS NOT NULL AND kp.tipo_movimiento = 1 AND COALESCE(kp.ind_vivo, true) = true
                ORDER BY kp.fecha_movimiento DESC";
        return $this->conn->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    }

    // Registra un movimiento manual en el Kardex de productos (Instrumentos o Kits)
    // Usado para entradas de producción adicionales, ajustes, ventas o devoluciones.
    public function insertKardexProducto($d) {
        $sql = "SELECT fun_kardex_productos(:tipo_item, :id_item, :tipo_mov, :cant, :obs, :jreparable) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':tipo_item'   => (int) $d['tipo_item'], // 1: Instrumento, 2: Kit
            ':id_item'     => (int) $d['id_item'],
            ':tipo_mov'    => (int) $d['tipo_movimiento'],
            ':cant'        => (float) $d['cantidad'],
            ':obs'         => $d['observaciones'] ?? 'Movimiento manual',
            ':jreparable'  => isset($d['jreparable']) ? (bool) $d['jreparable'] : true
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // ══════════════════════════════════════════════════════════
    // SECCIÓN 4: INSERCIÓN DE REGISTROS
    // ══════════════════════════════════════════════════════════
    // Cada método llama a una función SQL almacenada en la BD
    // (fun_insert_...) que se encarga de las validaciones
    // Eliminación lógica (soft delete) de registros

    // Insertar nuevo usuario del sistema
    public function insertUser($nom, $pass, $tel, $mail)
    {
        $sql = "SELECT fun_insert_user(:nom, :pass, :tel, :mail) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':nom' => $nom, ':pass' => $pass, ':tel' => $tel, ':mail' => $mail]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Insertar nuevo cliente con datos personales y ubicación
    public function insertCliente($d)
    {
        $sql = "SELECT fun_insert_cliente(:id_doc, :id_ciudad, :ind_genero, :nom1, :nom2, :apell1, :apell2, :doc, :tel, :dir, :prof) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id_doc' => (int) $d['id_documento'],
            ':id_ciudad' => (int) $d['id_ciudad'],
            ':ind_genero' => (int) ($d['ind_genero'] ?? 1), // Default 1
            ':nom1' => $d['prim_nom'],
            ':nom2' => $d['segun_nom'] ?? '',
            ':apell1' => $d['prim_apell'],
            ':apell2' => $d['segun_apell'] ?? '',
            ':doc' => $d['num_documento'],
            ':tel' => $d['tel_cliente'],
            ':dir' => $d['dir_cliente'],
            ':prof' => $d['ind_profesion']
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Insertar nuevo empleado con datos personales, cargo, banco, etc.
    public function insertEmpleado($d)
    {
        $sql = "SELECT fun_insert_empleados(:id_doc, :id_ciudad, :id_cargo, :id_sangre, :ind_genero, :doc, :nom1, :nom2, :apell1, :apell2, :mail, :tel, :dir, :fecha, :peso, :alt, :fec_ex, :obs, :id_banco, :num_cuenta) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id_doc' => (int) $d['id_documento'],
            ':id_ciudad' => (int) $d['id_ciudad'],
            ':id_cargo' => (int) $d['id_cargo'],
            ':id_sangre' => (int) $d['id_tipo_sangre'],
            ':ind_genero' => (int) ($d['ind_genero'] ?? 1),
            ':doc' => $d['num_documento'],
            ':nom1' => $d['prim_nom'],
            ':nom2' => $d['segun_nom'] ?? '',
            ':apell1' => $d['prim_apell'],
            ':apell2' => $d['segun_apell'] ?? '',
            ':mail' => $d['mail_empleado'],
            ':tel' => $d['tel_empleado'],
            ':dir' => $d['dir_emple'],
            ':fecha' => $d['ind_fecha_contratacion'],
            ':peso' => !empty($d['ind_peso']) ? number_format((float) str_replace(',', '.', (string) $d['ind_peso']), 2, '.', '') : '0.00',
            ':alt' => !empty($d['ind_altura']) ? number_format((float) str_replace(',', '.', (string) $d['ind_altura']), 2, '.', '') : '0.00',
            ':fec_ex' => !empty($d['ult_fec_exam']) ? $d['ult_fec_exam'] : date('Y-m-d'),
            ':obs' => $d['observ'] ?? '',
            ':id_banco' => !empty($d['id_banco']) ? (int) $d['id_banco'] : 0,
            ':num_cuenta' => $d['num_cuenta'] ?? ''
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Insertar nuevo proveedor con documento y ubicación
    public function insertProveedor($d)
    {
        $sql = "SELECT fun_insert_proveedor(:id_doc, :id_ciudad, :doc, :nom, :tel, :mail, :dir, :calidad) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id_doc' => (int) $d['id_documento'],
            ':id_ciudad' => (int) $d['id_ciudad'],
            ':doc' => $d['num_documento'],
            ':nom' => $d['nom_prov'],
            ':tel' => $d['tel_prov'],
            ':mail' => $d['mail_prov'],
            ':dir' => $d['dir_prov'],
            ':calidad' => $d['ind_calidad']
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Insertar nueva categoría de materia prima
    public function insertCategoriaMateria($nom)
    {
        $sql = "SELECT fun_insert_cat_mat(:nom) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':nom' => $nom]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // si se especifica (creando la relación en tab_mat_primas_prov)
    public function insertMateriaPrima($d)
    {
        if (empty($d['img_url']))
            throw new Exception("Error: URL de imagen no puede estar vacía.");

        $sql = "SELECT fun_insert_materia_primas(:id_cat, :nom, :min, :max, :url, :precio) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id_cat' => (int) $d['id_cat_mat'],
            ':nom' => $d['nom_materia_prima'],
            ':min' => (int) ($d['stock_min'] ?? 0),
            ':max' => (int) ($d['stock_max'] ?? 0),
            ':url' => $d['img_url'],
            ':precio' => (float) ($d['precio_inicial'] ?? 0)
        ]);

        $res = $stmt->fetch(PDO::FETCH_ASSOC);

        // Si se insertó correctamente y se especificó un proveedor,
        // se crea el vínculo entre la materia prima y el proveedor
        if ($res && !empty($d['id_prov'])) {
            $stmtMax = $this->conn->query("SELECT MAX(id_mat_prima) as max_id FROM tab_materias_primas");
            $maxRow = $stmtMax->fetch(PDO::FETCH_ASSOC);
            $newId = $maxRow['max_id'];

            if ($newId) {
                // Vincular materia prima con proveedor (lote, tipo, valor, unidad, cantidad)
                $sqlProv = "SELECT fun_insert_mat_prima_proveedor(:id_mat, :id_prov, :lote, :tipo_mat, :valor, :unidad, :cant) as result_prov";
                $stmtProv = $this->conn->prepare($sqlProv);
                $stmtProv->execute([
                    ':id_mat' => $newId,
                    ':id_prov' => (int) $d['id_prov'],
                    ':lote' => $d['lote'] ?? '-',
                    ':tipo_mat' => $d['tipo_mat_prima'] ?? '-',
                    ':valor' => (float) ($d['valor_medida'] ?? 0),
                    ':unidad' => (int) ($d['id_unidad_medida'] ?? 1),
                    ':cant' => (int) ($d['cant_mat_prima'] ?? 0)
                ]);
            }
        }
        return $res;
    }


    // Insertar nuevo instrumento médico
    public function insertInstrumento($d)
    {
        if (empty($d['img_url']))
            throw new Exception("Error: URL de imagen no puede estar vacía.");

        // Parámetros: especialización, nombre, cantidad, lote, posición en kit, material, imagen, stock mín/máx
        $sql = "SELECT fun_insert_instrumentos(:id_espec, :nom, :cant, :lote, :num, :mat, :url, :min, :max) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id_espec' => (int) $d['id_especializacion'],
            ':nom' => $d['nom_instrumento'],
            ':cant' => (int) $d['cant_disp'],
            ':lote' => (int) ($d['lote'] ?? 0),
            ':num' => (int) ($d['numeral_en_kit'] ?? 0),
            ':mat' => (int) $d['tipo_mat'],
            ':url' => $d['img_url'],
            ':min' => (int) ($d['stock_min'] ?? 0),
            ':max' => (int) ($d['stock_max'] ?? 0)
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Insertar nuevo kit de instrumentos
    // Recibe también un arreglo de IDs de instrumentos que lo componen
    public function insertKit($d)
    {
        if (empty($d['img_url']))
            throw new Exception("Error: URL de imagen no puede estar vacía.");

        $sql = "SELECT fun_insert_kits(:id_espec, :nom, :cant, :mat, :min, :max, :url, :instrs) as result";
        $stmt = $this->conn->prepare($sql);

        // Convertir lista de IDs de instrumentos al formato PostgreSQL: "{1,2,3}"
        $instrsPG = '{}';
        if (isset($d['instruments']) && is_array($d['instruments']) && count($d['instruments']) > 0) {
            // Limpiar valores vacíos y asegurar que sean números enteros
            $cleanInst = array_filter($d['instruments'], function ($v) {
                return !empty($v);
            });
            $cleanInst = array_map('intval', $cleanInst);
            if (count($cleanInst) > 0) {
                $instrsPG = '{' . implode(',', $cleanInst) . '}';
            }
        }

        $stmt->execute([
            ':id_espec' => (int) $d['id_especializacion'],
            ':nom' => $d['nom_kit'],
            ':cant' => (int) $d['cant_disp'],
            ':mat' => (int) $d['tipo_mat'],
            ':min' => (int) ($d['stock_min'] ?? 0),
            ':max' => (int) ($d['stock_max'] ?? 0),
            ':url' => $d['img_url'] ?? '',
            ':instrs' => $instrsPG
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Insertar nuevo producto de venta (vinculado a instrumento o kit)
    public function insertProducto($d)
    {
        // SYNERGY: Si no se envía imagen, intentar obtenerla del origen (instrumento o kit)
        if (empty($d['img_url'])) {
            if (!empty($d['id_instrumento'])) {
                $st = $this->conn->prepare("SELECT img_url FROM tab_instrumentos WHERE id_instrumento = :id");
                $st->execute([':id' => (int) $d['id_instrumento']]);
                $row = $st->fetch(PDO::FETCH_ASSOC);
                $d['img_url'] = $row['img_url'] ?? '';
            } else if (!empty($d['id_kit'])) {
                $st = $this->conn->prepare("SELECT img_url FROM tab_kits WHERE id_kit = :id");
                $st->execute([':id' => (int) $d['id_kit']]);
                $row = $st->fetch(PDO::FETCH_ASSOC);
                $d['img_url'] = $row['img_url'] ?? '';
            }
        }

        if (empty($d['img_url']))
            throw new Exception("Error: URL de imagen no puede estar vacía y no se encontró imagen de origen.");

        // Un producto puede estar basado en un instrumento O en un kit (no ambos)
        $sql = "SELECT fun_insert_producto(:id_inst, :id_kit, :nom, :precio, :url) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id_inst' => !empty($d['id_instrumento']) ? (int) $d['id_instrumento'] : null,
            ':id_kit' => !empty($d['id_kit']) ? (int) $d['id_kit'] : null,
            ':nom' => $d['nombre_producto'],
            ':precio' => (float) $d['precio_producto'],
            ':url' => $d['img_url']
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // ══════════════════════════════════════════════════════════
    // SECCIÓN 5: ELIMINACIÓN LÓGICA (SOFT DELETE)
    // ══════════════════════════════════════════════════════════
    // No se borran registros de la base de datos.
    // Se marca ind_vivo = false para mantener historial.
    // Antes de eliminar se verifican dependencias:
    //   - Si un kit tiene instrumentos, no se puede eliminar
    //   - Si un instrumento está en un producto, no se puede eliminar
    //   Etc.

    // Eliminación genérica: determina la tabla y función SQL según el tipo
    /**
     * MÉTODO: deleteGeneric
     * PROPÓSITO: Realiza una "Eliminación Lógica" (ind_vivo = false) de cualquier registro en el sistema.
     * DISPARADOR: Se ejecuta cuando el usuario hace clic en el botón de basura (trash) en cualquier tabla de gestión.
     * FLUJO: 
     *   1. Recibe el 'tipo' (ej: instrumentos) y el 'id'.
     *   2. Antes de este método, el controlador (api_gestion.php) ya debió validar dependencias activas.
     *   3. Valida que el registro exista.
     *   4. Ejecuta la función SQL de borrado específica para la tabla.
     * LLAMADO DESDE: api_gestion.php -> Sección B (POST) -> case 'delete'
     */
    public function deleteGeneric($tipo, $id)
    {
        $sql = "";
        switch ($tipo) {
            case 'usuarios':
                $sql = "SELECT fun_user_delete(:id) as result";
                break;
            case 'clientes':
                $sql = "SELECT fun_delete_cliente(:id) as result";
                break;
            case 'empleados':
                $sql = "SELECT fun_delete_empleado(:id) as result";
                break;
            case 'proveedores':
                $sql = "SELECT fun_delete_prov(:id) as result";
                break;
            case 'instrumentos':
                $sql = "SELECT fun_delete_instrum(:id) as result";
                break;
            case 'kits':
                $sql = "SELECT fun_delete_kit(:id) as result";
                break;
            case 'productos':
                // Implementación directa por si la función fun_delete_producto falla o no existe
                // Se prepara la sentencia SQL para marcar como inactivo (soft delete)
                $sql = "UPDATE tab_productos SET ind_vivo = false, fec_update = NOW() WHERE id_producto = :id";
                // $this->conn -> Es la conexión activa a la base de datos (PDO)
                $stmt = $this->conn->prepare($sql);
                // .execute -> Envía la orden a la BD con el ID sanitizado para seguridad
                return ['result' => $stmt->execute([':id' => (int) $id])];
                break;
            case 'categorias_materia':
                $sql = "SELECT fun_delete_cat_mat_prim(:id) as result";
                break;
            case 'materias_primas':
                $sql = "SELECT fun_delete_materias_primas(:id) as result";
                break;
            default:
                return false;
        }

        // 1) Verificar que el registro existe y no fue eliminado previamente
        $checkSql = "";
        switch ($tipo) {
            case 'usuarios':
                $checkSql = "SELECT ind_vivo FROM tab_users WHERE id_user = :id";
                break;
            case 'clientes':
                $checkSql = "SELECT ind_vivo FROM tab_clientes WHERE id_cliente = :id";
                break;
            case 'empleados':
                $checkSql = "SELECT ind_vivo FROM tab_empleados WHERE id_empleado = :id";
                break;
            case 'proveedores':
                $checkSql = "SELECT ind_vivo FROM tab_proveedores WHERE id_prov = :id";
                break;
            case 'instrumentos':
                $checkSql = "SELECT ind_vivo FROM tab_instrumentos WHERE id_instrumento = :id";
                break;
            case 'kits':
                $checkSql = "SELECT ind_vivo FROM tab_kits WHERE id_kit = :id";
                break;
            case 'productos':
                $checkSql = "SELECT ind_vivo FROM tab_productos WHERE id_producto = :id";
                break;
            case 'categorias_materia':
                $checkSql = "SELECT ind_vivo FROM tab_cat_mat_prim WHERE id_cat_mat = :id";
                break;
            case 'materias_primas':
                $checkSql = "SELECT ind_vivo FROM tab_materias_primas WHERE id_mat_prima = :id";
                break;
        }

        if ($checkSql) {
            $checkStmt = $this->conn->prepare($checkSql);
            $checkStmt->execute([':id' => (int) $id]);
            $row = $checkStmt->fetch(PDO::FETCH_ASSOC);

            if (!$row)
                throw new Exception("Error: El registro no existe.");
            if ($row['ind_vivo'] === false || $row['ind_vivo'] === 0 || $row['ind_vivo'] === 'f') {
                throw new Exception("Error: El registro ya fue eliminado anteriormente.");
            }
        }

        // 2) Verificar dependencias (otros módulos pueden añadir sus checks en los controladores)
        // Se han movido las validaciones específicas a los controladores correspondientes para mejor mantenimiento
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':id' => (int) $id]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    /**
     * Restauración genérica de registros (Logical Restore)
     * Activa registros marcados como ind_vivo = false
     */
    /**
     * MÉTODO: restoreGeneric
     * PROPÓSITO: Revierte un borrado lógico, regresando un registro al estado activo (ind_vivo = true).
     * DISPARADOR: Se ejecuta cuando el usuario hace clic en el botón verde de "Restaurar" en la pestaña de Inhabilitados.
     * LLAMADO DESDE: api_gestion.php -> Sección B (POST) -> case 'restore'
     */
    public function restoreGeneric($tipo, $id)
    {
        $table = '';
        $pk = '';

        switch ($tipo) {
            case 'usuarios': $table = 'tab_users'; $pk = 'id_user'; break;
            case 'clientes': $table = 'tab_clientes'; $pk = 'id_cliente'; break;
            case 'empleados': $table = 'tab_empleados'; $pk = 'id_empleado'; break;
            case 'proveedores': $table = 'tab_proveedores'; $pk = 'id_prov'; break;
            case 'instrumentos': $table = 'tab_instrumentos'; $pk = 'id_instrumento'; break;
            case 'kits': $table = 'tab_kits'; $pk = 'id_kit'; break;
            case 'productos': $table = 'tab_productos'; $pk = 'id_producto'; break;
            case 'categorias_materia': $table = 'tab_cat_mat_prim'; $pk = 'id_cat_mat'; break;
            case 'materias_primas': $table = 'tab_materias_primas'; $pk = 'id_mat_prima'; break;
            default: return ['success' => false, 'error' => 'Tipo no soportado para restauración.'];
        }

        try {
            // Se construye el UPDATE dinámicamente según la tabla y su Clave Primaria (PK)
            $sql = "UPDATE $table SET ind_vivo = true, fec_update = NOW() WHERE $pk = :id";
            // .prepare($sql) -> Prepara la plantilla de la consulta para evitar Inyección SQL
            $stmt = $this->conn->prepare($sql);
            // .execute -> Ejecuta la consulta vinculando el parámetro :id de forma segura
            $res = $stmt->execute([':id' => (int)$id]);
            return ['success' => $res];
        } catch (Exception $e) {
            return ['success' => false, 'error' => $e->getMessage()];
        }
    }

    // ══════════════════════════════════════════════════════════
    // SECCIÓN 6: ACTUALIZACIÓN DE REGISTROS
    // ══════════════════════════════════════════════════════════

    // Actualización genérica: construye dinámicamente el UPDATE
    public function updateEmpleado($d)
    {
        $sql = "SELECT fun_update_empleados(:id, :id_doc, :id_ciudad, :id_cargo, :id_sangre, :ind_genero, :doc, :nom1, :nom2, :apell1, :apell2, :mail, :tel, :fecha, :peso, :alt, :fec_ex, :obs, :id_banco, :num_cuenta) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id' => (int) $d['id_empleado'],
            ':id_doc' => (int) $d['id_documento'],
            ':id_ciudad' => (int) $d['id_ciudad'],
            ':id_cargo' => (int) $d['id_cargo'],
            ':id_sangre' => (int) $d['id_tipo_sangre'],
            ':ind_genero' => (int) ($d['ind_genero'] ?? 1),
            ':doc' => $d['num_documento'],
            ':nom1' => $d['prim_nom'],
            ':nom2' => $d['segun_nom'] ?? '',
            ':apell1' => $d['prim_apell'],
            ':apell2' => $d['segun_apell'] ?? '',
            ':mail' => $d['mail_empleado'],
            ':tel' => $d['tel_empleado'],
            ':fecha' => $d['ind_fecha_contratacion'],
            ':peso' => !empty($d['ind_peso']) ? number_format((float) str_replace(',', '.', (string) $d['ind_peso']), 2, '.', '') : '0.00',
            ':alt' => !empty($d['ind_altura']) ? number_format((float) str_replace(',', '.', (string) $d['ind_altura']), 2, '.', '') : '0.00',
            ':fec_ex' => !empty($d['ult_fec_exam']) ? $d['ult_fec_exam'] : date('Y-m-d'),
            ':obs' => $d['observ'] ?? '',
            ':id_banco' => !empty($d['id_banco']) ? (int) $d['id_banco'] : null,
            ':num_cuenta' => $d['num_cuenta'] ?? ''
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Actualización de cliente usando la función SQL específica (incluye validaciones)
    public function updateCliente($d)
    {
        $sql = "SELECT fun_update_clientes(:id_cliente, :id_doc, :id_ciudad, :ind_genero, :nom1, :nom2, :apell1, :apell2, :doc, :tel, :dir, :prof, :puntos) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id_cliente' => (int) $d['id_cliente'],
            ':id_doc' => (int) $d['id_documento'],
            ':id_ciudad' => (int) $d['id_ciudad'],
            ':ind_genero' => (int) $d['ind_genero'],
            ':nom1' => $d['prim_nom'],
            ':nom2' => $d['segun_nom'] ?? '',
            ':apell1' => $d['prim_apell'],
            ':apell2' => $d['segun_apell'] ?? '',
            ':doc' => $d['num_documento'],
            ':tel' => $d['tel_cliente'],
            ':dir' => $d['dir_cliente'],
            ':prof' => $d['ind_profesion'],
            ':puntos' => (float) ($d['val_puntos'] ?? 0)
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Actualización de proveedor usando la función SQL específica
    public function updateProveedor($d)
    {
        $sql = "SELECT fun_update_proveedores(:id_prov, :id_doc, :id_ciudad, :num_doc, :nom, :tel, :mail, :dir, :calidad) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id_prov' => (int) $d['id_prov'],
            ':id_doc' => (int) $d['id_documento'],
            ':id_ciudad' => (int) $d['id_ciudad'],
            ':num_doc' => $d['num_documento'],
            ':nom' => $d['nom_prov'],
            ':tel' => $d['tel_prov'],
            ':mail' => $d['mail_prov'],
            ':dir' => $d['dir_prov'],
            ':calidad' => $d['ind_calidad']
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Actualización genérica: construye dinámicamente el UPDATE
    // según los campos que se modificaron. Registra quién
    // hizo el cambio y cuándo (auditoría).
    public function updateGeneric($table, $data, $idField, $idValue, $userSession)
    {
        $campos = [];
        $params = [':id' => $idValue, ':user' => $userSession];

        foreach ($data as $key => $val) {
            $campos[] = "$key = :val_$key";
            $params[":val_$key"] = $val;
        }

        if (empty($campos))
            return false;

        $sql = "UPDATE $table SET " . implode(', ', $campos) . ", user_update = :user, fec_update = NOW() WHERE $idField = :id";
        $stmt = $this->conn->prepare($sql);
        return $stmt->execute($params);
    }

    // ══════════════════════════════════════════════════════════
    // SECCIÓN 7: ACTUALIZACIONES ESPECÍFICAS
    // ══════════════════════════════════════════════════════════
    // Para instrumentos, kits, productos y materias primas
    // se necesitan validaciones adicionales (stock, imágenes,
    // registros INVIMA, etc.) que el update genérico no cubre.

    // Actualizar kit: valida stock, imagen, y reemplaza instrumentos
    public function updateKit($id, $d)
    {
        // Si no se envía nueva imagen, mantener la actual
        if (!isset($d['img_url']) || empty($d['img_url'])) {
            $stmtCurr = $this->conn->prepare("SELECT img_url FROM tab_kits WHERE id_kit = :id");
            $stmtCurr->execute([':id' => (int) $id]);
            $curr = $stmtCurr->fetch(PDO::FETCH_ASSOC);
            $d['img_url'] = $curr['img_url'] ?? '';
        }

        // Validaciones de datos antes de enviar a la BD
        if (empty($d['nom_kit']))
            throw new Exception("Error: Nombre del kit no puede estar vacío.");
        if ((int) $d['cant_disp'] < 0)
            throw new Exception("Error: La cantidad disponible no puede ser negativa.");
        if ((int) $d['stock_min'] < 0)
            throw new Exception("Error: Stock mínimo no puede ser negativo.");
        if ((int) $d['stock_max'] < 0)
            throw new Exception("Error: Stock máximo no puede ser negativo.");
        if ((int) $d['stock_max'] < (int) $d['stock_min'])
            throw new Exception("Error: Stock máximo no puede ser menor al stock mínimo.");
        if (empty($d['img_url']))
            // Si aun asi esta vacia (ej: no tenia en BD y no subio nueva), lanzamos error
            throw new Exception("Error: URL de imagen no puede estar vacía.");

        // Convertir lista de instrumentos al formato PostgreSQL: "{1,2,3}"
        $instrsPG = '{}';
        if (isset($d['instruments']) && is_array($d['instruments']) && count($d['instruments']) > 0) {
            // Limpiar y convertir a enteros
            $cleanInst = array_map('intval', array_filter($d['instruments'], function ($v) {
                return !empty($v);
            }));
            // Eliminar duplicados
            $cleanInst = array_unique($cleanInst);
            if (count($cleanInst) > 0) {
                $instrsPG = '{' . implode(',', $cleanInst) . '}';
            }
        }

        $sql = "SELECT fun_update_kits(:id, :id_espec, :nom, :cant, :mat, :min, :max, :url, :instrs) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id' => (int) $id,
            ':id_espec' => (int) $d['id_especializacion'],
            ':nom' => $d['nom_kit'],
            ':cant' => (int) $d['cant_disp'],
            ':mat' => (int) $d['tipo_mat'],
            ':min' => (int) $d['stock_min'],
            ':max' => (int) $d['stock_max'],
            ':url' => $d['img_url'],
            ':instrs' => $instrsPG
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Actualizar instrumento: valida stock, imagen, registro INVIMA
    public function updateInstrumento($id, $d)
    {
        // Si no se envía nueva imagen, mantener la actual
        if (!isset($d['img_url']) || empty($d['img_url'])) {
            $stmtCurr = $this->conn->prepare("SELECT img_url FROM tab_instrumentos WHERE id_instrumento = :id");
            $stmtCurr->execute([':id' => (int) $id]);
            $curr = $stmtCurr->fetch(PDO::FETCH_ASSOC);
            $d['img_url'] = $curr['img_url'] ?? '';
        }

        // Imagen obligatoria
        if (empty($d['img_url']))
            throw new Exception("Error: URL de imagen no puede estar vacía.");

        // Validaciones de datos
        if (empty($d['nom_instrumento']))
            throw new Exception("Error: El nombre del instrumento no puede estar vacío.");

        // La cantidad no puede ser negativa
        if ((int) $d['cant_disp'] < 0)
            throw new Exception("Error: La cantidad disponible no puede ser negativa.");

        // Validar stock mínimo y máximo si se envían
        if (isset($d['stock_min']) && (int) $d['stock_min'] < 0)
            throw new Exception("Error: Stock mínimo no puede ser negativo.");

        if (isset($d['stock_max']) && (int) $d['stock_max'] < 0)
            throw new Exception("Error: Stock máximo no puede ser negativo.");

        if ((int) ($d['stock_max'] ?? 0) < (int) ($d['stock_min'] ?? 0))
            throw new Exception("Error: Stock máximo no puede ser menor al stock mínimo.");

        $sql = "SELECT fun_update_instrumentos(:id, :id_espec, :nom, :lote, :cant, :min, :max, :num_kit, :mat, :url) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id' => (int) $id,
            ':id_espec' => (int) $d['id_especializacion'],
            ':nom' => $d['nom_instrumento'],
            ':lote' => (int) ($d['lote'] ?? 0),
            ':cant' => (int) $d['cant_disp'],
            ':min' => (int) ($d['stock_min'] ?? 0),
            ':max' => (int) ($d['stock_max'] ?? 0),
            ':num_kit' => (int) ($d['numeral_en_kit'] ?? 0),
            ':mat' => (int) ($d['tipo_mat'] ?? 1),
            ':url' => $d['img_url']
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Actualizar producto: valida imagen, nombre y precio
    public function updateProducto($id, $d)
    {
        // SYNERGY: Si no se envía nueva imagen, primero intentar mantener la actual.
        // Si no tenía imagen previa, intentar obtenerla del origen.
        if (!isset($d['img_url']) || empty($d['img_url'])) {
            $stmtCurr = $this->conn->prepare("SELECT img_url, id_instrumento, id_kit FROM tab_productos WHERE id_producto = :id");
            $stmtCurr->execute([':id' => (int) $id]);
            $curr = $stmtCurr->fetch(PDO::FETCH_ASSOC);
            $d['img_url'] = $curr['img_url'] ?? '';

            // Si aún está vacía, buscar en el origen (posible cambio de vínculo o registro incompleto)
            if (empty($d['img_url'])) {
                $idInst = !empty($d['id_instrumento']) ? (int)$d['id_instrumento'] : ($curr['id_instrumento'] ?? null);
                $idKit = !empty($d['id_kit']) ? (int)$d['id_kit'] : ($curr['id_kit'] ?? null);

                if ($idInst) {
                    $st = $this->conn->prepare("SELECT img_url FROM tab_instrumentos WHERE id_instrumento = :id");
                    $st->execute([':id' => $idInst]);
                    $row = $st->fetch(PDO::FETCH_ASSOC);
                    $d['img_url'] = $row['img_url'] ?? '';
                } else if ($idKit) {
                    $st = $this->conn->prepare("SELECT img_url FROM tab_kits WHERE id_kit = :id");
                    $st->execute([':id' => $idKit]);
                    $row = $st->fetch(PDO::FETCH_ASSOC);
                    $d['img_url'] = $row['img_url'] ?? '';
                }
            }
        }

        if (empty($d['img_url']))
            throw new Exception("Error: URL de imagen no puede estar vacía.");

        if (empty($d['nombre_producto']))
            throw new Exception("Error: Nombre del producto obligatorio.");

        if ((float) $d['precio_producto'] < 0)
            throw new Exception("Error: Precio no puede ser negativo.");

        // Un producto se vincula a un instrumento O a un kit (no ambos)
        $sql = "SELECT fun_update_producto(:id, :id_inst, :id_kit, :nom, :precio, :url) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id' => (int) $id,
            ':id_inst' => !empty($d['id_instrumento']) ? (int) $d['id_instrumento'] : null,
            ':id_kit' => !empty($d['id_kit']) ? (int) $d['id_kit'] : null,
            ':nom' => $d['nombre_producto'],
            ':precio' => (float) $d['precio_producto'],
            ':url' => $d['img_url']
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // ══════════════════════════════════════════════════════════
    // SECCIÓN 8: KARDEX (CONTROL DE INVENTARIO)
    // ══════════════════════════════════════════════════════════
    // El Kardex registra cada entrada y salida de materia prima.
    // Permite rastrear quién movió qué, cuándo y por qué.

    // Registrar un movimiento de entrada o salida de materia prima
    public function registrarMovimientoKardex($d)
    {
        $sql = "SELECT fun_kardex_materia_prima(:id_mat, :id_prov, :tipo, :cant, :valor, :unidad, :obs) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id_mat' => (int) $d['id_materia'],
            ':id_prov' => (int) $d['id_proveedor'],
            ':tipo' => (int) $d['tipo_movimiento'],
            ':cant' => (float) $d['cantidad'],
            ':valor' => (float) ($d['valor_medida'] ?? 0),
            ':unidad' => (int) ($d['id_unidad_medida'] ?? 1),
            ':obs' => $d['observaciones']
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
    // Actualizar nombre de categoría de materia prima
    public function updateCategoriaMateria($id, $nom)
    {
        $sql = "SELECT fun_update_cat_mat_prim(:id, :nom) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':id' => (int) $id, ':nom' => $nom]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Actualizar materia prima: imagen, categoría, stock, y vínculo con proveedor
    public function updateMateriaPrima($id, $d)
    {
        // Si no se envía nueva imagen, mantener la actual
        if (!isset($d['img_url']) || empty($d['img_url'])) {
            $stmtCurr = $this->conn->prepare("SELECT img_url FROM tab_materias_primas WHERE id_mat_prima = :id");
            $stmtCurr->execute([':id' => (int) $id]);
            $curr = $stmtCurr->fetch(PDO::FETCH_ASSOC);
            $d['img_url'] = $curr['img_url'] ?? '';
        }

        if (empty($d['img_url']))
            throw new Exception("Error: URL de imagen no puede estar vacía.");

        // Actualizar los datos principales de la materia prima (incluyendo precio histórico si cambió)
        $sql = "SELECT fun_update_materias_primas(:id, :id_cat, :nom, :min, :max, :url, :precio) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id' => (int) $id,
            ':id_cat' => (int) $d['id_cat_mat'],
            ':nom' => $d['nom_materia_prima'],
            ':min' => (int) ($d['stock_min'] ?? 0),
            ':max' => (int) ($d['stock_max'] ?? 0),
            ':url' => $d['img_url'],
            ':precio' => (float) ($d['precio_inicial'] ?? $d['precio'] ?? 0)
        ]);

        $res = $stmt->fetch(PDO::FETCH_ASSOC);

        // Actualizar o crear el vínculo con el proveedor si se especificó
        if (!empty($d['id_prov'])) {
            // Verificar si ya existe el vínculo
            $stmtCheck = $this->conn->prepare("SELECT 1 FROM tab_mat_primas_prov WHERE id_mat_prima = :id_mat AND id_prov = :id_prov");
            $stmtCheck->execute([':id_mat' => (int) $id, ':id_prov' => (int) $d['id_prov']]);

            if ($stmtCheck->fetch()) {
                // Si ya existe, actualizar valores de medida
                $sqlUpd = "UPDATE tab_mat_primas_prov SET valor_medida = :valor, id_unidad_medida = :unidad WHERE id_mat_prima = :id_mat AND id_prov = :id_prov";
                $stmtUpd = $this->conn->prepare($sqlUpd);
                $stmtUpd->execute([
                    ':valor' => (float) ($d['valor_medida'] ?? 0),
                    ':unidad' => (int) ($d['id_unidad_medida'] ?? 1),
                    ':id_mat' => (int) $id,
                    ':id_prov' => (int) $d['id_prov']
                ]);
            } else {
                // Si no existe, crear nuevo vínculo proveedor-materia prima
                $sqlAdd = "SELECT fun_insert_mat_prima_proveedor(:id_mat, :id_prov, :lote, :tipo, :valor, :unidad, :cant) as res_prov";
                $stmtAdd = $this->conn->prepare($sqlAdd);
                $stmtAdd->execute([
                    ':id_mat' => (int) $id,
                    ':id_prov' => (int) $d['id_prov'],
                    ':lote' => $d['lote'] ?? '-',
                    ':tipo' => $d['tipo_mat_prima'] ?? '-',
                    ':valor' => (float) ($d['valor_medida'] ?? 0),
                    ':unidad' => (int) ($d['id_unidad_medida'] ?? 1),
                    ':cant' => 0 // Stock inicial 0, se maneja por Kardex
                ]);
            }
        }

        return $res;
    }

    // Obtener historial de movimientos de productos finalizados (específicamente ventas y devoluciones)
    public function getKardexVentasDevoluciones() {
        $sql = "(SELECT k.id_kardex_producto, k.id_instrumento, k.id_kit, k.tipo_movimiento, k.cantidad, 
                       TO_CHAR(k.fecha_movimiento, 'YYYY-MM-DD HH24:MI:SS') as fecha_movimiento, 
                       k.observaciones,
                       COALESCE(p.nombre_producto, i.nom_instrumento, kit.nom_kit) as producto_nombre,
                       CASE WHEN k.id_instrumento IS NOT NULL THEN 'Instrumento' ELSE 'Kit' END as producto_tipo,
                       COALESCE(
                           substring(k.observaciones from 'VENTA\\[([0-9a-zA-Z-]+)\\]'),
                           substring(k.observaciones from 'DEVOLUCI\\[([0-9a-zA-Z-]+)\\]'),
                           substring(k.observaciones from 'Factura #([0-9]+)')
                       ) as id_factura_ref,
                       'Finalizado' as estado_gestion
                FROM tab_kardex_productos k
                LEFT JOIN tab_instrumentos i ON k.id_instrumento = i.id_instrumento
                LEFT JOIN tab_kits kit ON k.id_kit = kit.id_kit
                LEFT JOIN tab_productos p ON (k.id_instrumento = p.id_instrumento OR k.id_kit = p.id_kit)
                WHERE k.tipo_movimiento IN (2, 5))
                
                UNION ALL
                
                (SELECT dr.id_devol_reparable, null, null, 5, dr.cantidad,
                       TO_CHAR(dr.fec_insert, 'YYYY-MM-DD HH24:MI:SS'),
                       'Devolución Pendiente - Factura #' || dr.id_factura,
                       p.nombre_producto,
                       'Producto',
                       dr.id_factura::TEXT,
                       'PENDIENTE'
                FROM tab_devol_reparable dr
                JOIN tab_productos p ON dr.id_producto = p.id_producto
                WHERE dr.id_estado_devol = 1 AND dr.ind_vivo = true)
                
                ORDER BY fecha_movimiento DESC";
        return $this->conn->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    }

    /**
     * MÉTODO: registrarVentaFormal
     * PROPÓSITO: Crea una factura y registra la salida de inventario múltiple.
     * FLUJO: Disparado desde el modal "Venta Crítica" al seleccionar varios items.
     * TÉCNICO: Recibe arrays de IDs y cantidades y los inyecta en la función SQL fun_fact.
     */
    public function registrarVentaFormal($d) {
        // Formatear arrays para PostgreSQL: {val1, val2, ...}
        $ids = '{' . implode(',', (array)$d['id_productos']) . '}';
        $cants = '{' . implode(',', (array)$d['cantidades']) . '}';

        $sql = "SELECT fun_fact(:id_cliente, :ids::INTEGER[], :cants::INTEGER[], :id_pago, :observaciones) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id_cliente'   => !empty($d['id_cliente']) ? (int) $d['id_cliente'] : null,
            ':ids'          => $ids,
            ':cants'        => $cants,
            ':id_pago'      => (int) $d['id_forma_pago'],
            ':observaciones'=> $d['observaciones'] ?? 'Venta formalizada'
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Búsqueda avanzada de facturas para el proceso de devolución
    public function buscarFacturasParaDevolucion($mes, $anio, $query) {
        $params = [':y' => (int)$anio];
        $filtroMes = "";
        if ($mes > (int)0) {
            $filtroMes = "AND EXTRACT(MONTH FROM f.fecha_venta) = :m";
            $params[':m'] = (int)$mes;
        }

        $filtroQuery = "";
        if (!empty($query)) {
            $filtroQuery = "AND (c.prim_nom || ' ' || c.prim_apell ILIKE :q OR f.id_factura::TEXT LIKE :qtxt)";
            $params[':q'] = "%$query%";
            $params[':qtxt'] = "%$query%";
        }

        $sql = "SELECT f.id_factura, f.fecha_venta, f.val_tot_fact, 
                       c.prim_nom || ' ' || c.prim_apell as cliente_nombre
                FROM tab_facturas f
                JOIN tab_clientes c ON f.id_cliente = c.id_cliente
                WHERE EXTRACT(YEAR FROM f.fecha_venta) = :y
                $filtroMes $filtroQuery
                AND f.ind_vivo = true
                ORDER BY f.fecha_venta DESC LIMIT 50";
        
        $stmt = $this->conn->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // Procesa la devolución de múltiples items de una misma factura
    public function registrarDevolucionMultiple($d) {
        $ids = '{' . implode(',', (array)$d['id_productos']) . '}';
        $cants = '{' . implode(',', (array)$d['cantidades']) . '}';
        // Mapear booleanos a strings 'true'/'false' para el array de PG
        $reparables = '{' . implode(',', array_map(function($v){ return $v ? 'true' : 'false'; }, (array)$d['reparables'])) . '}';

        $sql = "SELECT fun_registrar_devolucion_multiple(:id_factura, :ids::INTEGER[], :cants::INTEGER[], :reps::BOOLEAN[], :obs) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id_factura' => (int)$d['id_factura'],
            ':ids'         => $ids,
            ':cants'       => $cants,
            ':reps'        => $reparables,
            ':obs'         => $d['observaciones']
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function getDevolucionesPendientes() {
        $sql = "SELECT dr.id_devol_reparable, dr.id_factura, dr.id_producto, dr.cantidad, dr.id_estado_devol,
                       TO_CHAR(dr.fec_insert, 'YYYY-MM-DD HH24:MI:SS') as fecha_devolucion,
                       p.nombre_producto, p.img_url
                FROM tab_devol_reparable dr
                JOIN tab_productos p ON dr.id_producto = p.id_producto
                WHERE dr.id_estado_devol = 1 AND dr.ind_vivo = true
                ORDER BY dr.fec_insert DESC";
        return $this->conn->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    }

    public function resolverDevolucion($d) {
        $sql = "SELECT fun_resolver_devolucion(:id, :estado) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id' => (int)$d['id_devol_reparable'],
            ':estado' => (int)$d['id_nuevo_estado']
        ]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Obtener encabezado de factura (Datos de cliente y totales)
    public function getFacturaEncabezado($id_factura) {
        $sql = "SELECT f.*, c.num_documento, c.prim_nom || ' ' || c.prim_apell as cliente_nombre,
                       c.dir_cliente, c.tel_cliente, ci.nom_ciudad, td.nom_tipo_docum
                FROM tab_facturas f
                JOIN tab_clientes c ON f.id_cliente = c.id_cliente
                LEFT JOIN tab_ciudades ci ON c.id_ciudad = ci.id_ciudad
                LEFT JOIN tab_tipo_documentos td ON c.id_documento = td.id_documento
                WHERE f.id_factura = :id";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':id' => $id_factura]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Obtener detalle de factura (Productos y precios)
    public function getFacturaDetalle($id_factura) {
        $sql = "SELECT df.*, p.nombre_producto, p.id_instrumento, p.id_kit
                FROM tab_detalle_facturas df
                JOIN tab_productos p ON df.id_producto = p.id_producto
                WHERE df.id_factura = :id";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':id' => $id_factura]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // Obtener datos del vínculo materia prima-proveedor
    // para autocompletar unidad y valor en movimientos de Kardex
    public function getMatProvMetadata($id_mat, $id_prov)
    {
        $sql = "SELECT valor_medida, id_unidad_medida FROM tab_mat_primas_prov WHERE id_mat_prima = :id_mat AND id_prov = :id_prov LIMIT 1";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':id_mat' => (int) $id_mat, ':id_prov' => (int) $id_prov]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    // Historial completo de movimientos de Kardex de materia prima
    public function getKardexHistory()
    {
        $sql = "SELECT k.id_kardex_mat_prima, k.id_materia_prima, k.id_unidad_medida, k.valor_medida, 
                       k.tipo_movimiento, k.cantidad, TO_CHAR(k.fecha_movimiento, 'YYYY-MM-DD HH24:MI:SS') as fecha_movimiento, k.observaciones, TO_CHAR(k.fec_insert, 'YYYY-MM-DD HH24:MI:SS') as fec_insert,
                       mp.nom_materia_prima, 
                       um.nom_unidad
                FROM tab_kardex_mat_prima k
                LEFT JOIN tab_materias_primas mp ON k.id_materia_prima = mp.id_mat_prima
                LEFT JOIN tab_unidades_medida um ON k.id_unidad_medida = um.id_unidad_medida
                WHERE k.ind_vivo = true
                ORDER BY k.fec_insert DESC";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // Eliminar materia prima (función individual)
    public function deleteMateriaPrima($id)
    {
        $sql = "SELECT fun_delete_materias_primas(:id) as result";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':id' => (int) $id]);
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }
    // Lista simple de materias primas (para selectores/dropdowns)
    public function getMateriasPrimasList()
    {
        $sql = "SELECT id_mat_prima, nom_materia_prima FROM tab_materias_primas WHERE ind_vivo = true ORDER BY nom_materia_prima ASC";
        return $this->conn->query($sql)->fetchAll(PDO::FETCH_ASSOC);
    }

    // Materias primas filtradas por categoría
    // Incluye datos del proveedor vinculado si existe
    public function getMateriasXCategoria($id_cat, $soloHabilitados = true)
    {
        $sql = "SELECT mp.id_mat_prima, mp.nom_materia_prima, mp.id_cat_mat, mp.img_url, mp.stock_min, mp.stock_max, mp.ind_vivo,
                       um.nom_unidad as medida_mat_prima, 
                       mpp.id_unidad_medida,
                       mpp.id_prov,
                       p.nom_prov as proveedor,
                       mpp.valor_medida,
                       mpp.cant_mat_prima,
                       (SELECT precio_nuevo FROM tab_historico_mat_prima h 
                        WHERE h.id_materia_prima = mp.id_mat_prima 
                        AND h.id_proveedor = mpp.id_prov 
                        ORDER BY h.fec_insert DESC LIMIT 1) as precio_actual
                FROM tab_materias_primas mp
                LEFT JOIN tab_mat_primas_prov mpp ON mp.id_mat_prima = mpp.id_mat_prima
                LEFT JOIN tab_proveedores p ON mpp.id_prov = p.id_prov
                LEFT JOIN tab_unidades_medida um ON mpp.id_unidad_medida = um.id_unidad_medida
                WHERE mp.id_cat_mat = :id_cat AND mp.ind_vivo = :estado
                ORDER BY mp.nom_materia_prima ASC";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([
            ':id_cat' => (int) $id_cat,
            ':estado' => $soloHabilitados ? 'true' : 'false'
        ]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // Obtener historial de precios de una materia prima
    public function getHistoricoPrecios($id) {
        $sql = "SELECT * FROM fun_get_historico_precios(:id)";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':id' => (int) $id]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // Todas las materias primas disponibles para un proveedor
    // (muestra stock si está vinculado, 0 si no)
    public function getMateriasByProveedor($id_prov)
    {
        $sql = "SELECT mp.id_mat_prima, mp.nom_materia_prima, 
                       mpp.valor_medida,
                       mpp.id_unidad_medida,
                       um.nom_unidad as medida_mat_prima, 
                       mpp.cant_mat_prima 
                FROM tab_materias_primas mp
                LEFT JOIN tab_mat_primas_prov mpp ON mp.id_mat_prima = mpp.id_mat_prima AND mpp.id_prov = :id
                LEFT JOIN tab_unidades_medida um ON mpp.id_unidad_medida = um.id_unidad_medida
                WHERE mp.ind_vivo = true
                ORDER BY mp.nom_materia_prima ASC";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute([':id' => (int) $id_prov]);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    // ============================================================
    // SECCIÓN Finanzas: Estadísticas y Reportes
    // ============================================================

    public function getFinanzasStats($mes, $anio)
    {
        $filtroMes = ($mes > 0) ? "AND EXTRACT(MONTH FROM fecha_venta) = :m" : "";
        $params = [':y' => $anio];
        if ($mes > 0) $params[':m'] = $mes;

        // Ingresos Totales
        $sqlTotal = "SELECT SUM(val_tot_fact) as total FROM tab_facturas 
                     WHERE EXTRACT(YEAR FROM fecha_venta) = :y 
                     $filtroMes 
                     AND id_estado_fact = 1"; // Solo pagadas
        $stmt = $this->conn->prepare($sqlTotal);
        $stmt->execute($params);
        $totalIngresos = $stmt->fetch(PDO::FETCH_ASSOC)['total'] ?? 0;

        // Tasa de Retorno
        $sqlDev = "SELECT 
                    (SELECT COUNT(d.id_factura) FROM tab_dev d JOIN tab_facturas f ON d.id_factura = f.id_factura 
                     WHERE EXTRACT(YEAR FROM f.fecha_venta) = :y $filtroMes) as total_dev,
                    (SELECT COUNT(id_factura) FROM tab_facturas 
                     WHERE EXTRACT(YEAR FROM fecha_venta) = :y $filtroMes) as total_fact";
        $stmt = $this->conn->prepare($sqlDev);
        $stmt->execute($params);
        $devInfo = $stmt->fetch(PDO::FETCH_ASSOC);

        // Medios de Pago
        $sqlPagos = "SELECT ind_forma_pago, COUNT(id_factura) as cantidad, SUM(val_tot_fact) as monto
                     FROM tab_facturas 
                     WHERE EXTRACT(YEAR FROM fecha_venta) = :y
                     $filtroMes
                     GROUP BY ind_forma_pago";
        $stmt = $this->conn->prepare($sqlPagos);
        $stmt->execute($params);
        $mediosPago = $stmt->fetchAll(PDO::FETCH_ASSOC);

        // Rentabilidad Global
        $rentabilidad = $this->getRentabilidadGlobal($mes, $anio);

        return [
            'total_ingresos' => (float)$totalIngresos,
            'devoluciones' => $devInfo,
            'medios_pago' => $mediosPago,
            'rentabilidad' => $rentabilidad
        ];
    }

    public function getRentabilidadGlobal($mes, $anio)
    {
        $filtroMes = ($mes > 0) ? "AND EXTRACT(MONTH FROM k.fecha_movimiento) = :m" : "";
        $params = [':y' => $anio];
        if ($mes > 0) $params[':m'] = $mes;

        // Cálculo de Costos (Kardex tipo 2 + Histórico de precios)
        $sqlCostos = "SELECT SUM(k.cantidad * h.precio_nuevo) as total_costos
                      FROM tab_kardex_mat_prima k
                      CROSS JOIN LATERAL (
                          SELECT precio_nuevo 
                          FROM tab_historico_mat_prima h
                          WHERE h.id_materia_prima = k.id_materia_prima 
                          AND h.fecha_cambio <= k.fecha_movimiento
                          ORDER BY h.fecha_cambio DESC 
                          LIMIT 1
                      ) h
                      WHERE k.tipo_movimiento = 2 -- Salida a Producción
                      AND EXTRACT(YEAR FROM k.fecha_movimiento) = :y
                      $filtroMes";
        
        $stmt = $this->conn->prepare($sqlCostos);
        $stmt->execute($params);
        $costos = (float)($stmt->fetch(PDO::FETCH_ASSOC)['total_costos'] ?? 0);

        // Ingresos del mismo periodo (Solo pagadas)
        $filtroMesFact = ($mes > 0) ? "AND EXTRACT(MONTH FROM fecha_venta) = :m" : "";
        $sqlIngresos = "SELECT SUM(val_tot_fact) as total_ingresos 
                        FROM tab_facturas 
                        WHERE EXTRACT(YEAR FROM fecha_venta) = :y 
                        $filtroMesFact 
                        AND id_estado_fact = 1";
        
        $stmt = $this->conn->prepare($sqlIngresos);
        $stmt->execute($params);
        $ingresos = (float)($stmt->fetch(PDO::FETCH_ASSOC)['total_ingresos'] ?? 0);

        $utilidad = $ingresos - $costos;
        $margen = ($ingresos > 0) ? ($utilidad / $ingresos) * 100 : 0;

        return [
            'ingresos' => $ingresos,
            'costos' => $costos,
            'utilidad' => $utilidad,
            'margen' => round($margen, 2)
        ];
    }

    public function getTicketEspecialidad($mes, $anio)
    {
        $filtroMes = ($mes > 0) ? "AND EXTRACT(MONTH FROM f.fecha_venta) = :m" : "";
        $params = [':y' => $anio];
        if ($mes > 0) $params[':m'] = $mes;

        $sql = "SELECT 
                    te.nom_espec as especialidad,
                    AVG(df.val_neto) as ticket_promedio,
                    COUNT(df.id_producto) as volumen_ventas
                FROM tab_detalle_facturas df
                JOIN tab_facturas f ON df.id_factura = f.id_factura
                JOIN tab_productos p ON df.id_producto = p.id_producto
                LEFT JOIN tab_instrumentos i ON p.id_instrumento = i.id_instrumento
                LEFT JOIN tab_kits k ON p.id_kit = k.id_kit
                JOIN tab_tipo_especializacion te ON (i.id_especializacion = te.id_especializacion OR k.id_especializacion = te.id_especializacion)
                WHERE EXTRACT(YEAR FROM f.fecha_venta) = :y
                $filtroMes
                GROUP BY te.nom_espec";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getPrevisionesCompra()
    {
        $sql = "SELECT 
                    mp.nom_materia_prima as material,
                    mp.stock_min,
                    SUM(mpp.cant_mat_prima) as stock_actual,
                    prov.nom_prov as proveedor,
                    prov.tel_prov as telefono
                FROM tab_materias_primas mp
                JOIN tab_mat_primas_prov mpp ON mp.id_mat_prima = mpp.id_mat_prima
                JOIN tab_proveedores prov ON mpp.id_prov = prov.id_prov
                WHERE mp.ind_vivo = true
                GROUP BY mp.id_mat_prima, mp.nom_materia_prima, mp.stock_min, prov.nom_prov, prov.tel_prov
                HAVING SUM(mpp.cant_mat_prima) <= mp.stock_min
                ORDER BY mp.stock_min DESC";
        $stmt = $this->conn->query($sql);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getReporteFinanzasDetallado($mes, $anio)
    {
        $filtroMes = ($mes > 0) ? "AND EXTRACT(MONTH FROM f.fecha_venta) = :m" : "";
        $params = [':y' => $anio];
        if ($mes > 0) $params[':m'] = $mes;

        $sql = "SELECT f.id_factura as \"ID Factura\", 
                       TO_CHAR(f.fecha_venta, 'YYYY-MM-DD HH24:MI:SS') as \"Fecha\",
                       CASE EXTRACT(MONTH FROM f.fecha_venta)
                            WHEN 1 THEN 'Enero' WHEN 2 THEN 'Febrero' WHEN 3 THEN 'Marzo'
                            WHEN 4 THEN 'Abril' WHEN 5 THEN 'Mayo' WHEN 6 THEN 'Junio'
                            WHEN 7 THEN 'Julio' WHEN 8 THEN 'Agosto' WHEN 9 THEN 'Septiembre'
                            WHEN 10 THEN 'Octubre' WHEN 11 THEN 'Noviembre' WHEN 12 THEN 'Diciembre'
                       END as \"Mes\",
                       string_agg(p.nombre_producto, ', ') as \"Productos Comprados\",
                       c.prim_nom || ' ' || c.prim_apell as \"Cliente\",
                       f.val_tot_fact as \"Total\",
                       CASE f.ind_forma_pago 
                            WHEN 1 THEN 'Efectivo' 
                            WHEN 2 THEN 'Transferencia' 
                            WHEN 3 THEN 'Tarjeta' 
                            ELSE 'Otro' 
                       END as \"Medio de Pago\"
                FROM tab_facturas f
                JOIN tab_clientes c ON f.id_cliente = c.id_cliente
                LEFT JOIN tab_detalle_facturas df ON f.id_factura = df.id_factura
                LEFT JOIN tab_productos p ON df.id_producto = p.id_producto
                WHERE EXTRACT(YEAR FROM f.fecha_venta) = :y
                $filtroMes
                AND f.ind_vivo = true
                GROUP BY f.id_factura, f.fecha_venta, f.val_tot_fact, f.ind_forma_pago, c.id_cliente, c.prim_nom, c.prim_apell
                ORDER BY f.id_factura DESC";
        $stmt = $this->conn->prepare($sql);
        $stmt->execute($params);
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
?>
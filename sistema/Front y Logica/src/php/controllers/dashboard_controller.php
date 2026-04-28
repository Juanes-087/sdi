<?php
/**
 * ============================================================
 * CONTROLADOR DEL PANEL DE ADMINISTRACIÓN (DASHBOARD)
 * ============================================================
 * 
 * PROPÓSITO:
 * Este archivo es el "cerebro" detrás de la página principal
 * del administrador (menuPrincipal.php). Se ejecuta ANTES de
 * mostrar cualquier contenido visual.
 * 
 * RESPONSABILIDADES:
 * 1. Validar la identidad del usuario (JWT o sesión PHP)
 * 2. Redirigir a clientes hacia su menú propio
 * 3. Procesar cambios de contraseña y perfil
 * 4. Cargar las estadísticas del dashboard
 * 5. Cargar listas auxiliares (ciudades, cargos, etc.)
 * 
 * FLUJO DE AUTENTICACIÓN:
 * ┌─────────────────────────────────────────────────┐
 * │ ¿Viene con token JWT en la URL?                │
 * │   SÍ → Validar token → Crear sesión → Redirigir│
 * │   NO → ¿Tiene sesión PHP activa?               │
 * │          SÍ → ¿Es cliente? → Redirigir a menú  │
 * │          NO → Redirigir a Inicio de Sesión      │
 * └─────────────────────────────────────────────────┘
 * 
 * SEGURIDAD:
 * - Regeneración de ID de sesión (anti-fijación)
 * - Token JWT se elimina de la URL después de uso
 * - Sentencias preparadas para todas las consultas
 * - Verificación de contraseña con soporte legacy
 * ============================================================
 */

// ══════════════════════════════════════════════════════════
// SECCIÓN 1: CARGA DE DEPENDENCIAS
// ══════════════════════════════════════════════════════════
// Se cargan los archivos base que necesita el controlador
include_once(__DIR__ . "/../security_headers.php");  // Cabeceras de seguridad
include_once(__DIR__ . "/../conexion.php");           // Conexión a la base de datos
include_once(__DIR__ . "/../querys.php");             // Clase de consultas SQL
include_once(__DIR__ . "/../jwt.php");                // Funciones de JWT

// ══════════════════════════════════════════════════════════
// SECCIÓN 2: AUTENTICACIÓN POR TOKEN JWT
// ══════════════════════════════════════════════════════════
// Si el usuario llega con un token en la URL (ej: desde
// el formulario de login), se valida y se crea una sesión.
$token = $_GET['token'] ?? null;

if ($token) {
    // Intentar decodificar y verificar el token
    $payload = validarJWT($token);

    if ($payload && isset($payload['id'])) {
        // Token válido: crear sesión PHP con los datos del usuario
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        // Regenerar ID para prevenir ataques de fijación de sesión
        session_regenerate_id(true);

        // Guardar datos básicos del token en la sesión
        $_SESSION['id_usuario'] = $payload['id'];
        $_SESSION['nom_user'] = $payload['usuario'] ?? '';
        $_SESSION['id_menu'] = $payload['menu'] ?? 1;

        // Complementar con datos completos desde la base de datos
        $conexion = new CConexion();
        $conn = $conexion->conexionBD();
        if ($conn) {
            try {
                $sql = "SELECT nom_user, mail_user, tel_user FROM tab_users WHERE id_user = :id";
                $stmt = $conn->prepare($sql);
                $stmt->bindParam(":id", $_SESSION['id_usuario'], PDO::PARAM_INT);
                $stmt->execute();
                $userData = $stmt->fetch(PDO::FETCH_ASSOC);

                if ($userData) {
                    $_SESSION['nom_user'] = $userData['nom_user'] ?? $_SESSION['nom_user'];
                    $_SESSION['mail_user'] = $userData['mail_user'] ?? '';
                    $_SESSION['tel_user'] = $userData['tel_user'] ?? '';
                }
            } catch (PDOException $e) {
                error_log("Error al cargar datos del usuario: " . $e->getMessage());
            }
        }

        // Redirigir sin el token en la URL (seguridad: evita que
        // el token quede visible en el historial del navegador)
        header("Location: menuPrincipal.php");
        exit();
    } else {
        // Token inválido o expirado: enviar al inicio de sesión
        header("Location: ../../html/InicioSesion.html");
        exit();
    }
}

// ══════════════════════════════════════════════════════════
// SECCIÓN 3: VALIDACIÓN DE SESIÓN EXISTENTE
// ══════════════════════════════════════════════════════════
// Si no llegó con token, verificar que tenga sesión activa
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Si no hay sesión activa, no tiene acceso
if (!isset($_SESSION['id_usuario'])) {
    header("Location: ../../html/InicioSesion.html");
    exit();
}

// Control de acceso por rol: si es cliente (menú 2),
// redirigir al menú de clientes (no al panel de admin)
if (isset($_SESSION['id_menu']) && $_SESSION['id_menu'] == 2) {
    header("Location: ../php/menuCliente.php");
    exit();
}

// Si hay sesión pero faltan datos (ej: sesión antigua),
// completar la información desde la base de datos
if (isset($_SESSION['id_usuario']) && (!isset($_SESSION['mail_user']) || !isset($_SESSION['tel_user']))) {
    $conexion = new CConexion();
    $conn = $conexion->conexionBD();
    if ($conn) {
        try {
            $sql = "SELECT nom_user, mail_user, tel_user FROM tab_users WHERE id_user = :id";
            $stmt = $conn->prepare($sql);
            $stmt->bindParam(":id", $_SESSION['id_usuario'], PDO::PARAM_INT);
            $stmt->execute();
            $userData = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($userData) {
                $_SESSION['nom_user'] = $userData['nom_user'] ?? $_SESSION['nom_user'] ?? '';
                $_SESSION['mail_user'] = $userData['mail_user'] ?? '';
                $_SESSION['tel_user'] = $userData['tel_user'] ?? '';
            }
        } catch (PDOException $e) {
            error_log("Error al cargar datos del usuario: " . $e->getMessage());
        }
    }
}

// ══════════════════════════════════════════════════════════
// SECCIÓN 4: PROCESAMIENTO DE CAMBIO DE CONTRASEÑA (POST)
// ══════════════════════════════════════════════════════════
// Cuando el usuario envía el formulario de cambio de
// contraseña desde el modal en footer.php
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['cambiar_password'])) {
    // Obtener los 3 campos del formulario
    $password_actual = trim($_POST["password_actual"] ?? "");
    $password_nueva = trim($_POST["password_nueva"] ?? "");
    $password_confirmar = trim($_POST["password_confirmar"] ?? "");

    // Validaciones previas antes de consultar la base de datos
    if ($password_actual === '' || $password_nueva === '' || $password_confirmar === '') {
        $_SESSION['error_password'] = "Todos los campos son obligatorios";
    } elseif (strlen($password_nueva) < 8) {
        $_SESSION['error_password'] = "La nueva contraseña debe tener al menos 8 caracteres";
    } elseif ($password_nueva !== $password_confirmar) {
        $_SESSION['error_password'] = "Las contraseñas nuevas no coinciden";
    } else {
        $id_usuario = $_SESSION['id_usuario'];
        $conexion = new CConexion();
        $conn = $conexion->conexionBD();

        if ($conn) {
            try {
                // Obtener contraseña actual del usuario
                $sql = "SELECT pass_user FROM tab_users WHERE id_user = :id";
                $stmt = $conn->prepare($sql);
                $stmt->bindParam(":id", $id_usuario, PDO::PARAM_INT);
                $stmt->execute();
                $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

                if ($usuario) {
                    // Verificar la contraseña actual del usuario
                    $password_valida = false;
                    $pass_hash = $usuario['pass_user'];

                    // Detectar si la contraseña almacenada es un hash seguro
                    // o un texto plano (contraseñas antiguas/legacy)
                    if (substr($pass_hash, 0, 4) === '$2y$' || substr($pass_hash, 0, 4) === '$2a$' || substr($pass_hash, 0, 4) === '$2b$') {
                        // Es un hash moderno (bcrypt), verificar con la función segura
                        $password_valida = password_verify($password_actual, $pass_hash);
                    } else {
                        // Contraseña legacy (texto plano), comparar directamente
                        $password_valida = ($pass_hash === $password_actual);
                    }

                    if ($password_valida) {
                        // Crear hash seguro de la nueva contraseña
                        $password_hash = password_hash($password_nueva, PASSWORD_DEFAULT);

                        // Guardar la nueva contraseña en la base de datos
                        // También registra quién hizo el cambio y cuándo
                        $sql_update = "UPDATE tab_users 
                                      SET pass_user = :pass,
                                          user_update = :user_update,
                                          fec_update = NOW()
                                      WHERE id_user = :id";

                        $stmt_update = $conn->prepare($sql_update);
                        $stmt_update->bindParam(":pass", $password_hash, PDO::PARAM_STR);
                        $stmt_update->bindParam(":user_update", $_SESSION['nom_user'], PDO::PARAM_STR);
                        $stmt_update->bindParam(":id", $id_usuario, PDO::PARAM_INT);

                        $resultado_update = $stmt_update->execute();
                        $error_info = $stmt_update->errorInfo();

                        if ($resultado_update && $error_info[0] == '00000') {
                            $_SESSION['success_password'] = "Contraseña actualizada correctamente";
                        } else {
                            $_SESSION['error_password'] = "Error al actualizar la contraseña. Código: " . $error_info[0];
                        }
                    } else {
                        $_SESSION['error_password'] = "La contraseña actual es incorrecta";
                    }
                } else {
                    $_SESSION['error_password'] = "Usuario no encontrado";
                }
            } catch (PDOException $e) {
                $_SESSION['error_password'] = "Error en la base de datos: " . $e->getMessage();
            }
        } else {
            $_SESSION['error_password'] = "Error de conexión a la base de datos";
        }
    }

    // Redirigir para evitar reenvío del formulario
    // (patrón PRG: Post-Redirect-Get)
    header("Location: " . $_SERVER['PHP_SELF']);
    exit();
}

// ══════════════════════════════════════════════════════════
// SECCIÓN 5: PROCESAMIENTO DE ACTUALIZACIÓN DE PERFIL (POST)
// ══════════════════════════════════════════════════════════
// Cuando el usuario envía el formulario de edición de perfil
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['nom_user'])) {
    // Obtener y limpiar los datos del formulario
    $nom_user = trim($_POST["nom_user"] ?? "");
    $mail_user = trim($_POST["mail_user"] ?? "");
    $tel_user = preg_replace('/[^0-9]/', '', $_POST["tel_user"] ?? "");
    $tel_user_int = (int) $tel_user;

    // Validaciones
    if ($nom_user === '' || $mail_user === '' || $tel_user === '') {
        $_SESSION['error_perfil'] = "Todos los campos son obligatorios";
    } elseif (!filter_var($mail_user, FILTER_VALIDATE_EMAIL)) {
        $_SESSION['error_perfil'] = "El formato del email no es válido";
    } else {
        $id_usuario = $_SESSION['id_usuario'];
        $conexion = new CConexion();
        $conn = $conexion->conexionBD();

        if ($conn) {
            try {
                // Verificar que el nombre no esté ya en uso por otro usuario
                $check = $conn->prepare("SELECT id_user FROM tab_users WHERE LOWER(nom_user) = LOWER(:nom) AND id_user != :id");
                $check->execute([':nom' => $nom_user, ':id' => $id_usuario]);
                if ($check->fetchColumn()) {
                    $_SESSION['error_perfil'] = "El nombre de usuario ya está en uso. Elige otro.";
                } else {
                    // Actualizar los datos del perfil en la base de datos
                    // Se registra quién hizo el cambio y la fecha
                    $user_update = $_SESSION['nom_user'];
                    $sql = "UPDATE tab_users 
                            SET nom_user = :nom, 
                                mail_user = :mail, 
                                tel_user = :tel,
                                user_update = :user_update,
                                fec_update = NOW()
                            WHERE id_user = :id";

                    $stmt = $conn->prepare($sql);
                    $stmt->bindParam(":nom", $nom_user, PDO::PARAM_STR);
                    $stmt->bindParam(":mail", $mail_user, PDO::PARAM_STR);
                    $stmt->bindParam(":tel", $tel_user_int, PDO::PARAM_INT);
                    $stmt->bindParam(":user_update", $user_update, PDO::PARAM_STR);
                    $stmt->bindParam(":id", $id_usuario, PDO::PARAM_INT);

                    $resultado = $stmt->execute();
                    $error_info = $stmt->errorInfo();
                    $actualizacion_exitosa = ($resultado && $error_info[0] == '00000');

                    if ($actualizacion_exitosa) {
                        // Actualizar la sesión con los nuevos datos
                        $_SESSION['nom_user'] = $nom_user;
                        $_SESSION['mail_user'] = $mail_user;
                        $_SESSION['tel_user'] = $tel_user;
                        $_SESSION['success_perfil'] = "Perfil actualizado correctamente";
                    } else {
                        $_SESSION['error_perfil'] = "Error al actualizar. Código: " . $error_info[0];
                    }
                }
            } catch (PDOException $e) {
                $_SESSION['error_perfil'] = "Error en la base de datos: " . $e->getMessage();
            }
        } else {
            $_SESSION['error_perfil'] = "Error de conexión a la base de datos";
        }
    }

    // Redirigir para evitar reenvío del formulario (PRG)
    header("Location: " . $_SERVER['PHP_SELF']);
    exit();
}

// ══════════════════════════════════════════════════════════
// SECCIÓN 6: PROCESAMIENTO DE CONFIGURACIÓN GLOBAL (POST)
// ══════════════════════════════════════════════════════════
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['update_params'])) {
    $tema = isset($_POST['tema']) && $_POST['tema'] === 'claro';
    $idioma = $_POST['idioma'] ?? 'ES';

    $db = new CQuerys();
    $res = $db->updateParams($tema, $idioma);

    if ($res) {
        $_SESSION['success_params'] = "Configuración guardada";
    } else {
        $_SESSION['error_params'] = "Error al guardar configuración";
    }

    header("Location: " . $_SERVER['PHP_SELF']);
    exit();
}

// ══════════════════════════════════════════════════════════
// SECCIÓN 6: DATOS PARA LA VISTA (VARIABLES PHP → HTML)
// ══════════════════════════════════════════════════════════
// Estas variables se usan en los modales de footer.php
$nom_user = isset($_SESSION['nom_user']) ? $_SESSION['nom_user'] : 'Usuario';
$mail_user = isset($_SESSION['mail_user']) ? $_SESSION['mail_user'] : '';
$tel_user = isset($_SESSION['tel_user']) ? $_SESSION['tel_user'] : '';
$rol_usuario = isset($_SESSION['id_cliente']) && $_SESSION['id_cliente'] != null ? 'Cliente' : 'Administrador del Sistema';

// Mensajes de retroalimentación para los modales
// (se muestran si hubo éxito o error en operaciones anteriores)
$mensaje_error = isset($_SESSION['error_perfil']) ? $_SESSION['error_perfil'] : '';
$mensaje_success = isset($_SESSION['success_perfil']) ? $_SESSION['success_perfil'] : '';
$mensaje_error_password = isset($_SESSION['error_password']) ? $_SESSION['error_password'] : '';
$mensaje_success_password = isset($_SESSION['success_password']) ? $_SESSION['success_password'] : '';

// ══════════════════════════════════════════════════════════
// SECCIÓN 7: ESTADÍSTICAS DEL DASHBOARD
// ══════════════════════════════════════════════════════════
// Carga los números que se muestran en las tarjetas del panel:
// total de usuarios, productos, ventas, etc.
$stats = [
    'total_usuarios' => 0,
    'usuarios_mes' => 0,
    'empleados' => 0,
    'clientes' => 0,
    'proveedores' => 0,
    'total_productos' => 0,
    'instrumentos' => 0,
    'kits' => 0,
    'mayor_venta' => 'Sin datos',
    'menor_producto' => 'Sin datos',
    'total_ventas' => 0,
    'ventas_diarias' => 0,
    'criticos' => 0,
    'alertas_detalle' => [],
    'ind_tema' => true,
    'ind_idioma' => 'ES'
];

// Conectar a la base de datos para obtener las estadísticas
$conexion = new CConexion();
$conn = $conexion->conexionBD();

if ($conn) {
    try {
        // Usar el método centralizado de la clase CQuerys
        $db = new CQuerys();
        $data = $db->getStats();

        if ($data) {
            $stats['total_usuarios'] = (int) $data['total_usuarios'];
            $stats['usuarios_mes'] = (int) $data['usuarios_mes'];
            $stats['empleados'] = (int) $data['total_admins'];
            $stats['clientes'] = (int) $data['total_clientes'];
            $stats['proveedores'] = (int) ($data['total_proveedores'] ?? 0);

            // Productos
            $stats['total_productos'] = (int) $data['total_productos'];
            $stats['instrumentos'] = (int) $data['total_instrumentos'];
            $stats['kits'] = (int) $data['total_kits'];

            // Mayor Venta
            $stats['mayor_venta'] = ($data['mayor_venta_nombre'] ?? 'Sin datos') . ' (' . ($data['mayor_venta_total'] ?? 0) . ')';

            // Menor Stock
            $stats['menor_producto'] = ($data['menor_stock_nombre'] ?? 'Sin datos') . ' (' . ($data['menor_stock_cant'] ?? 0) . ')';

            // Ventas
            $stats['total_ventas'] = (float) $data['total_ventas'];
            $stats['ventas_diarias'] = (float) $data['ventas_diarias'];

            // Nuevas Métricas
            $stats['criticos'] = (int) ($data['alerta_stock_critico'] ?? 0);

            // Detalle de alertas
            $stats['alertas_detalle'] = $db->getAlertasDetalle();

            // Configuración (Casteo robusto para PostgreSQL)
            $stats['ind_tema'] = ($data['ind_tema'] === true || $data['ind_tema'] === 't' || $data['ind_tema'] === 1 || $data['ind_tema'] === '1');
            $stats['ind_idioma'] = $data['ind_idioma'];
        }
    } catch (Exception $e) {
        error_log("Error en analytics menuPrincipal: " . $e->getMessage());
    }
}

// ══════════════════════════════════════════════════════════
// SECCIÓN 8: CARGA DE DATOS AUXILIARES (LISTAS DESPLEGABLES)
// ══════════════════════════════════════════════════════════
// Estos datos se usan para llenar los selectores (dropdown)
// en los formularios de creación/edición de registros.
// Se pasan a JavaScript a través de la variable 'auxiliares'
// que se inyecta en footer.php.
$auxiliares = [
    'ciudades' => [],
    'documentos' => [],
    'bancos' => [],
    'cargos' => [],
    'sangre' => [],
    'instrumentos' => [],
    'kits' => []
];

if ($conn) {
    try {
        $db = new CQuerys();
        // Mover a uso de la funcion SQL optimizada como solicitaste
        $json_aux = $db->getAuxiliaresJSON();
        $auxDb = json_decode($json_aux, true);
        if (is_array($auxDb)) {
            $auxiliares = array_merge($auxiliares, $auxDb);
        }

        // Instrumentos y Kits no están en fun_obtener_auxiliares, se consultan aquí específicamente para el discriminador
        $stmtInst = $conn->query("SELECT id_instrumento as id, nom_instrumento as label FROM tab_instrumentos ORDER BY nom_instrumento ASC");
        $auxiliares['instrumentos'] = $stmtInst->fetchAll(PDO::FETCH_ASSOC);

        $stmtKits = $conn->query("SELECT id_kit as id, nom_kit as label FROM tab_kits ORDER BY nom_kit ASC");
        $auxiliares['kits'] = $stmtKits->fetchAll(PDO::FETCH_ASSOC);

    } catch (PDOException $e) {
        error_log("Error cargando auxiliares: " . $e->getMessage());
    }
}
?>
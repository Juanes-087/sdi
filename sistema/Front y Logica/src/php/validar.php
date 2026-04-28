<?php
/**
 * ============================================================
 * VALIDACIÓN DE INICIO DE SESIÓN
 * ============================================================
 * 
 * PROPÓSITO:
 * Procesa el formulario de login. Recibe usuario y contraseña,
 * los verifica contra la base de datos, y si son correctos,
 * genera un token JWT que el navegador usará como credencial.
 * 
 * FLUJO:
 * 1. Recibir usuario y contraseña por POST
 * 2. Buscar el usuario en la base de datos
 * 3. Verificar la contraseña (soporta formato moderno y legado)
 * 4. Si es válido → generar JWT y devolverlo
 * 5. Si falla → devolver error genérico (no dice si fue usuario o contraseña)
 * 
 * SEGURIDAD (OWASP A2 - Autenticación):
 * - Mensajes de error genéricos para no dar pistas a atacantes
 * - Migración automática de contraseñas antiguas a hash moderno
 * - Registro de intentos fallidos con IP para auditoría
 * ============================================================
 */
declare(strict_types=1)
;

// ══════════════════════════════════════════════
// BLOQUE 1: CONFIGURACIÓN INICIAL Y SEGURIDAD
// ══════════════════════════════════════════════
// Configura el manejo de errores y las cabeceras de seguridad.
// Los errores se registran en el log del servidor pero nunca
// se muestran al usuario (para no revelar información interna).

error_reporting(E_ALL);
ini_set('display_errors', '0');

// Cabeceras de seguridad OWASP
header("X-Content-Type-Options: nosniff");
header("X-Frame-Options: DENY");
header("X-XSS-Protection: 1; mode=block");
header("Referrer-Policy: strict-origin-when-cross-origin");
header("Content-Security-Policy: default-src 'self'");

// La respuesta siempre será en formato JSON
header("Content-Type: application/json; charset=UTF-8");

// Función auxiliar para enviar errores con formato consistente
function enviarError($codigo, $mensaje, $debug = null)
{
    http_response_code($codigo);
    $respuesta = ["success" => false, "error" => $mensaje];
    if ($debug !== null && ini_get('display_errors')) {
        $respuesta["debug"] = $debug;
    }
    echo json_encode($respuesta);
    exit;
}

// ══════════════════════════════════════════════
// BLOQUE 2: CARGAR DEPENDENCIAS
// ══════════════════════════════════════════════
// Incluye la conexión a la base de datos y las funciones JWT.
// Si alguno falla, devuelve error 500 sin revelar detalles.

try {
    include_once "conexion.php";
    include_once "jwt.php";
} catch (Throwable $e) {
    error_log("Error al incluir archivos: " . $e->getMessage());
    enviarError(500, "Error de configuración del servidor");
}

// ══════════════════════════════════════════════
// BLOQUE 3: VERIFICAR MÉTODO HTTP
// ══════════════════════════════════════════════
// Solo acepta peticiones POST (las que envía el formulario).
// Cualquier otro método (GET, PUT, etc.) se rechaza.

if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    http_response_code(405);
    echo json_encode(["success" => false, "error" => "Método no permitido"]);
    exit;
}

// ══════════════════════════════════════════════
// BLOQUE 4: RECIBIR Y VALIDAR DATOS DE ENTRADA
// ══════════════════════════════════════════════
// Toma el usuario y contraseña del formulario.
// Si alguno está vacío, rechaza la petición.

$usuario = trim($_POST["usuario"] ?? '');
$password = trim($_POST["password"] ?? '');

if ($usuario === '' || $password === '') {
    http_response_code(400);
    echo json_encode(["success" => false, "error" => "Datos incompletos"]);
    exit;
}

// ══════════════════════════════════════════════
// BLOQUE 5: CONECTAR A LA BASE DE DATOS
// ══════════════════════════════════════════════

try {
    $conexion = new CConexion();
    $conn = $conexion->conexionBD();

    if (!$conn) {
        error_log("Error: conexionBD() retornó null - Revisa los logs de PHP para más detalles");
        if (!extension_loaded('pdo_pgsql')) {
            enviarError(500, "La extensión PDO_PGSQL no está habilitada en PHP");
        } else {
            enviarError(500, "Error de conexión a la base de datos. Verifique que PostgreSQL esté corriendo y las credenciales sean correctas.");
        }
    }
} catch (Throwable $e) {
    error_log("Error al crear conexión: " . $e->getMessage());
    error_log("Stack trace: " . $e->getTraceAsString());
    enviarError(500, "Error al establecer conexión con la base de datos");
}

try {

    // ══════════════════════════════════════════════
    // BLOQUE 6: BUSCAR USUARIO EN LA BASE DE DATOS
    // ══════════════════════════════════════════════
    // Busca al usuario por nombre y trae su contraseña cifrada
    // y el tipo de menú asignado (1=administrador, 2=cliente).
    // Usa consulta preparada para prevenir inyección SQL.

    $sql = "
        SELECT 
            u.id_user,
            u.nom_user,
            u.pass_user,
            um.id_menu
        FROM tab_users u
        INNER JOIN tab_users_menu um ON um.id_user = u.id_user
        WHERE u.nom_user = :usuario
        LIMIT 1
    ";

    $stmt = $conn->prepare($sql);
    $stmt->execute([":usuario" => $usuario]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        throw new Exception("Credenciales inválidas");
    }

    $user["id_menu"] = (int) $user["id_menu"];

    if (!in_array($user["id_menu"], [1, 2], true)) {
        throw new Exception("Menú inválido");
    }

    // ══════════════════════════════════════════════
    // BLOQUE 7: VERIFICAR CONTRASEÑA
    // ══════════════════════════════════════════════
    // Soporta dos escenarios:
    // A) Contraseña con hash moderno → usa password_verify()
    // B) Contraseña en texto plano (legado) → compara directamente
    //    y la actualiza al formato moderno automáticamente
    //    para mejorar la seguridad a futuro.

    $hashGuardado = $user["pass_user"];
    $loginValido = false;

    // Caso A: Hash moderno
    if (password_get_info($hashGuardado)['algo'] !== null) {
        if (password_verify($password, $hashGuardado)) {
            $loginValido = true;
        }
    }
    // Caso B: Contraseña legada (texto plano)
    else {
        if (hash_equals((string) $hashGuardado, (string) $password)) {
            $loginValido = true;

            // Migrar automáticamente a hash moderno
            $nuevoHash = password_hash($password, PASSWORD_DEFAULT);
            $upd = $conn->prepare("
                UPDATE tab_users 
                SET pass_user = :hash 
                WHERE id_user = :id
            ");
            $upd->execute([
                ':hash' => $nuevoHash,
                ':id' => $user["id_user"]
            ]);
        }
    }

    if (!$loginValido) {
        throw new Exception("Credenciales inválidas");
    }

    // ══════════════════════════════════════════════
    // BLOQUE 8: GENERAR TOKEN JWT Y RESPONDER
    // ══════════════════════════════════════════════
    // Lee el tiempo de inactividad (ind_idle) desde tab_parametros
    // y lo usa como expiración del token. Se guarda en sesión
    // para que security_headers.php no tenga que consultar la BD.

    // Consulta directa (validar.php usa $conn PDO, no CQuerys)
    $stmtIdle = $conn->query("SELECT ind_idle FROM tab_parametros LIMIT 1");
    $rowIdle = $stmtIdle->fetch(PDO::FETCH_ASSOC);
    $idleMinutos = $rowIdle ? (int) $rowIdle['ind_idle'] : 30;

    // Guardar en sesión para security_headers.php
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    $_SESSION['ind_idle'] = $idleMinutos;

    $payload = [
        "id" => (int) $user["id_user"],
        "usuario" => $user["nom_user"],
        "menu" => $user["id_menu"],
        "iat" => time(),
        "exp" => time() + ($idleMinutos * 60) // Configurable desde tab_parametros
    ];

    $token = generarJWT($payload);

    http_response_code(200);
    echo json_encode([
        "success" => true,
        "token" => $token,
        "id_menu" => $user["id_menu"]
    ]);
    exit;

} catch (PDOException $e) {
    error_log("Error de base de datos: " . $e->getMessage());
    enviarError(500, "Error al consultar la base de datos");
} catch (Throwable $e) {
    // Registra el intento fallido con la IP para auditoría de seguridad
    error_log("Login fallido: {$usuario} IP: {$_SERVER['REMOTE_ADDR']} - Error: " . $e->getMessage());
    http_response_code(401);
    echo json_encode([
        "success" => false,
        "error" => "Usuario o contraseña incorrectos"
    ]);
    exit;
}

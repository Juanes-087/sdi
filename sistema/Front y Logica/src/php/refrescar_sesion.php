<?php
/**
 * ============================================================
 * REFRESCAR SESIÓN POR ACTIVIDAD
 * ============================================================
 * 
 * PROPÓSITO:
 * Extiende la vida del token JWT y la sesión PHP si se detecta
 * actividad del usuario en el navegador (movimiento mouse, etc).
 * 
 * FLUJO:
 * 1. Recibir token actual.
 * 2. Validar que sea legítimo.
 * 3. Actualizar el tiempo de última actividad.
 * 4. Generar un nuevo token con expiración extendida.
 * ============================================================
 */

declare(strict_types=1);

error_reporting(E_ALL);
ini_set('display_errors', '0');

header("Content-Type: application/json; charset=UTF-8");

try {
    include_once "conexion.php";
    include_once "jwt.php";

    // 1. Obtener el token del encabezado Authorization o del cuerpo
    $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    $token = '';
    if (preg_match('/Bearer\s+(.*)$/i', $authHeader, $matches)) {
        $token = $matches[1];
    } else {
        $data = json_decode(file_get_contents("php://input"), true);
        $token = $data['token'] ?? '';
    }

    if (empty($token)) {
        throw new Exception("Token no proporcionado", 401);
    }

    // 2. Validar el token actual
    $payload = validarJWT($token);
    if (!$payload) {
        throw new Exception("Sesión inválida o expirada", 401);
    }

    // 3. Conectar a BD para obtener configuraciones
    $conexion = new CConexion();
    $conn = $conexion->conexionBD();
    if (!$conn) {
        throw new Exception("Error de conexión", 500);
    }

    // Obtener tiempo de inactividad configurado
    $stmtIdle = $conn->query("SELECT ind_idle FROM tab_parametros LIMIT 1");
    $rowIdle = $stmtIdle->fetch(PDO::FETCH_ASSOC);
    $idleMinutos = $rowIdle ? (int) $rowIdle['ind_idle'] : 30;

    // 4. Iniciar sesión PHP y actualizar actividad
    if (session_status() === PHP_SESSION_NONE) {
        session_start();
    }
    $_SESSION['last_activity'] = time();
    $_SESSION['ind_idle'] = $idleMinutos;
    $_SESSION['id_usuario'] = $payload['id']; // Asegurar que la sesión PHP esté sincronizada

    // 5. Generar nuevo payload con expiración extendida
    $newPayload = $payload;
    $newPayload['iat'] = time();
    $newPayload['exp'] = time() + ($idleMinutos * 60);

    $newToken = generarJWT($newPayload);

    echo json_encode([
        "success" => true,
        "token" => $newToken,
        "exp" => $newPayload['exp']
    ]);

} catch (Throwable $e) {
    http_response_code($e->getCode() ?: 500);
    echo json_encode([
        "success" => false,
        "error" => $e->getMessage()
    ]);
}

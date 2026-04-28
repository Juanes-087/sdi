<?php
/**
 * ============================================================
 * CIERRE DE SESIÓN (LOGOUT)
 * ============================================================
 * 
 * PROPÓSITO:
 * Destruye completamente la sesión del usuario cuando
 * hace clic en "Cerrar sesión". Borra todos los datos
 * de la sesión, elimina las cookies, y redirige al inicio.
 * 
 * ¿POR QUÉ ES TAN EXHAUSTIVO?
 * Un logout incompleto podría permitir que alguien reutilice
 * la sesión de otro usuario. Por eso se realizan 5 pasos
 * de limpieza para garantizar que no quede ningún rastro.
 * 
 * SEGURIDAD (OWASP A7 - Autenticación):
 * - Destrucción completa en 5 pasos
 * - Registro de auditoría del cierre de sesión
 * ============================================================
 */

declare(strict_types=1);

// ══════════════════════════════════════════════
// BLOQUE 1: CABECERAS DE SEGURIDAD
// ══════════════════════════════════════════════
header("X-Content-Type-Options: nosniff");
header("X-Frame-Options: DENY");
header("X-XSS-Protection: 1; mode=block");
header("Referrer-Policy: strict-origin-when-cross-origin");
header("Permissions-Policy: geolocation=(), microphone=(), camera=()");

// Desactivar caché para que no se pueda volver a la página anterior
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0, private");
header("Pragma: no-cache");
header("Expires: Thu, 01 Jan 1970 00:00:00 GMT");

// ══════════════════════════════════════════════
// BLOQUE 2: VERIFICAR MÉTODO HTTP
// ══════════════════════════════════════════════
// Acepta POST (desde JavaScript) o GET (desde un enlace directo)
if ($_SERVER["REQUEST_METHOD"] !== "POST" && $_SERVER["REQUEST_METHOD"] !== "GET") {
    http_response_code(405);
    header("Content-Type: application/json");
    echo json_encode(["success" => false, "error" => "Método no permitido"]);
    exit();
}

session_start();

// ══════════════════════════════════════════════
// BLOQUE 3: REGISTRO DE AUDITORÍA
// ══════════════════════════════════════════════
// Antes de destruir todo, registra quién cerró sesión,
// desde qué IP y con qué navegador. Útil para auditorías.
$user_id = $_SESSION['id_usuario'] ?? 'unknown';
$username = $_SESSION['nom_user'] ?? 'unknown';
$ip_address = $_SERVER['REMOTE_ADDR'] ?? 'unknown';
$user_agent = $_SERVER['HTTP_USER_AGENT'] ?? 'unknown';

error_log(sprintf(
    "[LOGOUT] Usuario: %s (ID: %s) desde IP: %s - User-Agent: %s",
    $username,
    $user_id,
    $ip_address,
    $user_agent
));

// ══════════════════════════════════════════════
// BLOQUE 4: DESTRUCCIÓN COMPLETA DE SESIÓN (5 PASOS)
// ══════════════════════════════════════════════

// Paso 1: Vaciar todas las variables de sesión
$_SESSION = [];

// Paso 2: Eliminar la cookie de sesión del navegador
if (ini_get("session.use_cookies")) {
    $params = session_get_cookie_params();
    setcookie(
        session_name(),
        '',
        time() - 42000,
        $params["path"],
        $params["domain"],
        $params["secure"],
        $params["httponly"]
    );
}

// Paso 3: Destruir la sesión en el servidor
session_destroy();

// Paso 4: Iniciar nueva sesión con un ID diferente
// (previene que alguien reutilice el ID de sesión anterior)
session_start();
session_regenerate_id(true);
$_SESSION = [];

// Paso 5: Limpiar TODAS las cookies del sitio
if (isset($_COOKIE)) {
    foreach ($_COOKIE as $key => $value) {
        setcookie($key, '', time() - 3600, '/');
        setcookie($key, '', time() - 3600, '/', '', true, true);
    }
}

// ══════════════════════════════════════════════
// BLOQUE 5: RESPONDER AL NAVEGADOR
// ══════════════════════════════════════════════
header("Content-Type: application/json; charset=UTF-8");

// Si fue una llamada desde JavaScript, devolver JSON
if (!empty($_SERVER['HTTP_X_REQUESTED_WITH']) && strtolower($_SERVER['HTTP_X_REQUESTED_WITH']) == 'xmlhttprequest') {
    echo json_encode([
        "success" => true,
        "message" => "Sesión cerrada exitosamente",
        "timestamp" => time(),
        "redirect" => "../../index.html"
    ]);
    exit();
}

// Si fue un acceso directo (enlace), redirigir a la página principal
// Ajustado para que funcione correctamente cuando se llama desde /html/logout.php
header("Location: ../index.html");
exit();


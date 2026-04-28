<?php
/**
 * ============================================================
 * GUARDIA DE SEGURIDAD DEL SISTEMA
 * ============================================================
 * 
 * PROPÓSITO:
 * Este archivo se incluye al inicio de TODAS las páginas protegidas.
 * Configura las cabeceras de seguridad HTTP, inicia la sesión de
 * forma segura, y provee funciones para validar usuarios.
 * 
 * ESTÁNDARES APLICADOS:
 * - OWASP A5:2021 → Configuración de seguridad (headers)
 * - OWASP A7:2021 → Gestión segura de sesiones
 * - OWASP A3:2021 → Prevención de inyección (XSS)
 * ============================================================
 */

declare(strict_types=1);

// ══════════════════════════════════════════════
// BLOQUE 1: CABECERAS DE SEGURIDAD HTTP
// ══════════════════════════════════════════════
// Estas instrucciones le dicen al navegador cómo debe comportarse
// para proteger al usuario contra ataques comunes.

// Evita que el navegador intente adivinar el tipo de archivo
// (previene que un archivo malicioso se ejecute como script)
header("X-Content-Type-Options: nosniff");

// Impide que la página se cargue dentro de un iframe de otro sitio
// (protege contra ataques de clickjacking)
header("X-Frame-Options: DENY");

// Activa el filtro anti-XSS del navegador (para navegadores antiguos)
header("X-XSS-Protection: 1; mode=block");

// Controla qué información de la URL se envía cuando el usuario
// navega a otro sitio (protege la privacidad)
header("Referrer-Policy: strict-origin-when-cross-origin");

// Desactiva el acceso a la cámara, micrófono y ubicación
// (el sistema no necesita estos permisos)
header("Permissions-Policy: geolocation=(), microphone=(), camera=()");

// Política de seguridad de contenido (CSP):
// Define exactamente de dónde puede cargar recursos la página
// (scripts, estilos, imágenes, fuentes). Bloquea contenido de
// fuentes no autorizadas para prevenir inyección de código malicioso.
header("Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://kit.fontawesome.com https://cdn.jsdelivr.net https://cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' https://kit.fontawesome.com https://cdn.jsdelivr.net https://ka-f.fontawesome.com https://fonts.googleapis.com https://cdnjs.cloudflare.com; img-src 'self' data: blob: *; font-src 'self' https://kit.fontawesome.com https://ka-f.fontawesome.com https://fonts.gstatic.com https://cdnjs.cloudflare.com; connect-src 'self' https://ka-f.fontawesome.com;");

// Desactiva el caché para páginas sensibles:
// Si alguien cierra sesión, el navegador no mostrará la página
// anterior al presionar "atrás".
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0, private");
header("Pragma: no-cache");
header("Expires: Thu, 01 Jan 1970 00:00:00 GMT");

// ══════════════════════════════════════════════
// BLOQUE 2: CONFIGURACIÓN SEGURA DE SESIÓN
// ══════════════════════════════════════════════
// Configura las cookies de sesión para que sean lo más seguras posible
// y regenera el identificador de sesión cada 30 minutos para evitar
// que alguien robe la sesión de otro usuario.

if (session_status() === PHP_SESSION_NONE) {
    // Las cookies de sesión solo son accesibles por HTTP (no por JavaScript)
    ini_set('session.cookie_httponly', '1');
    // En producción con HTTPS, cambiar a '1' para mayor seguridad
    ini_set('session.cookie_secure', '0');
    // La cookie solo se envía en peticiones al mismo sitio
    ini_set('session.cookie_samesite', 'Strict');
    // Solo acepta IDs de sesión generados por el servidor
    ini_set('session.use_strict_mode', '1');
    // La sesión expira después de 1 hora de inactividad
    ini_set('session.cookie_lifetime', '3600');

    session_start();

    // Se regenera el ID de sesión según el tiempo de inactividad configurado
    // (ind_idle se guarda en sesión al hacer login en validar.php)
    $idleSeconds = (isset($_SESSION['ind_idle']) ? (int) $_SESSION['ind_idle'] : 30) * 60;

    if (!isset($_SESSION['created'])) {
        $_SESSION['created'] = time();
    } else if (time() - $_SESSION['created'] > $idleSeconds) {
        session_regenerate_id(true);
        $_SESSION['created'] = time();
    }
}

// ══════════════════════════════════════════════
// BLOQUE 3: FUNCIÓN PARA VALIDAR SESIÓN
// ══════════════════════════════════════════════
// Verifica si hay un usuario activo en la sesión actual.
// Revisa: que exista un ID de usuario, que sea numérico,
// y que no haya pasado más de 1 hora desde la última actividad.

function validarSesion(): bool
{
    if (!isset($_SESSION['id_usuario']) || empty($_SESSION['id_usuario'])) {
        return false;
    }

    if (!is_numeric($_SESSION['id_usuario'])) {
        return false;
    }

    // Si la sesión ha superado el tiempo de inactividad configurado, expiró
    $sessionIdleSeconds = (isset($_SESSION['ind_idle']) ? (int) $_SESSION['ind_idle'] : 30) * 60;
    if (isset($_SESSION['last_activity']) && (time() - $_SESSION['last_activity'] > $sessionIdleSeconds)) {
        return false;
    }

    // Actualizar el contador de actividad
    $_SESSION['last_activity'] = time();

    return true;
}

// ══════════════════════════════════════════════
// BLOQUE 4: FUNCIÓN PARA EXIGIR AUTENTICACIÓN
// ══════════════════════════════════════════════
// Si el usuario no tiene una sesión válida, limpia todo
// y lo manda a la pantalla de inicio de sesión.

function requerirAutenticacion(): void
{
    if (!validarSesion()) {
        $_SESSION = [];
        session_destroy();

        header("Location: ../../html/InicioSesion.html");
        exit();
    }
}

// ══════════════════════════════════════════════
// BLOQUE 5: FUNCIÓN PARA LIMPIAR TEXTO (Anti-XSS)
// ══════════════════════════════════════════════
// Antes de mostrar cualquier texto que vino del usuario
// en la página, esta función convierte caracteres especiales
// (<, >, ", etc.) en sus equivalentes seguros para que no
// se ejecuten como código HTML o JavaScript.

function h(string $string): string
{
    return htmlspecialchars($string, ENT_QUOTES | ENT_HTML5, 'UTF-8');
}

// ══════════════════════════════════════════════
// BLOQUE 6: FUNCIONES DE PROTECCIÓN CSRF
// ══════════════════════════════════════════════
// CSRF = Cross-Site Request Forgery
// Genera un código único por sesión que se incluye en cada
// formulario. Al enviar el formulario, se verifica que el código
// coincida. Esto impide que un sitio externo envíe formularios
// haciéndose pasar por el usuario.

function generarCSRFToken(): string
{
    if (!isset($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function validarCSRFToken(string $token): bool
{
    return isset($_SESSION['csrf_token']) && hash_equals($_SESSION['csrf_token'], $token);
}


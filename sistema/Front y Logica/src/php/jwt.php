<?php
/**
 * ============================================================
 * MANEJO DE TOKENS JWT (JSON Web Token)
 * ============================================================
 * 
 * PROPÓSITO:
 * Este archivo maneja los "pases de seguridad" del sistema.
 * Cuando un usuario inicia sesión correctamente, se le genera
 * un token JWT que funciona como credencial temporal.
 * Cada vez que el usuario hace una petición al servidor,
 * el token se valida para verificar que sea legítimo.
 * 
 * ¿CÓMO FUNCIONA UN JWT?
 * Un JWT tiene 3 partes separadas por puntos:
 *   1. Header  → Dice qué algoritmo se usó para firmarlo
 *   2. Payload → Contiene los datos del usuario (ID, nombre, menú)
 *   3. Firma   → Código generado con una clave secreta que impide falsificación
 * 
 * SEGURIDAD (OWASP A2 - Autenticación):
 * - Usa HMAC-SHA256 para la firma (estándar de la industria).
 * - Los tokens expiran después de 30 minutos.
 * - La clave secreta se lee del archivo .env.
 * ============================================================
 */

declare(strict_types=1)
;

require_once __DIR__ . '/load_env.php';

// ── Clave secreta para firmar los tokens ──
// Se lee del archivo .env. Si no existe, usa un valor por defecto
// (solo para desarrollo; en producción DEBE configurarse).
define('JWT_SECRET', getenv('JWT_SECRET') ?: 'clave-por-defecto-cambiar-en-produccion');

// ── Algoritmo de cifrado utilizado ──
const JWT_ALG = 'HS256';

/**
 * ── GENERAR UN TOKEN JWT ──
 * 
 * Recibe los datos del usuario (payload), los combina con
 * un encabezado estándar, y los firma con la clave secreta.
 * Devuelve una cadena de texto (el token) que el navegador guardará.
 */
function generarJWT(array $payload): string
{
    $header = [
        'alg' => JWT_ALG,
        'typ' => 'JWT'
    ];

    // Codificar las dos primeras partes del token
    $base64Header = base64url_encode(json_encode($header));
    $base64Payload = base64url_encode(json_encode($payload));

    // Generar la firma usando la clave secreta
    $signature = hash_hmac(
        'sha256',
        $base64Header . '.' . $base64Payload,
        JWT_SECRET,
        true
    );

    $base64Signature = base64url_encode($signature);

    // Unir las 3 partes: header.payload.firma
    return $base64Header . '.' . $base64Payload . '.' . $base64Signature;
}

/**
 * ── VALIDAR UN TOKEN JWT ──
 * 
 * Recibe un token, lo descompone en sus 3 partes,
 * recalcula la firma y la compara con la que trae el token.
 * Si coinciden, el token es legítimo y no fue alterado.
 * También revisa si el token ya expiró.
 * 
 * Devuelve los datos del usuario si es válido, o null si no lo es.
 */
function validarJWT(string $jwt): ?array
{
    // Separar las 3 partes del token
    $partes = explode('.', $jwt);
    if (count($partes) !== 3) {
        return null;
    }

    [$header64, $payload64, $signature64] = $partes;

    // Recalcular la firma con la clave secreta
    $firmaVerificada = base64url_encode(
        hash_hmac(
            'sha256',
            $header64 . '.' . $payload64,
            JWT_SECRET,
            true
        )
    );

    // Comparar la firma recalculada con la que trae el token
    if (!hash_equals($firmaVerificada, $signature64)) {
        return null;
    }

    // Decodificar los datos del usuario
    $payload = json_decode(base64url_decode($payload64), true);

    if (!$payload) {
        return null;
    }

    // Verificar si el token ya expiró
    if (isset($payload['exp']) && time() > $payload['exp']) {
        return null;
    }

    return $payload;
}

/**
 * ── FUNCIONES AUXILIARES ──
 * Codifican/decodifican datos en formato seguro para URLs
 * (variante de Base64 que no usa caracteres problemáticos en URLs).
 */
function base64url_encode(string $data): string
{
    return rtrim(strtr(base64_encode($data), '+/', '-_'), '=');
}

function base64url_decode(string $data): string
{
    return base64_decode(strtr($data, '-_', '+/'));
}

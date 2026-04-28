<?php
/**
 * ============================================================
 * CARGADOR DE VARIABLES DE ENTORNO (.env)
 * ============================================================
 * 
 * PROPÓSITO:
 * Lee el archivo .env que contiene las credenciales secretas
 * del proyecto (contraseñas de base de datos, claves JWT, etc.)
 * y las hace disponibles para todos los demás archivos PHP.
 * 
 * ¿POR QUÉ EXISTE?
 * Para que las contraseñas no estén escritas directamente 
 * en el código fuente. Si necesitamos cambiar una credencial,
 * solo editamos el archivo .env sin tocar ningún archivo PHP.
 * 
 * SEGURIDAD (OWASP A5 - Configuración de Seguridad):
 * El archivo .env NUNCA debe subirse al repositorio.
 * ============================================================
 */
declare(strict_types=1);

(function (): void{

    // ── BLOQUE 1: Localizar el archivo .env ──
    // Busca el archivo .env en la carpeta padre del directorio actual (raíz del proyecto).
    // Si no existe o no se puede leer, simplemente sale sin error.
    $envPath = dirname(__DIR__) . '/.env';

    if (!file_exists($envPath) || !is_readable($envPath)) {
        return;
    }

    // ── BLOQUE 2: Leer el archivo línea por línea ──
    // Lee todas las líneas del archivo, ignorando las vacías.
    $lines = file($envPath, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    if ($lines === false) {
        return;
    }

    // ── BLOQUE 3: Procesar cada variable ──
    // Cada línea tiene el formato CLAVE=VALOR (ej: DB_HOST=localhost).
    // Ignora las líneas que empiezan con # (comentarios).
    // Si el valor tiene comillas, las quita.
    // Registra cada variable en 3 lugares: putenv(), $_ENV y $_SERVER
    // para que esté disponible sin importar cómo se consulte.
    foreach ($lines as $line) {
        $line = trim($line);
        // Ignorar comentarios
        if ($line === '' || strpos($line, '#') === 0) {
            continue;
        }
        // Parsear KEY=VALUE
        if (strpos($line, '=') !== false) {
            [$key, $value] = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value);
            // Quitar comillas si las tiene
            $len = strlen($value);
            if (
                $len >= 2 &&
                ((substr($value, 0, 1) === '"' && substr($value, -1) === '"') ||
                    (substr($value, 0, 1) === "'" && substr($value, -1) === "'"))
            ) {
                $value = substr($value, 1, -1);
            }
            if ($key !== '') {
                putenv("$key=$value");
                $_ENV[$key] = $value;
                $_SERVER[$key] = $value;
            }
        }
    }
})();

<?php
/**
 * ============================================================
 * RATE LIMITER - Control de Tasa de Intentos Persistente
 * ============================================================
 * 
 * Permite limitar la frecuencia de peticiones e intentos por IP o Clave
 * almacenando el estado en el sistema de archivos temporal con bloqueo seguro,
 * evitando que la eliminación de cookies/sesiones burle la protección.
 * ============================================================
 */

declare(strict_types=1);

class RateLimiter
{
    private static function getStorageDir(): string
    {
        $dir = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'sid_rate_limits';
        if (!is_dir($dir)) {
            @mkdir($dir, 0700, true);
        }
        return $dir;
    }

    private static function getFilePath(string $key): string
    {
        $safeKey = preg_replace('/[^a-zA-Z0-9_-]/', '_', $key);
        return self::getStorageDir() . DIRECTORY_SEPARATOR . 'rl_' . hash('sha256', $safeKey) . '.json';
    }

    /**
     * Verifica si se ha alcanzado el límite de intentos.
     * 
     * @param string $key Clave única (ej: login_ip_127.0.0.1 o recup_user_12)
     * @param int $maxAttempts Número máximo de intentos permitidos
     * @param int $decaySeconds Segundos que dura la ventana de bloqueo/evaluación
     * @return array ['allowed' => bool, 'attempts' => int, 'remaining_seconds' => int]
     */
    public static function check(string $key, int $maxAttempts, int $decaySeconds): array
    {
        $file = self::getFilePath($key);
        if (!file_exists($file)) {
            return [
                'allowed' => true,
                'attempts' => 0,
                'remaining_seconds' => 0
            ];
        }

        $fp = @fopen($file, 'c+');
        if (!$fp) {
            return ['allowed' => true, 'attempts' => 0, 'remaining_seconds' => 0];
        }

        flock($fp, LOCK_SH);
        $contents = stream_get_contents($fp);
        flock($fp, LOCK_UN);
        fclose($fp);

        $data = json_decode($contents ?: '', true);
        if (!$data || !isset($data['first_attempt']) || !isset($data['count'])) {
            return ['allowed' => true, 'attempts' => 0, 'remaining_seconds' => 0];
        }

        $now = time();
        $elapsed = $now - $data['first_attempt'];

        // Si ya expiró la ventana, se considera libre
        if ($elapsed > $decaySeconds) {
            @unlink($file);
            return ['allowed' => true, 'attempts' => 0, 'remaining_seconds' => 0];
        }

        $attempts = (int)$data['count'];
        $remaining = max(0, $decaySeconds - $elapsed);
        $allowed = $attempts < $maxAttempts;

        return [
            'allowed' => $allowed,
            'attempts' => $attempts,
            'remaining_seconds' => $remaining
        ];
    }

    /**
     * Registra un nuevo intento fallido o consumo de token.
     */
    public static function hit(string $key, int $decaySeconds): int
    {
        $file = self::getFilePath($key);
        $fp = @fopen($file, 'c+');
        if (!$fp) {
            return 1;
        }

        flock($fp, LOCK_EX);
        $contents = stream_get_contents($fp);
        $data = json_decode($contents ?: '', true);
        $now = time();

        if (!$data || !isset($data['first_attempt']) || ($now - $data['first_attempt']) > $decaySeconds) {
            $data = [
                'first_attempt' => $now,
                'count' => 1
            ];
        } else {
            $data['count'] = ((int)($data['count'] ?? 0)) + 1;
        }

        ftruncate($fp, 0);
        rewind($fp);
        fwrite($fp, json_encode($data));
        fflush($fp);
        flock($fp, LOCK_UN);
        fclose($fp);

        return $data['count'];
    }

    /**
     * Limpia los intentos registrados para la clave especificada.
     */
    public static function clear(string $key): void
    {
        $file = self::getFilePath($key);
        if (file_exists($file)) {
            @unlink($file);
        }
    }
}

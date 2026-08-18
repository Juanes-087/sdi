<?php
/**
 * ============================================================
 * CONEXIÓN A LA BASE DE DATOS (PostgreSQL)
 * ============================================================
 * 
 * PROPÓSITO:
 * Establece la conexión con la base de datos PostgreSQL 
 * usando las credenciales leídas del archivo .env.
 * Todos los demás archivos PHP que necesiten acceder a la 
 * base de datos usan esta clase como punto de entrada único.
 * 
 * SEGURIDAD (OWASP A3 - Inyección):
 * Usa PDO (PHP Data Objects) que permite consultas preparadas,
 * protegiendo contra inyección SQL.
 * ============================================================
 */
require_once __DIR__ . '/load_env.php';

class CConexion
{
    private static $instance = null;

    /**
     * Devuelve la instancia única (Singleton) de la conexión PDO.
     */
    public static function getInstance()
    {
        if (self::$instance === null) {
            $connObj = new self();
            self::$instance = $connObj->createConnection();
        }
        return self::$instance;
    }

    /**
     * Verifica si el modo DEBUG está activado en las variables de entorno (.env).
     * Soporta APP_DEBUG=true / APP_DEBUG=1 o APP_ENV=desarrollo
     */
    public static function isDebugEnabled(): bool
    {
        $debug = strtolower((string)(getenv('APP_DEBUG') ?: ''));
        $env = strtolower((string)(getenv('APP_ENV') ?: ''));
        return in_array($debug, ['true', '1', 'yes', 'on'], true) || in_array($env, ['desarrollo', 'development', 'debug', 'local'], true);
    }

    /**
     * Método público retrocompatible. Reutiliza la conexión singleton.
     */
    public function conexionBD()
    {
        return self::getInstance();
    }

    /**
     * Crea y devuelve la conexión PDO a PostgreSQL leyendo el .env.
     */
    private function createConnection()
    {
        // ── Leer credenciales desde variables de entorno ──
        $host = getenv('DB_HOST');
        $dbname = getenv('DB_NAME');
        $username = getenv('DB_USER');
        $password = getenv('DB_PASSWORD');
        $port = getenv('DB_PORT') ?: '5432';

        // ── Verificar que las credenciales estén configuradas ──
        if (empty($host) || empty($dbname) || empty($username)) {
            error_log("ERROR: Variables de BD no configuradas (DB_HOST, DB_NAME, DB_USER). Revisa el archivo .env");
            return null;
        }
        if ($password === false) {
            $password = '';
        }

        // ── Verificar que PHP tenga el driver de PostgreSQL ──
        if (!extension_loaded('pdo_pgsql')) {
            error_log("ERROR: La extensión PDO_PGSQL no está habilitada en PHP");
            return null;
        }

        try {
            // ── Intentar la conexión a PostgreSQL ──
            $dsn = "pgsql:host=$host;port=$port;dbname=$dbname";
            $conn = new PDO($dsn, $username, $password);
            $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            error_log("Conexión exitosa a PostgreSQL");
            return $conn;
        } catch (PDOException $exp) {
            error_log("Error de conexión PostgreSQL: " . $exp->getMessage());
            return null;
        }
    }
}

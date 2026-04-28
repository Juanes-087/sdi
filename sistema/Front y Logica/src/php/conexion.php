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
    /**
     * Crea y devuelve la conexión a la base de datos.
     * 
     * Lee las credenciales desde las variables de entorno (archivo .env),
     * verifica que estén completas, comprueba que PHP tenga el driver 
     * de PostgreSQL habilitado, y si todo está bien, abre la conexión.
     * 
     * Si algo falla (credenciales vacías, driver faltante, BD apagada),
     * registra el error en el log del servidor y devuelve null.
     */
    public function conexionBD()
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
            // Se arma la cadena de conexión (DSN) y se abre la conexión con PDO.
            // Se configura para que lance excepciones si hay error en las consultas.
            $dsn = "pgsql:host=$host;port=$port;dbname=$dbname";
            $conn = new PDO($dsn, $username, $password);
            $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            error_log("Conexión exitosa a PostgreSQL");
        } catch (PDOException $exp) {
            error_log("Error de conexión PostgreSQL: " . $exp->getMessage());
            return null;
        }

        return $conn;
    }
}

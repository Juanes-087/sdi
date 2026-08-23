<?php
/**
 * ============================================================
 * SMTP MAILER - Envío de emails via SMTP (Sin dependencias)
 * ============================================================
 * 
 * Clase liviana que envía correos electrónicos usando sockets
 * nativos de PHP (fsockopen). No requiere Composer, PHPMailer
 * ni ninguna dependencia externa.
 * 
 * Soporta: STARTTLS, AUTH LOGIN, emails HTML.
 * Configurado para Gmail / Yahoo / Outlook.
 * ============================================================
 */
declare(strict_types=1);

class SmtpMailer
{
    private string $host;
    private int $port;
    private string $user;
    private string $pass;
    private string $fromName;
    private $socket;
    private string $lastError = '';

    public function __construct()
    {
        // Cargar variables de entorno
        require_once __DIR__ . '/load_env.php';

        $this->host     = getenv('SMTP_HOST') ?: 'smtp.gmail.com';
        $this->port     = (int)(getenv('SMTP_PORT') ?: 587);
        $this->user     = getenv('SMTP_USER') ?: '';
        $this->pass     = getenv('SMTP_PASS') ?: '';
        $this->fromName = getenv('SMTP_FROM_NAME') ?: 'SPECIALIZED';
    }

    /**
     * Enviar un email HTML
     * 
     * @param string $to      Dirección del destinatario
     * @param string $subject Asunto del email
     * @param string $body    Contenido HTML del email
     * @return bool           true si se envió correctamente
     */
    public function send(string $to, string $subject, string $body): bool
    {
        try {
            // Validar que las credenciales SMTP no estén vacías
            if (empty($this->user) || empty($this->pass)) {
                $this->lastError = "Credenciales SMTP no configuradas. Verifica SMTP_USER y SMTP_PASS en el archivo .env";
                return false;
            }

            // 1. Conectar al servidor SMTP
            $context = stream_context_create([
                'ssl' => [
                    'verify_peer' => false,
                    'verify_peer_name' => false,
                    'allow_self_signed' => true
                ]
            ]);

            $this->socket = @stream_socket_client(
                "tcp://{$this->host}:{$this->port}",
                $errno,
                $errstr,
                15,
                STREAM_CLIENT_CONNECT,
                $context
            );

            if (!$this->socket) {
                $this->lastError = "No se pudo conectar al servidor SMTP ({$this->host}:{$this->port}): $errstr ($errno)";
                return false;
            }

            // Leer saludo del servidor
            $resp = $this->getResponse();
            if (substr($resp, 0, 3) !== '220') {
                $this->lastError = "Respuesta no esperada del servidor: " . trim($resp);
                return false;
            }

            // 2. Identificarse ante el servidor (EHLO)
            $this->sendCommand("EHLO " . gethostname());

            // 3. Iniciar encriptación TLS
            $tlsResp = $this->sendCommand("STARTTLS");
            if (substr($tlsResp, 0, 3) === '220') {
                // Activar encriptación en el socket
                $cryptoMethod = STREAM_CRYPTO_METHOD_TLS_CLIENT;
                if (defined('STREAM_CRYPTO_METHOD_TLSv1_2_CLIENT')) {
                    $cryptoMethod |= STREAM_CRYPTO_METHOD_TLSv1_2_CLIENT;
                }
                if (defined('STREAM_CRYPTO_METHOD_TLSv1_3_CLIENT')) {
                    $cryptoMethod |= STREAM_CRYPTO_METHOD_TLSv1_3_CLIENT;
                }

                if (!@stream_socket_enable_crypto($this->socket, true, $cryptoMethod)) {
                    $this->lastError = "Error al iniciar TLS en la conexión segura con el servidor SMTP.";
                    return false;
                }

                // 4. Re-identificarse después de TLS
                $this->sendCommand("EHLO " . gethostname());
            }

            // 5. Autenticación (AUTH LOGIN)
            $authResp = $this->sendCommand("AUTH LOGIN");
            $this->sendCommand(base64_encode($this->user));
            $passResp = $this->sendCommand(base64_encode($this->pass));

            if (substr($passResp, 0, 3) !== '235') {
                $this->lastError = "Fallo de autenticación SMTP. Revisa tu correo y contraseña de aplicación en .env: " . trim($passResp);
                return false;
            }

            // 6. Configurar remitente y destinatario
            $this->sendCommand("MAIL FROM:<{$this->user}>");
            $rcptResp = $this->sendCommand("RCPT TO:<{$to}>");
            if (substr($rcptResp, 0, 3) !== '250') {
                $this->lastError = "Destinatario rechazado por el servidor: " . trim($rcptResp);
                return false;
            }

            // 7. Enviar contenido del email
            $this->sendCommand("DATA");

            // Construir headers del email
            $headers = "From: {$this->fromName} <{$this->user}>\r\n";
            $headers .= "To: <{$to}>\r\n";
            $headers .= "Subject: {$subject}\r\n";
            $headers .= "MIME-Version: 1.0\r\n";
            $headers .= "Content-Type: text/html; charset=UTF-8\r\n";
            $headers .= "X-Mailer: Specialized-PHP-SMTP\r\n";
            $headers .= "\r\n";

            // Enviar headers + body + terminador
            fwrite($this->socket, $headers . $body . "\r\n.\r\n");
            $dataResp = $this->getResponse();

            // 8. Cerrar conexión
            $this->sendCommand("QUIT");
            fclose($this->socket);

            if (substr($dataResp, 0, 3) !== '250') {
                $this->lastError = "Error al finalizar envío del correo: " . trim($dataResp);
                return false;
            }

            return true;

        } catch (\Throwable $e) {
            $this->lastError = $e->getMessage();
            if ($this->socket && is_resource($this->socket)) {
                fclose($this->socket);
            }
            return false;
        }
    }

    /**
     * Enviar un código de recuperación de contraseña por email
     * 
     * @param string $to       Email del destinatario
     * @param string $codigo   Código de 6 dígitos
     * @param string $usuario  Nombre de usuario (para personalizar el mensaje)
     * @return bool
     */
    public function enviarCodigoRecuperacion(string $to, string $codigo, string $usuario): bool
    {
        $subject = "Código de Recuperación - SPECIALIZED";

        $body = $this->getRecoveryTemplate($codigo, $usuario);

        return $this->send($to, $subject, $body);
    }

    /**
     * Obtener el último error registrado
     */
    public function getLastError(): string
    {
        return $this->lastError;
    }

    /**
     * Enviar un comando SMTP y leer la respuesta
     */
    private function sendCommand(string $command): string
    {
        fwrite($this->socket, $command . "\r\n");
        return $this->getResponse();
    }

    /**
     * Leer respuesta del servidor SMTP
     */
    private function getResponse(): string
    {
        $response = '';
        stream_set_timeout($this->socket, 10);

        while ($line = fgets($this->socket, 515)) {
            $response .= $line;
            // Si el 4to carácter es un espacio, es la última línea
            if (isset($line[3]) && $line[3] === ' ') {
                break;
            }
        }
        return $response;
    }

    /**
     * Generar el template HTML del email de recuperación
     * Con branding de Specialized
     */
    private function getRecoveryTemplate(string $codigo, string $usuario): string
    {
        return '
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; font-family: Segoe UI, Tahoma, Geneva, Verdana, sans-serif; background-color: #f0f2f5;">
    <div style="max-width: 600px; margin: 30px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 40px rgba(0,0,0,0.1);">
        
        <!-- Header con gradiente institucional -->
        <div style="background: linear-gradient(135deg, #36498f 0%, #087d4e 100%); padding: 35px 30px; text-align: center;">
            <h1 style="color: #ffffff; margin: 0; font-size: 28px; letter-spacing: 2px; font-weight: 700;">SPECIALIZED</h1>
            <p style="color: rgba(255,255,255,0.85); margin: 8px 0 0; font-size: 13px; letter-spacing: 1px;">INSTRUMENTAL DENTAL</p>
        </div>

        <!-- Cuerpo del email -->
        <div style="padding: 40px 35px;">
            <h2 style="color: #36498f; margin: 0 0 10px; font-size: 22px;">Recuperación de Contraseña</h2>
            <p style="color: #666; font-size: 15px; line-height: 1.6; margin: 0 0 25px;">
                Hola <strong style="color: #333;">' . htmlspecialchars($usuario) . '</strong>, recibimos una solicitud para restablecer la contraseña de tu cuenta.
            </p>

            <!-- Código destacado -->
            <div style="background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%); border-radius: 12px; padding: 30px; text-align: center; margin: 25px 0; border-left: 5px solid #36498f;">
                <p style="color: #888; font-size: 13px; margin: 0 0 10px; text-transform: uppercase; letter-spacing: 1px;">Tu código de verificación</p>
                <div style="font-size: 38px; font-weight: 800; color: #36498f; letter-spacing: 12px; font-family: monospace;">' . $codigo . '</div>
                <p style="color: #999; font-size: 12px; margin: 12px 0 0;">Este código expira en <strong>5 minutos</strong></p>
            </div>

            <!-- Aviso de seguridad -->
            <div style="background: #fff8e1; border-radius: 8px; padding: 15px 20px; margin: 20px 0; border-left: 4px solid #f59e0b;">
                <p style="color: #856404; font-size: 13px; margin: 0; line-height: 1.5;">
                    <strong>⚠️ Seguridad:</strong> Si no solicitaste este código, ignora este mensaje. Tu cuenta permanece segura.
                </p>
            </div>

            <p style="color: #999; font-size: 13px; margin: 25px 0 0; line-height: 1.5;">
                No compartas este código con nadie. El equipo de SPECIALIZED nunca te pedirá tu contraseña.
            </p>
        </div>

        <!-- Footer -->
        <div style="background: #f8f9fa; padding: 20px 35px; text-align: center; border-top: 1px solid #eee;">
            <p style="color: #999; font-size: 12px; margin: 0;">SPECIALIZED - Instrumental Dental</p>
            <p style="color: #bbb; font-size: 11px; margin: 5px 0 0;">Calle 41 #6-68, Lagos 2, Floridablanca, Santander | +57 (607) 649 6730</p>
        </div>
    </div>
</body>
</html>';
    }
}

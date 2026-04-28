<?php
/**
 * ============================================================
 * RECUPERACIÓN DE CONTRASEÑA
 * ============================================================
 * 
 * PROPÓSITO:
 * Maneja el proceso de recuperación de contraseña en 3 pasos:
 *   Paso 1 → Buscar al usuario por su nombre
 *   Paso 2 → Enviar un código de verificación por EMAIL (Gmail SMTP)
 *   Paso 3 → Verificar el código y cambiar la contraseña
 * 
 * El código se envía al correo electrónico registrado del usuario
 * usando SMTP autenticado de Gmail.
 * ============================================================
 */
declare(strict_types=1)
;

// Iniciar sesión para guardar el código temporalmente
session_start();

include_once __DIR__ . "/conexion.php";

// Cabeceras de seguridad y formato de respuesta
header("Content-Type: application/json; charset=UTF-8");
header("X-Content-Type-Options: nosniff");
header("X-Frame-Options: DENY");

// Función auxiliar para enviar respuesta JSON estandarizada
function enviarRespuesta($success, $mensaje, $data = [])
{
    echo json_encode(array_merge(['success' => $success, 'message' => $mensaje], $data));
    exit;
}

// Solo se aceptan peticiones POST
if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    http_response_code(405);
    enviarRespuesta(false, "Método no permitido");
}

// Se recibe qué paso del proceso se está ejecutando
$accion = $_POST['accion'] ?? '';

try {
    // ══════════════════════════════════════════════
    // CONEXIÓN A LA BASE DE DATOS
    // ══════════════════════════════════════════════
    $conexion = new CConexion();
    $conn = $conexion->conexionBD();

    if (!$conn) {
        throw new Exception("Error de conexión a la base de datos");
    }

    // ══════════════════════════════════════════════
    // PASO 1: BUSCAR USUARIO
    // ══════════════════════════════════════════════
    // El usuario escribe su nombre de usuario.
    // El sistema busca si existe y devuelve su correo y teléfono
    // enmascarados (ej: a***z@gmail.com, ******1234)
    // para que el usuario elija por dónde recibir el código.
    if ($accion === 'buscar_usuario') {
        $usuario = trim($_POST['usuario'] ?? '');

        if (empty($usuario)) {
            enviarRespuesta(false, "Ingresa tu usuario");
        }

        $stmt = $conn->prepare("SELECT id_user, nom_user, mail_user, tel_user FROM tab_users WHERE nom_user = :u LIMIT 1");
        $stmt->execute([':u' => $usuario]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user) {
            // Guardar datos en sesión para los pasos siguientes
            $_SESSION['recup_id_user'] = $user['id_user'];
            $_SESSION['recup_nom_user'] = $user['nom_user'];
            $_SESSION['recup_mail_user'] = $user['mail_user'];

            // Enmascarar datos personales por privacidad
            $mail = $user['mail_user'];

            if (empty($mail)) {
                enviarRespuesta(false, "Este usuario no tiene un correo electrónico registrado.");
            }

            // Enmascarar email: mostrar solo primera y última letra antes del @
            $parts = explode('@', $mail);
            $maskMail = substr($parts[0], 0, 1) . str_repeat('*', max(3, strlen($parts[0]) - 2)) . substr($parts[0], -1) . '@' . $parts[1];

            enviarRespuesta(true, "Usuario encontrado", [
                'email_masked' => $maskMail,
                'has_email' => true
            ]);
        } else {
            enviarRespuesta(false, "Usuario no encontrado");
        }
    }

    // ══════════════════════════════════════════════
    // PASO 2: ENVIAR CÓDIGO DE VERIFICACIÓN POR EMAIL
    // ══════════════════════════════════════════════
    // Genera un código aleatorio de 6 dígitos,
    // lo guarda en la sesión con una expiración de 5 minutos,
    // y lo envía al correo electrónico registrado del usuario.
    elseif ($accion === 'enviar_codigo') {
        if (!isset($_SESSION['recup_id_user']) || !isset($_SESSION['recup_mail_user'])) {
            enviarRespuesta(false, "Sesión expirada. Busca tu usuario nuevamente.");
        }

        // Generar código aleatorio de 6 dígitos
        $codigo = rand(100000, 999999);

        // Guardar código en sesión con expiración de 5 minutos
        $_SESSION['recup_codigo'] = (string) $codigo;
        $_SESSION['recup_expire'] = time() + 300;

        // Enviar el código por email real usando SMTP
        require_once __DIR__ . '/smtp_mailer.php';
        $mailer = new SmtpMailer();

        $enviado = $mailer->enviarCodigoRecuperacion(
            $_SESSION['recup_mail_user'],
            (string) $codigo,
            $_SESSION['recup_nom_user']
        );

        if ($enviado) {
            enviarRespuesta(true, "Código enviado a tu correo electrónico.");
        } else {
            error_log("SMTP Error: " . $mailer->getLastError());
            enviarRespuesta(false, "No se pudo enviar el correo. Intenta nuevamente en unos minutos.");
        }
    }

    // ══════════════════════════════════════════════
    // PASO 3: VERIFICAR CÓDIGO Y CAMBIAR CONTRASEÑA
    // ══════════════════════════════════════════════
    // Compara el código ingresado con el guardado en sesión.
    // Si es correcto y no ha expirado, actualiza la contraseña
    // en la base de datos con un hash seguro.
    elseif ($accion === 'verificar_cambiar') {
        if (!isset($_SESSION['recup_id_user']) || !isset($_SESSION['recup_codigo'])) {
            enviarRespuesta(false, "Sesión expirada. Reinicia el proceso.");
        }

        $codigoIngresado = trim($_POST['codigo'] ?? '');
        $newPass = $_POST['new_password'] ?? '';

        // Verificar que el código coincida
        if ($codigoIngresado !== $_SESSION['recup_codigo']) {
            enviarRespuesta(false, "Código incorrecto");
        }

        // Verificar que no haya expirado (5 minutos)
        if (time() > $_SESSION['recup_expire']) {
            enviarRespuesta(false, "El código ha expirado");
        }

        // Validar que la nueva contraseña cumpla la política de seguridad
        if (strlen($newPass) < 8 || !preg_match('/[A-Z]/', $newPass) || !preg_match('/[a-z]/', $newPass) || !preg_match('/[0-9]/', $newPass)) {
            enviarRespuesta(false, "La contraseña no cumple con los requisitos de seguridad");
        }

        // Cifrar y guardar la nueva contraseña en la base de datos
        $hash = password_hash($newPass, PASSWORD_DEFAULT);
        $upd = $conn->prepare("UPDATE tab_users SET pass_user = :p, fec_update = NOW(), user_update = :u_upd WHERE id_user = :id");
        $upd->execute([
            ':p' => $hash,
            ':u_upd' => $_SESSION['recup_nom_user'],
            ':id' => $_SESSION['recup_id_user']
        ]);

        // Limpiar datos temporales de la sesión
        unset($_SESSION['recup_id_user']);
        unset($_SESSION['recup_nom_user']);
        unset($_SESSION['recup_mail_user']);
        unset($_SESSION['recup_codigo']);
        unset($_SESSION['recup_expire']);

        enviarRespuesta(true, "Contraseña actualizada correctamente");
    } else {
        enviarRespuesta(false, "Acción no válida");
    }

} catch (Throwable $e) {
    error_log("Error Recuperación: " . $e->getMessage());
    enviarRespuesta(false, "Error del servidor: " . $e->getMessage());
}

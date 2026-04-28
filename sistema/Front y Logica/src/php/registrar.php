<?php
/**
 * ============================================================
 * REGISTRO DE NUEVOS USUARIOS
 * ============================================================
 * 
 * PROPÓSITO:
 * Procesa el formulario de registro. Recibe usuario, correo,
 * teléfono y contraseña, valida todo, y si cumple los requisitos,
 * crea la cuenta en la base de datos con menú de cliente (menú 2).
 * 
 * FLUJO:
 * 1. Verificar que sea petición POST y que los campos no estén vacíos
 * 2. Validar formato de usuario, correo, teléfono y contraseña
 * 3. Cifrar la contraseña con hash seguro
 * 4. Verificar que no exista un usuario o correo duplicado
 * 5. Insertar usuario y asignarle el menú de cliente
 * 6. Devolver éxito o error en formato JSON
 * 
 * SEGURIDAD (OWASP):
 * - Consultas preparadas contra inyección SQL
 * - Contraseña cifrada con password_hash() (bcrypt)
 * - Validaciones estrictas de formato en todos los campos
 * ============================================================
 */
declare(strict_types=1)
;

include_once __DIR__ . "/conexion.php";

// ══════════════════════════════════════════════
// BLOQUE 1: CABECERAS DE SEGURIDAD
// ══════════════════════════════════════════════
header("X-Content-Type-Options: nosniff");
header("X-Frame-Options: DENY");
header("Referrer-Policy: no-referrer");
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Pragma: no-cache");

// ══════════════════════════════════════════════
// BLOQUE 2: FUNCIÓN PARA DEVOLVER ERRORES
// ══════════════════════════════════════════════
// Envía una respuesta JSON indicando que algo falló,
// con un mensaje descriptivo para el usuario.
function volverConError(string $mensaje): void
{
    header('Content-Type: application/json');
    echo json_encode(['success' => false, 'error' => $mensaje]);
    exit();
}

// ══════════════════════════════════════════════
// BLOQUE 3: VERIFICAR MÉTODO HTTP
// ══════════════════════════════════════════════
// Solo se acepta POST (envío de formulario).
if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    http_response_code(405);
    exit("Método no permitido");
}

// ══════════════════════════════════════════════
// BLOQUE 4: RECIBIR Y LIMPIAR DATOS DEL FORMULARIO
// ══════════════════════════════════════════════
// Limpia espacios en blanco y elimina caracteres no numéricos
// del teléfono como medidas de sanitización.
$usuario = trim($_POST["usuario"] ?? "");
$mail = trim($_POST["mail_user"] ?? "");
$tel = preg_replace('/[^0-9]/', '', $_POST["tel_user"] ?? "");
$password = $_POST["password"] ?? "";
$terms = $_POST["terms"] ?? ""; // Checkbox de términos

// ══════════════════════════════════════════════
// BLOQUE 5: VALIDACIONES DE SEGURIDAD
// ══════════════════════════════════════════════
// Verifica que cada campo cumpla con los requisitos mínimos
// antes de intentar guardar en la base de datos.

// Todos los campos son requeridos
if ($usuario === '' || $mail === '' || $tel === '' || $password === '') {
    volverConError("Todos los campos son obligatorios");
}

// Validación de Términos y Condiciones
if ($terms !== 'on') {
    volverConError("Debes aceptar los términos y condiciones para registrarte");
}

// El usuario solo puede tener letras, números y guion bajo (3 a 50 caracteres)
if (!preg_match('/^[a-zA-Z0-9_]{3,50}$/', $usuario)) {
    volverConError("El usuario debe tener entre 3 y 50 caracteres y solo letras o números");
}

// El correo debe tener formato válido (ejemplo@dominio.com)
if (!filter_var($mail, FILTER_VALIDATE_EMAIL)) {
    volverConError("Correo electrónico inválido");
}

// El teléfono debe tener entre 7 y 10 dígitos
if (strlen($tel) < 7 || strlen($tel) > 10) {
    volverConError("Número de teléfono inválido");
}

// La contraseña debe cumplir política de seguridad
if (strlen($password) < 8) {
    volverConError("La contraseña debe tener al menos 8 caracteres");
}
if (!preg_match('/[A-Z]/', $password)) {
    volverConError("La contraseña debe tener al menos una letra mayúscula");
}
if (!preg_match('/[a-z]/', $password)) {
    volverConError("La contraseña debe tener al menos una letra minúscula");
}
if (!preg_match('/[0-9]/', $password)) {
    volverConError("La contraseña debe tener al menos un número");
}

// ══════════════════════════════════════════════
// BLOQUE 6: CIFRAR CONTRASEÑA
// ══════════════════════════════════════════════
// Convierte la contraseña en un hash irreversible.
// Aunque alguien vea la base de datos, no podrá leer la contraseña real.
$hash = password_hash($password, PASSWORD_DEFAULT);

// ══════════════════════════════════════════════
// BLOQUE 7: CONECTAR A LA BASE DE DATOS
// ══════════════════════════════════════════════
$conexion = new CConexion();
$conn = $conexion->conexionBD();

if (!$conn) {
    volverConError("Error de conexión con la base de datos");
}

try {
    // Se inicia una transacción: si algo falla, todo se deshace
    $conn->beginTransaction();

    // ══════════════════════════════════════════════
    // BLOQUE 8: VERIFICAR QUE NO EXISTA DUPLICADO
    // ══════════════════════════════════════════════
    // Busca si ya hay un usuario con ese nombre o correo.
    // La comparación ignora mayúsculas/minúsculas.
    $check = $conn->prepare("
        SELECT 1 
        FROM tab_users 
        WHERE LOWER(nom_user) = LOWER(:u)
           OR LOWER(mail_user) = LOWER(:m)
        LIMIT 1
    ");
    $check->execute([
        ':u' => $usuario,
        ':m' => $mail
    ]);

    if ($check->fetchColumn()) {
        $conn->rollBack();
        volverConError("El usuario o correo ya existen");
    }

    // ══════════════════════════════════════════════
    // BLOQUE 9: GENERAR ID Y GUARDAR USUARIO
    // ══════════════════════════════════════════════
    // Calcula el siguiente ID disponible e inserta el usuario
    // con todos sus datos en la tabla principal.
    $nextId = (int) $conn
        ->query("SELECT COALESCE(MAX(id_user),0)+1 FROM tab_users")
        ->fetchColumn();

    $insUser = $conn->prepare("
        INSERT INTO tab_users 
        (id_user, nom_user, pass_user, tel_user, mail_user, user_insert, fec_insert, ind_vivo)
        VALUES 
        (:id, :nom, :pass, :tel, :mail, :uins, NOW(), TRUE)
    ");

    $insUser->execute([
        ':id' => $nextId,
        ':nom' => $usuario,
        ':pass' => $hash,
        ':tel' => $tel,
        ':mail' => $mail,
        ':uins' => $usuario
    ]);

    // ══════════════════════════════════════════════
    // BLOQUE 10: ASIGNAR MENÚ DE CLIENTE
    // ══════════════════════════════════════════════
    // Todo usuario nuevo se registra como CLIENTE (menú 2).
    // Los administradores (menú 1) se asignan manualmente.

    $MENU_CLIENTE_ID = 2;

    $insUM = $conn->prepare("
        INSERT INTO tab_users_menu
        (id_user, id_menu, nom_prog, user_insert, fec_insert, ind_vivo)
        VALUES
        (:id_user, :id_menu, :nom_prog, :user_insert, NOW(), TRUE)
    ");

    $insUM->execute([
        ':id_user' => $nextId,
        ':id_menu' => $MENU_CLIENTE_ID,
        ':nom_prog' => 'Cliente',
        ':user_insert' => $usuario
    ]);

    // Confirmar la transacción (hacer permanentes los cambios)
    $conn->commit();

    // ══════════════════════════════════════════════
    // BLOQUE 11: RESPUESTA EXITOSA
    // ══════════════════════════════════════════════
    header('Content-Type: application/json');
    echo json_encode(['success' => true, 'message' => 'Usuario creado exitosamente. Ya puedes iniciar sesión.']);
    exit();

} catch (Throwable $e) {
    // Si algo falló, deshacer todos los cambios en la BD
    if ($conn->inTransaction()) {
        $conn->rollBack();
    }

    // Registrar el error en los logs del servidor (nunca se muestra al usuario)
    error_log('[REGISTRO ERROR] ' . $e->getMessage());
    volverConError("Ocurrió un error interno. Intenta nuevamente");
}

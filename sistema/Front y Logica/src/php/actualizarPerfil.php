<?php
/**
 * ============================================================
 * ACTUALIZACIÓN DE PERFIL DE USUARIO
 * ============================================================
 * 
 * PROPÓSITO:
 * Permite al usuario cambiar su nombre, correo y teléfono
 * desde el panel de perfil del menú principal.
 * 
 * FLUJO:
 * 1. Verificar que haya una sesión activa
 * 2. Recibir los nuevos datos del formulario
 * 3. Validar formato de cada campo
 * 4. Verificar que el nuevo nombre no esté en uso por otro usuario
 * 5. Actualizar la base de datos
 * 6. Redirigir al menú principal con mensaje de resultado
 * ============================================================
 */
session_start();
include_once("conexion.php");

// ══════════════════════════════════════════════
// BLOQUE 2: VERIFICAR SESIÓN ACTIVA
// ══════════════════════════════════════════════
// Si no hay un usuario autenticado, redirige al login.
if (!isset($_SESSION['id_usuario'])) {
    $_SESSION['error_perfil'] = "Sesión no válida. Por favor, inicia sesión nuevamente.";
    header("Location: ../../html/InicioSesion.html");
    exit();
}

// ══════════════════════════════════════════════
// BLOQUE 3: VERIFICAR MÉTODO HTTP
// ══════════════════════════════════════════════
// Solo acepta POST (envío de formulario de perfil).
if ($_SERVER["REQUEST_METHOD"] != "POST") {
    $_SESSION['error_perfil'] = "Error: No se recibieron datos del formulario. Método recibido: " . $_SERVER["REQUEST_METHOD"];
    header("Location: menuPrincipal.php");
    exit();
}

// ══════════════════════════════════════════════
// BLOQUE 4: RECIBIR Y LIMPIAR DATOS
// ══════════════════════════════════════════════
// Toma los datos del formulario y los limpia
// (espacios en blanco, caracteres no numéricos en el teléfono).
$nom_user = trim($_POST["nom_user"] ?? "");
$mail_user = trim($_POST["mail_user"] ?? "");
$tel_user = preg_replace('/[^0-9]/', '', $_POST["tel_user"] ?? "");

// ══════════════════════════════════════════════
// BLOQUE 5: VALIDAR CAMPOS
// ══════════════════════════════════════════════
// Verifica que ningún campo esté vacío y que el email tenga formato válido.
if ($nom_user === '' || $mail_user === '' || $tel_user === '') {
    $_SESSION['error_perfil'] = "Todos los campos son obligatorios. Nombre: " . ($nom_user ?: 'vacío') . ", Email: " . ($mail_user ?: 'vacío') . ", Tel: " . ($tel_user ?: 'vacío');
    header("Location: menuPrincipal.php");
    exit();
}

// Convertir teléfono a número (la columna en BD es DECIMAL(10))
$tel_user_int = (int) $tel_user;

if (!filter_var($mail_user, FILTER_VALIDATE_EMAIL)) {
    $_SESSION['error_perfil'] = "El formato del email no es válido";
    header("Location: menuPrincipal.php");
    exit();
}

// ══════════════════════════════════════════════
// BLOQUE 6: CONECTAR A LA BASE DE DATOS
// ══════════════════════════════════════════════
$id_usuario = $_SESSION['id_usuario'];
$conexion = new CConexion();
$conn = $conexion->conexionBD();

if (!$conn) {
    $_SESSION['error_perfil'] = "Error de conexión a la base de datos";
    header("Location: menuPrincipal.php");
    exit();
}

try {
    // ══════════════════════════════════════════════
    // BLOQUE 7: VERIFICAR NOMBRE NO DUPLICADO
    // ══════════════════════════════════════════════
    // Busca si otro usuario (diferente al actual) ya tiene ese nombre.
    $check = $conn->prepare("SELECT id_user FROM tab_users WHERE LOWER(nom_user) = LOWER(:nom) AND id_user != :id");
    $check->execute([':nom' => $nom_user, ':id' => $id_usuario]);
    if ($check->fetchColumn()) {
        $_SESSION['error_perfil'] = "El nombre de usuario ya está en uso. Elige otro.";
        header("Location: menuPrincipal.php");
        exit();
    }

    // ══════════════════════════════════════════════
    // BLOQUE 8: ACTUALIZAR DATOS EN LA BASE DE DATOS
    // ══════════════════════════════════════════════
    // Ejecuta la actualización registrando quién hizo el cambio
    // y cuándo (campos user_update y fec_update para auditoría).
    $user_update = $_SESSION['nom_user'];

    $sql = "UPDATE tab_users 
            SET nom_user = :nom, 
                mail_user = :mail, 
                tel_user = :tel,
                user_update = :user_update,
                fec_update = NOW()
            WHERE id_user = :id";

    $stmt = $conn->prepare($sql);
    $stmt->bindParam(":nom", $nom_user, PDO::PARAM_STR);
    $stmt->bindParam(":mail", $mail_user, PDO::PARAM_STR);
    $stmt->bindParam(":tel", $tel_user_int, PDO::PARAM_INT);
    $stmt->bindParam(":user_update", $user_update, PDO::PARAM_STR);
    $stmt->bindParam(":id", $id_usuario, PDO::PARAM_INT);

    $resultado = $stmt->execute();
    $filas_afectadas = $stmt->rowCount();

    // ══════════════════════════════════════════════
    // BLOQUE 9: EVALUAR RESULTADO
    // ══════════════════════════════════════════════
    // Si se actualizaron filas, renueva los datos de sesión.
    // Si no se afectó ninguna fila, verifica si es porque el
    // usuario no existe o porque los datos son iguales.
    if ($resultado && $filas_afectadas > 0) {
        // Actualizar la sesión con los nuevos datos
        $_SESSION['nom_user'] = $nom_user;
        $_SESSION['mail_user'] = $mail_user;
        $_SESSION['tel_user'] = $tel_user;
        $_SESSION['success_perfil'] = "Perfil actualizado correctamente";
    } else {
        if ($filas_afectadas == 0) {
            $verificar = $conn->prepare("SELECT id_user FROM tab_users WHERE id_user = :id");
            $verificar->execute([':id' => $id_usuario]);
            if (!$verificar->fetchColumn()) {
                $_SESSION['error_perfil'] = "Error: Usuario no encontrado en la base de datos";
            } else {
                $_SESSION['error_perfil'] = "No se realizaron cambios. Los datos pueden ser iguales a los actuales.";
            }
        } else {
            $_SESSION['error_perfil'] = "Error al actualizar el perfil. Intenta nuevamente.";
        }
    }

} catch (PDOException $e) {
    error_log("Error al actualizar perfil: " . $e->getMessage());
    $_SESSION['error_perfil'] = "Error al comunicarse con la base de datos. Intente nuevamente.";
    if (class_exists('CConexion') && CConexion::isDebugEnabled()) {
        $_SESSION['error_perfil'] .= " (Debug: " . $e->getMessage() . ")";
    }
}

// Redirigir de vuelta al menú principal
header("Location: menuPrincipal.php");
exit();
?>
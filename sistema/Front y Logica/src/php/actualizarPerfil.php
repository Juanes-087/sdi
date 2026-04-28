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

// ══════════════════════════════════════════════
// BLOQUE 1: INFORMACIÓN DE DEPURACIÓN
// ══════════════════════════════════════════════
// Guarda en sesión los datos recibidos para poder diagnosticar
// problemas si algo falla durante la actualización.
$_SESSION['debug_inicio'] = [
    'timestamp' => date('Y-m-d H:i:s'),
    'method' => $_SERVER["REQUEST_METHOD"],
    'post_data' => $_POST,
    'session_id' => session_id(),
    'id_usuario_en_sesion' => $_SESSION['id_usuario'] ?? 'NO DEFINIDO'
];

include_once("conexion.php");

error_reporting(E_ALL);
ini_set('display_errors', 1);

// ══════════════════════════════════════════════
// BLOQUE 2: VERIFICAR SESIÓN ACTIVA
// ══════════════════════════════════════════════
// Si no hay un usuario autenticado, redirige al login.
if (!isset($_SESSION['id_usuario'])) {
    $_SESSION['error_perfil'] = "Sesión no válida. Por favor, inicia sesión nuevamente.";
    $_SESSION['debug_error'] = "No hay id_usuario en sesión";
    header("Location: ../../html/InicioSesion.html");
    exit();
}

// ══════════════════════════════════════════════
// BLOQUE 3: VERIFICAR MÉTODO HTTP
// ══════════════════════════════════════════════
// Solo acepta POST (envío de formulario de perfil).
if ($_SERVER["REQUEST_METHOD"] != "POST") {
    $_SESSION['error_perfil'] = "Error: No se recibieron datos del formulario. Método recibido: " . $_SERVER["REQUEST_METHOD"];
    $_SESSION['debug_error'] = "No es POST, es: " . $_SERVER["REQUEST_METHOD"];
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

// Guardar datos para depuración
$_SESSION['debug_post'] = [
    'nom_user' => $nom_user,
    'mail_user' => $mail_user,
    'tel_user' => $tel_user,
    'post_completo' => $_POST
];

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

    // Guardar información de la ejecución para depuración
    $_SESSION['debug_update'] = [
        'resultado' => $resultado,
        'filas_afectadas' => $filas_afectadas,
        'id_usuario' => $id_usuario,
        'sql' => $sql,
        'valores' => [
            'nom_user' => $nom_user,
            'mail_user' => $mail_user,
            'tel_user_int' => $tel_user_int,
            'user_update' => $user_update
        ],
        'error_info' => $stmt->errorInfo()
    ];

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
    $_SESSION['error_perfil'] = "Error en la base de datos: " . $e->getMessage();
    $_SESSION['debug_error'] = [
        'mensaje' => $e->getMessage(),
        'codigo' => $e->getCode(),
        'archivo' => $e->getFile(),
        'linea' => $e->getLine()
    ];
    error_log("Error al actualizar perfil: " . $e->getMessage());
}

// ══════════════════════════════════════════════
// BLOQUE 10: MODO DEPURACIÓN (OPCIONAL)
// ══════════════════════════════════════════════
// Si se accede con ?debug=1, muestra toda la información
// de depuración en pantalla en lugar de redirigir.
if (isset($_GET['debug']) && $_GET['debug'] == '1') {
    echo "<h2>Debug de Actualización</h2>";
    echo "<pre>";
    echo "Datos POST recibidos:\n";
    print_r($_POST);
    echo "\n\nDatos procesados:\n";
    echo "nom_user: " . $nom_user . "\n";
    echo "mail_user: " . $mail_user . "\n";
    echo "tel_user_int: " . $tel_user_int . "\n";
    echo "id_usuario: " . $id_usuario . "\n";
    echo "\n\nDebug de sesión:\n";
    print_r($_SESSION['debug_update'] ?? 'No hay debug_update');
    if (isset($_SESSION['debug_error'])) {
        echo "\n\nError:\n";
        print_r($_SESSION['debug_error']);
    }
    echo "</pre>";
    echo "<a href='menuPrincipal.php'>Volver al menú</a>";
    exit();
}

// Redirigir de vuelta al menú principal
header("Location: menuPrincipal.php");
exit();
?>
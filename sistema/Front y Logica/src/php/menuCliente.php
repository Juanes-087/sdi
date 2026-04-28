<?php
/**
 * ============================================================
 * PÁGINA PRINCIPAL DEL CLIENTE (TIENDA ONLINE)
 * ============================================================
 * 
 * PROPÓSITO:
 * Vista principal para los usuarios con rol de CLIENTE.
 * Muestra el catálogo de productos, carrito de compras,
 * y opciones de perfil/contraseña.
 * 
 * A DIFERENCIA de menuPrincipal.php (para administradores),
 * esta página NO usa la estructura modular de includes/.
 * Tiene todo en un solo archivo (autenticación + vista).
 * 
 * SECCIONES:
 * 1. Autenticación (JWT y sesión PHP)
 * 2. Procesamiento de perfil y contraseña (POST)
 * 3. Barra de navegación con búsqueda y carrito
 * 4. Catálogo de productos (cargado por JavaScript)
 * 5. Carrito de compras (panel lateral)
 * 6. Modales de perfil y contraseña
 * 7. Lógica de cierre de sesión
 * ============================================================
 */

// ══════════════════════════════════════════════════════════
// SECCIÓN 1: CARGA DE DEPENDENCIAS Y AUTENTICACIÓN
// ══════════════════════════════════════════════════════════
include_once("security_headers.php");  // Cabeceras de seguridad
include_once("conexion.php");           // Conexión a la base de datos
include_once("jwt.php");                // Funciones de JWT

// Validar si viene token JWT en la URL (desde el login)
$token = $_GET['token'] ?? null;

if ($token) {
    $payload = validarJWT($token);

    if ($payload && isset($payload['id'])) {
        // Token válido: crear sesión PHP
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
        // Regenerar ID de sesión para seguridad
        session_regenerate_id(true);

        $_SESSION['id_usuario'] = $payload['id'];
        $_SESSION['nom_user'] = $payload['usuario'] ?? '';
        $_SESSION['id_menu'] = $payload['menu'] ?? 2;

        // Completar datos del usuario desde la base de datos
        $conexion = new CConexion();
        $conn = $conexion->conexionBD();
        if ($conn) {
            try {
                $sql = "SELECT nom_user, mail_user, tel_user FROM tab_users WHERE id_user = :id";
                $stmt = $conn->prepare($sql);
                $stmt->bindParam(":id", $_SESSION['id_usuario'], PDO::PARAM_INT);
                $stmt->execute();
                $userData = $stmt->fetch(PDO::FETCH_ASSOC);

                if ($userData) {
                    $_SESSION['nom_user'] = $userData['nom_user'] ?? $_SESSION['nom_user'];
                    $_SESSION['mail_user'] = $userData['mail_user'] ?? '';
                    $_SESSION['tel_user'] = $userData['tel_user'] ?? '';
                }
            } catch (PDOException $e) {
                error_log("Error al cargar datos del usuario: " . $e->getMessage());
            }
        }

        // Redirigir sin el token en la URL (seguridad)
        header("Location: menuCliente.php");
        exit();
    } else {
        // Token inválido o expirado
        header("Location: ../../html/InicioSesion.html");
        exit();
    }
}

// Si no llegó con token, verificar sesión existente
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

if (!isset($_SESSION['id_usuario'])) {
    header("Location: ../../html/InicioSesion.html");
    exit();
}

// Completar datos de sesión si faltan
if (isset($_SESSION['id_usuario']) && (!isset($_SESSION['mail_user']) || !isset($_SESSION['tel_user']))) {
    $conexion = new CConexion();
    $conn = $conexion->conexionBD();
    if ($conn) {
        try {
            $sql = "SELECT nom_user, mail_user, tel_user FROM tab_users WHERE id_user = :id";
            $stmt = $conn->prepare($sql);
            $stmt->bindParam(":id", $_SESSION['id_usuario'], PDO::PARAM_INT);
            $stmt->execute();
            $userData = $stmt->fetch(PDO::FETCH_ASSOC);

            if ($userData) {
                $_SESSION['nom_user'] = $userData['nom_user'] ?? $_SESSION['nom_user'] ?? '';
                $_SESSION['mail_user'] = $userData['mail_user'] ?? '';
                $_SESSION['tel_user'] = $userData['tel_user'] ?? '';
            }
        } catch (PDOException $e) {
            error_log("Error al cargar datos del usuario: " . $e->getMessage());
        }
    }
}

// ══════════════════════════════════════════════════════════
// SECCIÓN 2: PROCESAMIENTO DE FORMULARIOS (POST)
// ══════════════════════════════════════════════════════════

// --- Actualización de Perfil ---
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['nom_user'])) {
    $nom_user = trim($_POST["nom_user"] ?? "");
    $mail_user = trim($_POST["mail_user"] ?? "");
    $tel_user = preg_replace('/[^0-9]/', '', $_POST["tel_user"] ?? "");
    $tel_user_int = (int) $tel_user;

    // Validaciones
    if ($nom_user === '' || $mail_user === '' || $tel_user === '') {
        $_SESSION['error_perfil'] = "Todos los campos son obligatorios";
    } elseif (!filter_var($mail_user, FILTER_VALIDATE_EMAIL)) {
        $_SESSION['error_perfil'] = "El formato del email no es válido";
    } else {
        $id_usuario = $_SESSION['id_usuario'];
        $conexion = new CConexion();
        $conn = $conexion->conexionBD();

        if ($conn) {
            try {
                // Verificar si el nombre de usuario ya existe
                $check = $conn->prepare("SELECT id_user FROM tab_users WHERE LOWER(nom_user) = LOWER(:nom) AND id_user != :id");
                $check->execute([':nom' => $nom_user, ':id' => $id_usuario]);
                if ($check->fetchColumn()) {
                    $_SESSION['error_perfil'] = "El nombre de usuario ya está en uso. Elige otro.";
                } else {
                    // Actualizar
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
                    $error_info = $stmt->errorInfo();

                    if ($resultado && $error_info[0] == '00000') {
                        // Actualizar la sesión con los nuevos datos
                        $_SESSION['nom_user'] = $nom_user;
                        $_SESSION['mail_user'] = $mail_user;
                        $_SESSION['tel_user'] = $tel_user;
                        $_SESSION['success_perfil'] = "Perfil actualizado correctamente";
                    } else {
                        $_SESSION['error_perfil'] = "Error al actualizar. Código: " . $error_info[0];
                    }
                }
            } catch (PDOException $e) {
                $_SESSION['error_perfil'] = "Error en la base de datos: " . $e->getMessage();
            }
        } else {
            $_SESSION['error_perfil'] = "Error de conexión a la base de datos";
        }
    }

    // Redirigir para evitar reenvío del formulario
    header("Location: " . $_SERVER['PHP_SELF']);
    exit();
}

// --- Cambio de Contraseña ---
if ($_SERVER["REQUEST_METHOD"] == "POST" && isset($_POST['cambiar_password'])) {
    $password_actual = trim($_POST["password_actual"] ?? "");
    $password_nueva = trim($_POST["password_nueva"] ?? "");
    $password_confirmar = trim($_POST["password_confirmar"] ?? "");

    // Validaciones
    if ($password_actual === '' || $password_nueva === '' || $password_confirmar === '') {
        $_SESSION['error_password'] = "Todos los campos son obligatorios";
    } elseif (strlen($password_nueva) < 8) {
        $_SESSION['error_password'] = "La nueva contraseña debe tener al menos 8 caracteres";
    } elseif ($password_nueva !== $password_confirmar) {
        $_SESSION['error_password'] = "Las contraseñas nuevas no coinciden";
    } else {
        $id_usuario = $_SESSION['id_usuario'];
        $conexion = new CConexion();
        $conn = $conexion->conexionBD();

        if ($conn) {
            try {
                // Obtener contraseña actual del usuario
                $sql = "SELECT pass_user FROM tab_users WHERE id_user = :id";
                $stmt = $conn->prepare($sql);
                $stmt->bindParam(":id", $id_usuario, PDO::PARAM_INT);
                $stmt->execute();
                $usuario = $stmt->fetch(PDO::FETCH_ASSOC);

                if ($usuario) {
                    // Verificar contraseña actual
                    $password_valida = false;
                    $pass_hash = $usuario['pass_user'];

                    // Verificar si es un hash (empieza con $2y$ o $2a$)
                    if (substr($pass_hash, 0, 4) === '$2y$' || substr($pass_hash, 0, 4) === '$2a$' || substr($pass_hash, 0, 4) === '$2b$') {
                        // Es un hash bcrypt, usar password_verify
                        $password_valida = password_verify($password_actual, $pass_hash);
                    } else {
                        // No es hash, comparar directamente (legacy)
                        $password_valida = ($pass_hash === $password_actual);
                    }

                    if ($password_valida) {
                        // Hashear nueva contraseña
                        $password_hash = password_hash($password_nueva, PASSWORD_DEFAULT);

                        // Actualizar contraseña
                        $sql_update = "UPDATE tab_users 
                                      SET pass_user = :pass,
                                          user_update = :user_update,
                                          fec_update = NOW()
                                      WHERE id_user = :id";

                        $stmt_update = $conn->prepare($sql_update);
                        $stmt_update->bindParam(":pass", $password_hash, PDO::PARAM_STR);
                        $stmt_update->bindParam(":user_update", $_SESSION['nom_user'], PDO::PARAM_STR);
                        $stmt_update->bindParam(":id", $id_usuario, PDO::PARAM_INT);

                        $resultado_update = $stmt_update->execute();
                        $error_info = $stmt_update->errorInfo();

                        if ($resultado_update && $error_info[0] == '00000') {
                            $_SESSION['success_password'] = "Contraseña actualizada correctamente";
                        } else {
                            $_SESSION['error_password'] = "Error al actualizar la contraseña. Código: " . $error_info[0];
                        }
                    } else {
                        $_SESSION['error_password'] = "La contraseña actual es incorrecta";
                    }
                } else {
                    $_SESSION['error_password'] = "Usuario no encontrado";
                }
            } catch (PDOException $e) {
                $_SESSION['error_password'] = "Error en la base de datos: " . $e->getMessage();
            }
        } else {
            $_SESSION['error_password'] = "Error de conexión a la base de datos";
        }
    }

    // Redirigir para evitar reenvío de formulario y PRG
    header("Location: " . $_SERVER['PHP_SELF']);
    exit();
}

// ══════════════════════════════════════════════════════════
// SECCIÓN 3: DATOS PARA LA VISTA
// ══════════════════════════════════════════════════════════
$nom_user = isset($_SESSION['nom_user']) ? $_SESSION['nom_user'] : 'Usuario';
$mail_user = isset($_SESSION['mail_user']) ? $_SESSION['mail_user'] : '';
$tel_user = isset($_SESSION['tel_user']) ? $_SESSION['tel_user'] : '';

// Mensajes de retroalimentación para modales
$mensaje_error = isset($_SESSION['error_perfil']) ? $_SESSION['error_perfil'] : '';
$mensaje_success = isset($_SESSION['success_perfil']) ? $_SESSION['success_perfil'] : '';
$mensaje_error_password = isset($_SESSION['error_password']) ? $_SESSION['error_password'] : '';
$mensaje_success_password = isset($_SESSION['success_password']) ? $_SESSION['success_password'] : '';

// Limpiar mensajes de sesión después de leerlos
// (para que no aparezcan de nuevo al recargar)
unset($_SESSION['error_perfil']);
unset($_SESSION['success_perfil']);
unset($_SESSION['error_password']);
unset($_SESSION['success_password']);
?>
<!DOCTYPE html>
<html lang="es">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Specialized - Tienda Online</title>
    <link rel="stylesheet" href="../../styles/menu_clientes.css">
    <link rel="stylesheet" href="../../styles/validation.css">
    <script src="../JavaScript/security.js?v=1"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        /* Ocultar el ojo por defecto de Edge y navegadores basados en Chromium */
        input::-ms-reveal,
        input::-ms-clear {
            display: none !important;
        }

        /* Ocultar botones de autocompletado que puedan estorbar */
        input::-webkit-contacts-auto-fill-button,
        input::-webkit-credentials-auto-fill-button {
            visibility: hidden;
            position: absolute;
            right: 0;
        }

        .modal {
            display: none;
            position: fixed;
            z-index: 3000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            overflow: auto;
            background-color: rgba(0, 0, 0, 0.5);
            align-items: center;
            justify-content: center;
            opacity: 0;
            transition: opacity 0.3s;
        }

        .modal.show {
            opacity: 1;
        }

        .alert {
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 8px;
        }

        .alert-success {
            background-color: #d4edda;
            color: #155724;
            border: 1px solid #c3e6cb;
        }

        .alert-error {
            background-color: #f8d7da;
            color: #721c24;
            border: 1px solid #f5c6cb;
        }

        .form-group {
            margin-bottom: 20px;
        }

        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: bold;
        }

        .form-group input {
            width: 100%;
            padding: 12px;
            border: 1px solid #ddd;
            border-radius: 8px;
        }

        .modal-buttons {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
        }

        /* SVG Utils */
        .icon-svg {
            width: 20px;
            height: 20px;
            vertical-align: middle;
        }
    </style>
</head>

<body>

    <!-- ══════════════════════════════════════════════ -->
    <!-- SECCIÓN 4: BARRA DE NAVEGACIÓN SUPERIOR       -->
    <!-- ══════════════════════════════════════════════ -->
    <!-- Logo, barra de búsqueda, carrito y perfil    -->
    <nav class="navbar">
        <a href="#" class="nav-brand">
            <img src="../../images/logo central solo.png" alt="Logo" class="nav-logo">
            <span class="nav-title">Specialized</span>
        </a>

        <div class="nav-search">
            <input type="text" class="search-input" placeholder="Buscar productos...">
        </div>

        <div class="nav-controls desktop-only">
            <button class="nav-btn cart-btn">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <circle cx="9" cy="21" r="1"></circle>
                    <circle cx="20" cy="21" r="1"></circle>
                    <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
                </svg>
                <span class="cart-count">0</span>
            </button>
            <button class="nav-btn" onclick="openProfileModal()">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                    <circle cx="12" cy="7" r="4"></circle>
                </svg>
                <span style="font-size: 0.9rem;"><?php echo htmlspecialchars($nom_user); ?></span>
            </button>
            <button class="nav-btn" onclick="cerrarSesionSeguro(event)" title="Cerrar Sesión">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                    <polyline points="16 17 21 12 16 7"></polyline>
                    <line x1="21" y1="12" x2="9" y2="12"></line>
                </svg>
            </button>
        </div>

        <div class="hamburger">
            <span></span>
            <span></span>
            <span></span>
        </div>
    </nav>

    <!-- Menú móvil (se muestra con el botón hamburguesa) -->
    <div class="mobile-overlay"></div>
    <div class="mobile-menu">
        <div style="text-align: center; margin-bottom: 20px;">
            <img src="../../images/logo central solo.png" alt="Logo" style="height: 60px;">
            <h3>Hola, <?php echo htmlspecialchars($nom_user); ?></h3>
        </div>
        <a href="#" class="mobile-link" px-cart>
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none"
                stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <circle cx="9" cy="21" r="1"></circle>
                <circle cx="20" cy="21" r="1"></circle>
                <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
            </svg>
            Carrito <span class="cart-count" style="position:static; display:inline-block; margin-left:10px;">0</span>
        </a>
        <a href="#" class="mobile-link" onclick="openProfileModal(); return false;">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none"
                stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path>
                <circle cx="12" cy="7" r="4"></circle>
            </svg>
            Mi Perfil
        </a>
        <a href="#" class="mobile-link" onclick="cerrarSesionSeguro(event); return false;" style="color: #ff4757;">
            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none"
                stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path>
                <polyline points="16 17 21 12 16 7"></polyline>
                <line x1="21" y1="12" x2="9" y2="12"></line>
            </svg>
            Cerrar Sesión
        </a>
    </div>

    <!-- ══════════════════════════════════════════════ -->
    <!-- SECCIÓN 5: CATÁLOGO DE PRODUCTOS            -->
    <!-- ══════════════════════════════════════════════ -->

    <!-- Banner principal -->
    <header class="hero">
        <h1>Instrumental Dental Premium</h1>
        <p>Calidad certificada para profesionales exigentes. Encuentra todo lo que necesitas para tu consultorio.</p>
    </header>

    <!-- Filtros por categoría de producto -->
    <div class="category-tabs">
        <button class="tab-btn active" data-category="todos">Todos</button>
        <button class="tab-btn" data-category="estetica">Estética</button>
        <button class="tab-btn" data-category="esterilizacion">Esterilización</button>
        <button class="tab-btn" data-category="endodoncia">Endodoncia</button>
        <button class="tab-btn" data-category="periodoncia">Periodoncia</button>
        <button class="tab-btn" data-category="kit">Kits</button>
    </div>

    <!-- Cuadrícula de productos (llenada por JavaScript) -->
    <div class="products-container">
        <div class="grid">
            <!-- Los productos se cargan dinámicamente desde menu_cliente.js -->
        </div>
    </div>

    <!-- ══════════════════════════════════════════════ -->
    <!-- SECCIÓN 6: CARRITO DE COMPRAS (PANEL LATERAL)  -->
    <!-- ══════════════════════════════════════════════ -->
    <!-- Se desliza desde la derecha al hacer clic     -->
    <!-- en el ícono del carrito.                       -->
    <div class="cart-drawer">
        <div class="cart-header">
            <h3>Tu Carrito</h3>
            <button class="close-cart">
                <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                    <line x1="18" y1="6" x2="6" y2="18"></line>
                    <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
            </button>
        </div>
        <div class="cart-items">
            <!-- Items del carrito -->
        </div>
        <div class="cart-footer">
            <div class="cart-total">
                <span>Total:</span>
                <span class="cart-total-value">$0</span>
            </div>
            <button class="btn-checkout" onclick="alert('Funcionalidad de pago próximamente')">
                Proceder al Pago
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none"
                    stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"
                    style="vertical-align:middle; margin-left:5px;">
                    <line x1="5" y1="12" x2="19" y2="12"></line>
                    <polyline points="12 5 19 12 12 19"></polyline>
                </svg>
            </button>
        </div>
    </div>

    <!-- ══════════════════════════════════════════════ -->
    <!-- SECCIÓN 7: MODAL DE PERFIL DEL CLIENTE         -->
    <!-- ══════════════════════════════════════════════ -->
    <!-- Formulario para editar nombre, email y tel.   -->
    <div id="modalPerfil" class="modal">
        <div class="modal-content" style="background:white; width:90%; max-width:500px; padding:0;">
            <div class="modal-header" style="padding:20px; color:white;">
                <h2 style="margin:0;">Modificar Perfil</h2>
            </div>
            <div style="padding:30px;">

                <form method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>">
                    <div class="form-group">
                        <label>Nombre de Usuario</label>
                        <input type="text" name="nom_user" value="<?php echo htmlspecialchars($nom_user); ?>" required>
                    </div>
                    <div class="form-group">
                        <label>Email</label>
                        <input type="email" name="mail_user" value="<?php echo htmlspecialchars($mail_user); ?>"
                            required>
                    </div>
                    <div class="form-group">
                        <label>Teléfono</label>
                        <input type="tel" name="tel_user" value="<?php echo htmlspecialchars($tel_user); ?>" required>
                    </div>
                    <div class="modal-buttons" style="justify-content: space-between;">
                        <button type="button" class="btn-secondary" onclick="closeProfileModal(); openPasswordModal();"
                            style="padding:10px 20px; border:none; border-radius:8px; cursor:pointer; background-color: #6c757d; color: white;">
                            Cambiar Contraseña
                        </button>
                        <div style="display:flex; gap:10px;">
                            <button type="button" class="btn-secondary" onclick="closeProfileModal()"
                                style="padding:10px 20px; border:none; border-radius:8px; cursor:pointer;">Cancelar</button>
                            <button type="submit" class="btn-primary btn-shine"
                                style="cursor:pointer; color:white; border:none;">Guardar Cambios</button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- ══════════════════════════════════════════════ -->
    <!-- SECCIÓN 8: MODAL DE CAMBIO DE CONTRASEÑA      -->
    <!-- ══════════════════════════════════════════════ -->
    <div id="modalPassword" class="modal">
        <div class="modal-content" style="background:white; width:90%; max-width:500px; padding:0;">
            <div class="modal-header"
                style="padding:20px; color:white; background: linear-gradient(135deg, #36498f 0%, #087d4e 100%);">
                <h2 style="margin:0;">Cambiar Contraseña</h2>
            </div>
            <div style="padding:30px;">

                <form id="formPassword" method="POST" action="<?php echo htmlspecialchars($_SERVER['PHP_SELF']); ?>">
                    <input type="hidden" name="cambiar_password" value="1">
                    <div class="form-group">
                        <label>Contraseña Actual</label>
                        <div style="position: relative;">
                            <input type="password" name="password_actual" id="oldPassClient" required
                                autocomplete="current-password" style="padding-right: 40px;">
                            <i class="fa-solid fa-eye" onclick="togglePasswordVisibility('oldPassClient', this)"
                                style="position: absolute; right: 10px; top: 50%; transform: translateY(-50%); cursor: pointer; color: #888; z-index: 10;"></i>
                        </div>
                    </div>

                    <div class="form-group">
                        <label>Nueva Contraseña</label>
                        <div style="position: relative;">
                            <input type="password" name="password_nueva" id="newPassClient" required
                                autocomplete="new-password" minlength="8" style="padding-right: 40px;">
                            <i class="fa-solid fa-eye" onclick="togglePasswordVisibility('newPassClient', this)"
                                style="position: absolute; right: 10px; top: 50%; transform: translateY(-50%); cursor: pointer; color: #888; z-index: 10;"></i>
                        </div>
                    </div>

                    <div class="form-group">
                        <label>Confirmar Nueva Contraseña</label>
                        <div style="position: relative;">
                            <input type="password" name="password_confirmar" id="confirmPassClient" required
                                autocomplete="new-password" minlength="8" style="padding-right: 40px;">
                            <i class="fa-solid fa-eye" onclick="togglePasswordVisibility('confirmPassClient', this)"
                                style="position: absolute; right: 10px; top: 50%; transform: translateY(-50%); cursor: pointer; color: #888; z-index: 10;"></i>
                        </div>
                    </div>

                    <div class="modal-buttons"
                        style="display: flex; justify-content: flex-end; gap: 10px; margin-top: 20px;">
                        <button type="button" onclick="closePasswordModal()" class="btn-secondary"
                            style="padding:10px 20px; border:none; border-radius:8px; cursor:pointer; background:#eee; color:#333;">Cancelar</button>
                        <button type="submit" class="btn-primary"
                            style="padding:10px 20px; border:none; border-radius:8px; cursor:pointer; background:#36498f; color:white;">Cambiar
                            Contraseña</button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- ══════════════════════════════════════════════ -->
    <!-- SECCIÓN 9: SCRIPTS Y LÓGICA AUTOMÁTICA       -->
    <!-- ══════════════════════════════════════════════ -->
    <!-- SweetAlert2: Librería para mostrar alertas con diseño moderno -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <!-- Script principal del menú cliente -->
    <script src="../JavaScript/menu_cliente.js?v=<?php echo time(); ?>"></script>

    <!-- Lógica de alertas con SweetAlert2 -->
    <script>
        document.addEventListener('DOMContentLoaded', function () {
            // --- Alertas de Perfil ---
            <?php if ($mensaje_error || $mensaje_success): ?>
                <?php if ($mensaje_success): ?>
                    Swal.fire({
                        title: '¡Perfil Actualizado!',
                        text: '<?php echo $mensaje_success; ?>',
                        icon: 'success',
                        timer: 3000,
                        timerProgressBar: true,
                        confirmButtonColor: '#36498f'
                    });
                <?php else: ?>
                    Swal.fire({
                        title: 'Error de Actualización',
                        text: '<?php echo $mensaje_error; ?>',
                        icon: 'error',
                        confirmButtonColor: '#36498f'
                    }).then(() => {
                        openProfileModal();
                    });
                <?php endif; ?>
            <?php endif; ?>

            // --- Alertas de Contraseña ---
            <?php if (isset($_GET['password']) || $mensaje_error_password || $mensaje_success_password): ?>
                <?php if ($mensaje_success_password): ?>
                    Swal.fire({
                        title: '¡Contraseña Cambiada!',
                        text: '<?php echo $mensaje_success_password; ?>',
                        icon: 'success',
                        timer: 3000,
                        timerProgressBar: true,
                        confirmButtonColor: '#36498f'
                    });
                <?php elseif ($mensaje_error_password): ?>
                    Swal.fire({
                        title: 'Error en Contraseña',
                        text: '<?php echo $mensaje_error_password; ?>',
                        icon: 'error',
                        confirmButtonColor: '#36498f'
                    }).then(() => {
                        openPasswordModal();
                    });
                <?php else: ?>
                    // Apertura manual
                    openPasswordModal();
                <?php endif; ?>
            <?php endif; ?>

            // --- Limpieza de URL (PRG persistente) ---
            if (window.history.replaceState) {
                const cleanUrl = window.location.protocol + "//" + window.location.host + window.location.pathname;
                window.history.replaceState({ path: cleanUrl }, '', cleanUrl);
            }
        });

        // --- Mostrar/Ocultar Contraseña ---
        function togglePasswordVisibility(inputId, icon) {
            const input = document.getElementById(inputId);
            if (input.type === 'password') {
                input.type = 'text';
                icon.classList.remove('fa-eye');
                icon.classList.add('fa-eye-slash');
            } else {
                input.type = 'password';
                icon.classList.remove('fa-eye-slash');
                icon.classList.add('fa-eye');
            }
        }

        // --- PROTECCIÓN CONTRA NAVEGACIÓN HACIA ATRÁS ---
        window.addEventListener('pageshow', function (event) {
            if (event.persisted) {
                // Si la página se carga desde caché (botón atrás), forzar ir al login
                // Subir 2 niveles desde src/php/ para llegar a raíz
                window.location.href = '../../html/InicioSesion.html';
            }
        });
    </script>

</body>

</html>
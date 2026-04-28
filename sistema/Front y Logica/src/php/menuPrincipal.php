<?php
/**
 * ============================================================
 * PÁGINA PRINCIPAL DEL ADMINISTRADOR (VISTA)
 * ============================================================
 * 
 * PROPÓSITO:
 * Esta es la página principal que ve el administrador cuando
 * inicia sesión. Funciona como un ensamblador que une las
 * diferentes piezas de la interfaz:
 * 
 * ESTRUCTURA:
 * 1. dashboard_controller.php → Lógica y autenticación
 * 2. header.php → Cabecera HTML, estilos y librerías
 * 3. sidebar.php → Menú lateral de navegación
 * 4. [Contenido central] → Dashboard con estadísticas
 * 5. [Panel derecho] → Perfil del usuario
 * 6. footer.php → Modales, scripts y cierre de sesión
 * 
 * PATRÓN MVC:
 * - Modelo: querys.php (datos)
 * - Vista: este archivo + includes/ (interfaz)
 * - Controlador: dashboard_controller.php (lógica)
 * ============================================================
 */

// Cargar la lógica del controlador (autenticación, datos, etc.)
require_once "controllers/dashboard_controller.php";

// Incluir la cabecera HTML (estilos, metadatos)
include_once "includes/header.php";

// Incluir el menú lateral de navegación
include_once "includes/sidebar.php";
?>

<!-- ══════════════════════════════════════════════ -->
<!-- SECCIÓN CENTRAL: PANEL DE ADMINISTRACIÓN      -->
<!-- ══════════════════════════════════════════════ -->
<!-- Contiene el dashboard con tarjetas de         -->
<!-- estadísticas y el contenedor para vistas       -->
<!-- dinámicas (instrumental, materia prima, etc.)  -->
<section class="a2">
    <!-- Vista del Dashboard (visible por defecto) -->
    <div id="dashboard-view">
        <div class="header-inventario">
            <h1 data-i18n="dashboard.title">Panel de Administración</h1>
            <p data-i18n="dashboard.subtitle">Sistema de gestión de instrumental dental especializado</p>
        </div>

        <!-- Bienvenida personalizada con el nombre del usuario -->
        <div class="dashboard-intro">
            <div class="intro-content">
                <h2><span data-i18n="dashboard.welcome">Bienvenido</span>, <?php echo htmlspecialchars($nom_user); ?>!</h2>
                <p data-i18n="dashboard.intro">Aquí tienes un resumen de la actividad de tu plataforma. Los datos se actualizan en tiempo real desde la base de datos.</p>
            </div>
        </div>

        <!-- ─── TARJETAS DE ESTADÍSTICAS ─── -->
        <!-- Cada tarjeta muestra un número del dashboard -->
        <!-- Al hacer clic, abre el modal de gestión correspondiente -->
        <div class="dashboard-analytics">
            <div class="analytics-grid">
                <div class="stat-card stat-card-primary" onclick="abrirGestion('usuarios')" style="cursor: pointer;">
                    <div class="stat-icon"><i class="fa-solid fa-users"></i></div>
                    <div class="stat-info">
                        <span class="stat-label" data-i18n="dashboard.stats.total_users">Total Usuarios</span>
                        <span class="stat-value"><?php echo $stats['total_usuarios']; ?></span>
                    </div>
                </div>
                <div class="stat-card stat-card-success" onclick="abrirGestion('nuevos_mes')" style="cursor: pointer;">
                    <div class="stat-icon"><i class="fa-solid fa-user-plus"></i></div>
                    <div class="stat-info">
                        <span class="stat-label" data-i18n="dashboard.stats.new_users">Nuevos este mes</span>
                        <span class="stat-value"><?php echo $stats['usuarios_mes']; ?></span>
                    </div>
                </div>
                <div class="stat-card stat-card-warning" onclick="abrirGestion('empleados')">
                    <div class="stat-icon"><i class="fa-solid fa-user-shield"></i></div>
                    <div class="stat-info">
                        <span class="stat-label" data-i18n="dashboard.stats.employees">Empleados</span>
                        <span class="stat-value"><?php echo $stats['empleados']; ?></span>
                    </div>
                </div>
                <div class="stat-card stat-card-info" onclick="abrirGestion('clientes')">
                    <div class="stat-icon"><i class="fa-solid fa-user-check"></i></div>
                    <div class="stat-info">
                        <span class="stat-label" data-i18n="dashboard.stats.clients">Clientes</span>
                        <span class="stat-value"><?php echo $stats['clientes']; ?></span>
                    </div>
                </div>
                <!-- Tarjeta: Proveedores registrados -->
                <div class="stat-card stat-card-secondary" onclick="abrirGestion('proveedores')">
                    <div class="stat-icon"><i class="fa-solid fa-truck"></i></div>
                    <div class="stat-info">
                        <span class="stat-label" data-i18n="dashboard.stats.providers">Proveedores</span>
                        <span class="stat-value"><?php echo $stats['proveedores']; ?></span>
                    </div>
                </div>
            </div>

            <!-- Tarjetas secundarias (más grandes, con detalle) -->
            <div class="analytics-secondary">
                <div class="stat-card stat-card-large" id="card-dashboard-productos" style="cursor: pointer;">
                    <div class="stat-icon"><i class="fa-solid fa-boxes-stacked"></i></div>
                    <div class="stat-info">
                        <span class="stat-label" data-i18n="dashboard.stats.products">Productos en inventario</span>
                        <div class="stat-main">
                            <span class="stat-value"><?php echo $stats['total_productos'] ?: '0'; ?></span>
                        </div>
                        <span class="stat-hint">
                            <span data-i18n="dashboard.stats.instruments">Instrumentos</span>: <?php echo $stats['instrumentos']; ?> | 
                            <span data-i18n="dashboard.stats.kits">Kits</span>: <?php echo $stats['kits']; ?>
                        </span>
                    </div>
                </div>
                <div class="stat-card stat-card-large">
                    <div class="stat-icon"><i class="fa-solid fa-chart-line"></i></div>
                    <div class="stat-info">
                        <span class="stat-label" data-i18n="dashboard.stats.top_sale">Mayor venta</span>
                        <span class="stat-value"><?php echo $stats['mayor_venta'] ?? '—'; ?></span>
                        <span class="stat-hint" data-i18n="dashboard.stats.requires_sales_table">Requiere tabla de ventas</span>
                    </div>
                </div>
                <div class="stat-card stat-card-large">
                    <div class="stat-icon"><i class="fa-solid fa-chart-column"></i></div>
                    <div class="stat-info">
                        <span class="stat-label" data-i18n="dashboard.stats.low_stock">Menor producto en stock</span>
                        <span class="stat-value" style="font-size: 1.2rem;"><?php echo $stats['menor_producto'] ?? '—'; ?></span>
                        <span class="stat-hint" data-i18n="dashboard.stats.requires_inventory_table">Requiere tabla de inventario</span>
                    </div>
                </div>
            </div>

        </div>
    </div>

    <!-- Contenedor para vistas dinámicas -->
    <!-- Se muestra cuando el usuario navega a instrumental, -->
    <!-- materia prima, historial, etc. desde el menú lateral -->
    <div id="dynamic-view" style="display:none; width: 100%; height: 100%;"></div>

    <!-- Controles de inventario (para futuras funcionalidades) -->

</section>

<!-- ══════════════════════════════════════════════ -->
<!-- SECCIÓN DERECHA: PERFIL DEL USUARIO            -->
<!-- ══════════════════════════════════════════════ -->
<!-- Panel lateral con datos del usuario logueado, -->
<!-- menú de opciones y estadísticas de venta.     -->

<!-- Botón hamburguesa para mostrar perfil en móviles -->
<button id="mobileProfileBtn" class="mobile-profile-btn">
    <i class="fa-solid fa-bars"></i>
</button>
<section class="a3">
    <div class="perfil">
        <!-- Información básica del usuario -->
        <div class="perfil-header">
            <div class="imagenPerfil">
                <i class="fa-solid fa-user"></i>
            </div>
            <h2 class="nombrePerfil"><?php echo htmlspecialchars($nom_user); ?></h2>
            <p class="rol-usuario"><?php echo htmlspecialchars($rol_usuario); ?></p>
        </div>

        <!-- Menú de opciones del perfil -->
        <div class="menu-perfil">
            <a href="#" class="opcion-perfil" onclick="abrirModalPerfil()">
                <i class="fa-solid fa-user-edit"></i>
                <span>Modificar Perfil</span>
            </a>

            <a href="#" class="opcion-perfil" onclick="abrirModalPassword()">
                <i class="fa-solid fa-key"></i>
                <span>Cambiar Contraseña</span>
            </a>

            <a href="#" class="opcion-perfil" onclick="abrirModalNotificaciones()">
                <i class="fa-solid fa-bell"></i>
                <span>Notificaciones</span>
                <?php if ($stats['criticos'] > 0): ?>
                    <span class="badge-notif"><?php echo $stats['criticos']; ?></span>
                <?php endif; ?>
            </a>

            <a href="#" class="opcion-perfil" onclick="abrirModalAccesibilidad()">
                <i class="fa-solid fa-universal-access"></i>
                <span data-i18n="menu.settings">Accesibilidad</span>
            </a>

            <!-- Exportar Datos Eliminado -->

            <a href="#" class="opcion-perfil" onclick="abrirModalSoporte()">
                <i class="fa-solid fa-circle-question"></i>
                <span>Ayuda y Soporte</span>
            </a>

            <a href="#" class="opcion-perfil cerrar-sesion" onclick="cerrarSesionSeguro(event)">
                <i class="fa-solid fa-sign-out-alt"></i>
                <span>Cerrar Sesión</span>
            </a>
        </div>

        <!-- Estadísticas de venta (resumen rápido) -->
        <div class="estadisticas-perfil">
            <h3>Estadísticas de Venta</h3>
            <div class="stat-item">
                <span>Total Ventas:</span>
                <span class="stat-valor" id="sidebar-total-ventas">$<?php echo number_format($stats['total_ventas'], 0, ',', '.'); ?></span>
            </div>
            <div class="stat-item">
                <span>Ventas Diarias:</span>
                <span class="stat-valor" id="sidebar-ventas-diarias">$<?php echo number_format($stats['ventas_diarias'], 0, ',', '.'); ?></span>
            </div>
            <div class="stat-item">
                <span>Productos:</span>
                <span class="stat-valor" id="sidebar-total-productos"><?php echo $stats['total_productos'] ?: '0'; ?></span>
            </div>
        </div>
    </div>
</section>

<?php
// Incluir footer (modales, scripts, cierre de sesión)
include_once "includes/footer.php";
?>
<!-- Scripts adicionales específicos de esta página -->
<script src="../JavaScript/bodega_produccion.js?v=<?php echo time(); ?>&r=1"></script>

<script>
    // Manejo de la redirección desde la tarjeta del dashboard
    document.addEventListener('DOMContentLoaded', function() {
        const prodCard = document.getElementById('card-dashboard-productos');
        if (prodCard) {
            prodCard.addEventListener('click', function() {
                const btnProductos = document.getElementById('btn-productos');
                if (btnProductos) {
                    btnProductos.click();
                }
            });
        }
    });
</script>
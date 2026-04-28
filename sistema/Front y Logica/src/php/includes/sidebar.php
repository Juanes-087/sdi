<?php
/**
 * ============================================================
 * BARRA LATERAL DE NAVEGACIÓN (SIDEBAR - CLIENTE)
 * ============================================================
 * 
 * PROPÓSITO:
 * Menú de navegación izquierdo para la vista del CLIENTE.
 * Se incluye automáticamente en menuCliente.php.
 * 
 * SECCIONES DEL MENÚ:
 * 1. Instrumental → Catálogo de instrumentos médicos
 * 2. Materia Prima → Vista de materias primas disponibles
 * 3. Historial → Registro de movimientos del cliente
 * 4. Nosotros → Información de la empresa
 * 
 * NOTA: Cada botón del menú activa una vista diferente
 * mediante JavaScript (navegación sin recargar la página).
 * ============================================================
 */
?>

<!-- ══════════════════════════════════════════════ -->
<!-- SECCIÓN IZQUIERDA - MENÚ DE NAVEGACIÓN       -->
<!-- ══════════════════════════════════════════════ -->
<section class="a1">
    <div class="contenedor_menus">

        <!-- Logo y nombre del sistema -->
        <div class="logo">
            <div class="imagen_logo">SDI</div>
            <label class="texto_logo">
                <h1>SDI</h1>
            </label>
        </div>

        <!-- Botón: Instrumental (catálogo de instrumentos) -->
        <a href="#instrumental" id="btn-instrumental">
            <div class="menu">
                <h2 class="instrumental">Instrumental</h2>
                <i class="fa-solid fa-tools fa-xl" style="color: #868788;"></i>
            </div>
        </a>

        <!-- Botón: Materia Prima (vista de materiales) -->
        <a href="#materia-prima" id="btn-materia-prima">
            <div class="menu">
                <h2 class="materiaPrima">Materia Prima</h2>
                <i class="fa-solid fa-cube fa-xl" style="color: #868788;"></i>
            </div>
        </a>

        <!-- Botón: Productos (Gestión de ventas) -->
        <a href="#productos" id="btn-productos">
            <div class="menu">
                <h2 class="productos">Productos</h2>
                <i class="fa-solid fa-boxes-stacked fa-xl" style="color: #868788;"></i>
            </div>
        </a>

        <!-- Botón: Finanzas (Métricas y Reportes) -->
        <a href="#finanzas" id="btn-finanzas">
            <div class="menu">
                <h2 class="finanzas">Finanzas</h2>
                <i class="fa-solid fa-chart-line fa-xl" style="color: #868788;"></i>
            </div>
        </a>

        <!-- Botón: Historial (movimientos registrados) -->
        <a href="#historial" id="btn-historial">
            <div class="menu">
                <h2 class="historial">Historial</h2>
                <i class="fa-solid fa-clock-rotate-left fa-xl" style="color: #868788;"></i>
            </div>
        </a>


        <!-- Eslogan de la empresa -->
        <div class="slogan">
            <h1 class="slogan_texto">Instrumental al alcance de tú mano</h1>
        </div>
    </div>
</section>
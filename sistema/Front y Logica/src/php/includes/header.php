<?php
/**
 * ============================================================
 * CABECERA HTML (INCLUDE)
 * ============================================================
 * 
 * PROPÓSITO:
 * Define la parte superior del documento HTML que se repite
 * en todas las páginas del panel de administración.
 * Se incluye automáticamente en menuPrincipal.php y otras vistas.
 * 
 * CONTIENE:
 * - Metadatos del documento (charset, viewport)
 * - Título de la página y favicon (ícono en la pestaña)
 * - Hojas de estilo CSS del panel de administración
 * - Librería de íconos Font Awesome (para botones y menús)
 * - SweetAlert2 (librería para alertas bonitas)
 * 
 * NOTA: El parámetro ?v=<?php echo time(); ?> en los CSS
 * evita que el navegador use versiones en caché (cache busting).
 * ============================================================
 */
?>
<!DOCTYPE html>
<html lang="en">

<head>
    <!-- Configuración básica del documento -->
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard SDI</title>

    <!-- Ícono que aparece en la pestaña del navegador -->
    <link rel="icon" href="../../images/logo central solo.png" type="image/png">

    <!-- Estilos del panel de administración (con cache busting) -->
    <link rel="stylesheet" href="../../styles/estilos_menuPrincipal.css?v=<?php echo time(); ?>">
    <link rel="stylesheet" href="../../styles/validation.css">

    <!-- Librería de seguridad y anti-debugging -->
    <script src="../JavaScript/security.js?v=1"></script>
    <script src="../JavaScript/activity_tracker.js?v=1"></script>

    <!-- Librería de íconos (flechas, botones, menús, etc.) -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">

    <!-- SweetAlert2: Librería para mostrar alertas con diseño moderno -->
    <script src="https://cdn.jsdelivr.net/npm/sweetalert2@11"></script>

    <!-- SheetJS: Librería para exportación a Excel -->
    <script src="https://cdn.jsdelivr.net/npm/xlsx@0.18.5/dist/xlsx.full.min.js"></script>

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
    </style>
</head>

<!-- Inicio del cuerpo de la página -->

<body>
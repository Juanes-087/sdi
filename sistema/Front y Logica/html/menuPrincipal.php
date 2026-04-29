<?php
/**
 * Redirección a menuPrincipal.php en carpeta php/
 * Mantiene compatibilidad con rutas antiguas usando redirección HTTP
 */
header("Location: ../src/php/menuPrincipal.php");
exit;

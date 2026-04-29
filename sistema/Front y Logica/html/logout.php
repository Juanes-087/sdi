<?php
/**
 * Redirección a logout.php en carpeta php/
 * Para cuando el cierre de sesión se llama desde html/menuPrincipal.php
 */
header("Location: ../src/php/logout.php");
exit;

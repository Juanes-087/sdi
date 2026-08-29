<?php
/**
 * API DE ESPECIALIZACIONES / CATEGORÍAS
 * Devuelve el listado de especializaciones odontológicas activas
 */
header('Content-Type: application/json');
require_once __DIR__ . '/querys.php';

try {
    $db = new CQuerys();
    $categorias = $db->getEspecializaciones();
    echo json_encode([
        'success' => true,
        'data' => $categorias
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>

<?php
/**
 * API DE PRODUCTOS MÁS VENDIDOS
 * 
 * Devuelve los 5 productos con mayor volumen de ventas
 * para ser mostrados en el carrusel de la landing page.
 */
header('Content-Type: application/json');
require_once __DIR__ . '/querys.php';

try {
    $db = new CQuerys();
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 5;
    
    $resultados = $db->getTopVendidos($limit);
    
    echo json_encode([
        'success' => true,
        'data' => $resultados
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>

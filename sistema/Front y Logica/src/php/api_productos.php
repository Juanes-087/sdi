<?php
/**
 * ============================================================
 * API DE BÚSQUEDA DE PRODUCTOS
 * ============================================================
 * 
 * PROPÓSITO:
 * Endpoint dedicado exclusivamente a buscar productos en el
 * catálogo de la tienda. Es usado por la página de compras
 * del cliente para filtrar instrumentos y kits disponibles.
 * 
 * FUNCIONAMIENTO:
 * 1. Recibe un parámetro de búsqueda 'q' por la URL
 *    Ejemplo: api_productos.php?q=bisturí
 * 2. Llama a la función SQL fun_buscar_productos()
 * 3. Devuelve los resultados en formato JSON
 * 
 * SEGURIDAD:
 * - No requiere autenticación (catálogo público)
 * - La búsqueda usa sentencias preparadas (anti SQL injection)
 * ============================================================
 */
header('Content-Type: application/json');
require_once __DIR__ . '/querys.php';

try {
    $db = new CQuerys();

    // Obtener el término de búsqueda del parámetro 'q'
    // Si no se envía, se devuelven todos los productos
    $q = isset($_GET['q']) ? trim($_GET['q']) : '';

    // Ejecutar la búsqueda a través de la clase CQuerys
    // que internamente llama a la función SQL fun_buscar_productos
    $resultados = $db->buscarProductos($q);

    echo json_encode($resultados);

} catch (Exception $e) {
    // En caso de error, devolver código 500 con mensaje
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}
?>
<?php
/**
 * API PÚBLICA DE INFORMACIÓN DE EMPRESA Y PARÁMETROS
 * Devuelve el registro INVIMA y datos de contacto de la empresa
 */
header('Content-Type: application/json');
header("Cache-Control: public, max-age=300"); // Cache de 5 min para optimizar

require_once __DIR__ . '/querys.php';

try {
    $db = new CQuerys();
    $info = $db->getInfoEmpresaPublica();

    if ($info) {
        echo json_encode([
            'success' => true,
            'data' => $info
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'error' => 'No se encontraron parámetros de la empresa'
        ]);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>

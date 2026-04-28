<?php
require_once __DIR__ . '/../querys.php';

// Endpoint para proveer los datos de la tabla Bodega en JSON o HTML HTML
if (isset($_GET['action'])) {
    
    $querys = new CQuerys();
    
    // Devolver lista de insumos en bodega
    if ($_GET['action'] === 'get_bodega') {
        try {
            $bodega = $querys->getBodega();
            echo json_encode(['status' => 'success', 'data' => $bodega]);
        } catch (Exception $e) {
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
        exit;
    }
    
    // Devolver lista de insumos en produccion
    if ($_GET['action'] === 'get_produccion') {
        try {
            $produccion = $querys->getProduccion();
            echo json_encode(['status' => 'success', 'data' => $produccion]);
        } catch (Exception $e) {
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
        exit;
    }

    // Devolver historial de fabricación de instrumentos
    if ($_GET['action'] === 'get_kardex_instrumentos') {
        try {
            $kardex_inst = $querys->getKardexInstrumentos();
            echo json_encode(['status' => 'success', 'data' => $kardex_inst]);
        } catch (Exception $e) {
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
        exit;
    }

    // Devolver historial de ensamblaje de kits
    if ($_GET['action'] === 'get_kardex_kits') {
        try {
            $kardex_kits = $querys->getKardexKits();
            echo json_encode(['status' => 'success', 'data' => $kardex_kits]);
        } catch (Exception $e) {
            echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
        }
        exit;
    }
    
}
?>

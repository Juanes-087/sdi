<?php
/**
 * ============================================================
 * API DE GESTIÓN ADMINISTRATIVA (ENRUTADOR REFACCIONADO)
 * ============================================================
 * 
 * PROPÓSITO:
 * Archivo central que ahora invoca los controladores por módulo.
 */
include_once("security_headers.php");
include_once("querys.php");
include_once("jwt.php");

include_once __DIR__ . "/controllers/api_dashboard_controller.php";
include_once __DIR__ . "/controllers/api_instrumental_controller.php";
include_once __DIR__ . "/controllers/api_mat_prim_controller.php";
include_once __DIR__ . "/controllers/api_productos_controller.php";
include_once __DIR__ . "/controllers/api_historial_controller.php";

header('Content-Type: application/json');
header("Cache-Control: no-store, no-cache, must-revalidate, max-age=0");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");
header("Expires: Sat, 26 Jul 1997 05:00:00 GMT");

if ($_SERVER['REQUEST_METHOD'] !== 'GET' && $_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['error' => 'Método no permitido']);
    exit;
}

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}
if (!isset($_SESSION['id_usuario'])) {
    http_response_code(401);
    echo json_encode(['error' => 'No autorizado']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    if (!isset($_SESSION['id_menu']) || $_SESSION['id_menu'] != 1) {
        http_response_code(403);
        echo json_encode([
            'error' => 'Acceso denegado: No tienes permisos de administrador.',
            'debug_role' => $_SESSION['id_menu'] ?? 'null'
        ]);
        exit;
    }
}

$db = new CQuerys();
$conn = $db->getConn();

// ══════════════════════════════════════════════════════════════
// SECCIÓN A: CONSULTAS (GET)
// ══════════════════════════════════════════════════════════════
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $tipo = $_GET['tipo'] ?? '';
    $id = $_GET['id'] ?? 0;

    try {
        ApiDashboardController::handleGet($db, $tipo);
        ApiInstrumentalController::handleGet($db, $tipo, $id);
        ApiMatPrimController::handleGet($db, $tipo, $id);
        ApiProductosController::handleGet($db, $tipo, $id);
        ApiHistorialController::handleGet($db, $tipo, $id);

        echo json_encode(['error' => 'Tipo de dato (GET) no válido o no encontrado: ' . $tipo]);
        exit;
    } catch (Throwable $e) {
        http_response_code(500);
        echo json_encode(['error' => 'Error del Servidor: ' . $e->getMessage()]);
        exit;
    }
}

// ══════════════════════════════════════════════════════════════
// SECCIÓN B: OPERACIONES DE ESCRITURA (POST)
// ══════════════════════════════════════════════════════════════
elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $parsedInput = [];
    $accion = '';
    $tipo = '';
    $id = null;

    if (!empty($_FILES) || !empty($_POST)) {
        $accion = $_POST['accion'] ?? '';
        $tipo = $_POST['tipo'] ?? '';
        $id = $_POST['id'] ?? null;
        if ($id === 'null' || $id === 'undefined')
            $id = null;

        $parsedInput = json_decode($_POST['data'] ?? '{}', true);

        if (isset($_FILES['img_url']) && $_FILES['img_url']['error'] === UPLOAD_ERR_OK) {
            $subFolder = 'instrum';
            if ($tipo === 'kits')
                $subFolder = 'kit';
            if ($tipo === 'productos')
                $subFolder = 'prod';
            if ($tipo === 'materias_primas')
                $subFolder = 'mat_prima';

            $uploadDir = __DIR__ . '/../../images/' . $subFolder . '/';
            if (!file_exists($uploadDir))
                mkdir($uploadDir, 0777, true);

            $fileTmpPath = $_FILES['img_url']['tmp_name'];
            $fileName = $_FILES['img_url']['name'];
            $fileNameCmps = explode(".", $fileName);
            $fileExtension = strtolower(end($fileNameCmps));

            $allowedfileExtensions = array('jpg', 'png', 'jpeg');
            if (in_array($fileExtension, $allowedfileExtensions)) {
                $newFileName = md5(time() . $fileName) . '.' . $fileExtension;
                $dest_path = $uploadDir . $newFileName;
                if (move_uploaded_file($fileTmpPath, $dest_path)) {
                    $parsedInput['img_url'] = '../../images/' . $subFolder . '/' . $newFileName;
                } else {
                    echo json_encode(['error' => 'Error al mover imagen al destino.']);
                    exit;
                }
            } else {
                echo json_encode(['error' => 'Tipo de archivo no permitido. Solo JPG y PNG.']);
                exit;
            }
        }
    } else {
        $contentLength = $_SERVER['CONTENT_LENGTH'] ?? 0;
        $contentType = $_SERVER['CONTENT_TYPE'] ?? '';

        if (empty($_POST) && empty($_FILES) && $contentLength > 0 && stripos($contentType, 'multipart/form-data') !== false) {
            http_response_code(413);
            echo json_encode(['error' => 'El archivo es demasiado grande (Excede post_max_size).']);
            exit;
        }

        if (stripos($contentType, 'multipart/form-data') !== false) {
            $parsedInput = [];
        } else {
            $rawInput = json_decode(file_get_contents('php://input'), true);
            $accion = $rawInput['accion'] ?? '';
            $tipo = $rawInput['tipo'] ?? '';
            $id = $rawInput['id'] ?? null;
            $parsedInput = $rawInput['data'] ?? [];
        }
    }

    $data = $parsedInput;
    if (empty($tipo)) {
        http_response_code(400);
        echo json_encode(['error' => 'Tipo no especificado']);
        exit;
    }

    try {
        $conn->beginTransaction();

        switch ($accion) {
            case 'create':
                // Redirigir la creación a Kardex si es específico
                $res = ApiHistorialController::handleCreate($db, $tipo, $data);

                if ($res === false)
                    $res = ApiDashboardController::handleCreate($db, $tipo, $data);
                if ($res === false)
                    $res = ApiInstrumentalController::handleCreate($db, $tipo, $data, $parsedInput);
                if ($res === false)
                    $res = ApiMatPrimController::handleCreate($db, $tipo, $data);

                if ($res === false) {
                    throw new Exception("Tipo de registro no soportado o método de creación no encontrado para: " . $tipo);
                }

                if ((isset($res['result']) && ($res['result'] === false || $res['result'] === 'f' || $res['result'] === 0 || $res['result'] === '0'))) {
                    throw new Exception("Error al crear registro: La base de datos retornó falso.");
                }

                echo json_encode(['success' => true, 'message' => 'Creado correctamente', 'data' => $res]);
                break;

            case 'update':
                if (!$id)
                    throw new Exception("ID requerido para actualizar");

                // Estos endpoints manejan su propia operación SQL final y hacen commit + exit;
                ApiInstrumentalController::handleUpdate($db, $tipo, $id, $data, $conn);
                ApiMatPrimController::handleUpdate($db, $tipo, $id, $data, $conn);
                $histRes = ApiHistorialController::handleUpdate($db, $tipo, $id, $data);
                if ($histRes !== false) {
                    echo json_encode(['success' => true, 'message' => 'Devolución resuelta', 'result' => $histRes]);
                    $conn->commit();
                    exit;
                }

                // Si no fue instrumental o mat_prim, es dashboard u otro genérico.
                $updateRes = ApiDashboardController::handleUpdate($db, $tipo, $id, $data);

                if (is_array($updateRes) && isset($updateRes['done'])) {
                    if ($updateRes['done'] === true) {
                        $conn->commit();
                        echo json_encode(['success' => true, 'message' => $updateRes['message']]);
                        exit;
                    } else if (isset($updateRes['table']) && !empty($updateRes['updateData'])) {
                        $db->updateGeneric($updateRes['table'], $updateRes['updateData'], $updateRes['idField'], $id, $_SESSION['nom_user']);
                        echo json_encode(['success' => true, 'message' => 'Registro actualizado genéricamente']);
                        $conn->commit();
                        exit;
                    }
                }

                throw new Exception("Tipo de actualización no reconocido o no hay datos a actualizar.");

            case 'delete':
                if (!$id)
                    throw new Exception("ID requerido para eliminar");

                // Verificaciones preventivas antes del delete genérico
                ApiInstrumentalController::handleDelete($db, $conn, $tipo, $id);
                ApiDashboardController::handleDelete($db, $conn, $tipo, $id);
                ApiMatPrimController::handleDelete($db, $conn, $tipo, $id);
                ApiProductosController::handleDelete($db, $conn, $tipo, $id);

                // Si ninguna validación tiro throw Exception, procedemos con soft delete
                $res = $db->deleteGeneric($tipo, $id);

                while (ob_get_level())
                    ob_end_clean();

                if ($res === false || (isset($res['result']) && ($res['result'] === false || $res['result'] === 'f' || $res['result'] === 0 || $res['result'] === '0'))) {
                    throw new Exception("Error al eliminar: La base de datos no pudo completar la operación (Verifique dependencias o estado).");
                } else {
                    echo json_encode(['success' => true, 'message' => 'Eliminado correctamente']);
                }
                break;

            case 'restore':
                if (!$id)
                    throw new Exception("ID requerido para restaurar");

                $res = ApiProductosController::handleRestore($db, $tipo, $id);
                if ($res === false)
                    $res = ApiMatPrimController::handleRestore($db, $tipo, $id);
                if ($res === false)
                    $res = ApiDashboardController::handleRestore($db, $tipo, $id);

                while (ob_get_level())
                    ob_end_clean();

                if (isset($res['success']) && $res['success'] === true) {
                    echo json_encode(['success' => true, 'message' => 'Restaurado correctamente']);
                } else {
                    throw new Exception($res['error'] ?? "Error al restaurar: La base de datos no pudo completar la operación.");
                }
                break;

            default:
                throw new Exception("Acción no reconocida: " . $accion);
        }

        $conn->commit();

    } catch (Exception $e) {
        $conn->rollBack();
        http_response_code(500);
        $msg = $e->getMessage();

        if (preg_match('/ERROR:\s*(.+?)(\n|$)/', $msg, $matches)) {
            $msg = $matches[1];
        } else {
            $msg = preg_replace('/SQLSTATE\[\w+\]:.*?ERROR:\s*/', '', $msg);
        }
        echo json_encode(['error' => 'Error en la operación: ' . $msg]);
    }
}
?>
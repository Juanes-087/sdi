<?php
class ApiInstrumentalController
{
    public static function handleGet($db, $tipo, $id)
    {
        $soloHabilitados = (isset($_GET['estado']) && $_GET['estado'] === 'false') ? false : true;

        if ($tipo === 'instrumentos') {
            $data = $db->getInstrumentos($soloHabilitados);
            echo json_encode([
                'data' => $data,
                'columns' => [
                    ['key' => 'id_instrumento', 'label' => 'ID'],
                    ['key' => 'nom_instrumento', 'label' => 'Instrumento'],
                    ['key' => 'especializacion', 'label' => 'Especialización'],
                    ['key' => 'cant_disp', 'label' => 'Cantidad'],
                    ['key' => 'lote', 'label' => 'Lote']
                ]
            ]);
            exit;
        } else if ($tipo === 'kits') {
            $data = $db->getKits($soloHabilitados);
            echo json_encode([
                'data' => $data,
                'columns' => [
                    ['key' => 'id_kit', 'label' => 'ID'],
                    ['key' => 'nom_kit', 'label' => 'Nombre Kit'],
                    ['key' => 'nom_espec', 'label' => 'Especialización'],
                    ['key' => 'cant_disp', 'label' => 'Cantidad'],
                    ['key' => 'stock_min', 'label' => 'Min'],
                    ['key' => 'stock_max', 'label' => 'Max']
                ]
            ]);
            exit;
        } else if ($tipo === 'kit_instruments') {
            $data = $db->getInstrumentsByKit($id);
            echo json_encode(['data' => $data]);
            exit;
        }
        return false;
    }

    public static function handleCreate($db, $tipo, $data, $parsedInput)
    {
        if ($tipo === 'instrumentos') {
            $valEspec = $data['id_especializacion'] ?? $data['nom_especializacion'] ?? '';
            $data['id_especializacion'] = $db->getIdByName('tab_tipo_especializacion', 'id_especializacion', 'nom_espec', $valEspec);

            if (!$data['id_especializacion'])
                throw new Exception("Especialización inválida: " . $valEspec);

            $res = $db->insertInstrumento($data);
            return $res;
        } else if ($tipo === 'kits') {
            $valEspec = $data['id_especializacion'] ?? $data['nom_especializacion'] ?? $data['nom_espec'] ?? '';
            $data['id_especializacion'] = $db->getIdByName('tab_tipo_especializacion', 'id_especializacion', 'nom_espec', $valEspec);

            if (!$data['id_especializacion']) {
                throw new Exception("Especialización inválida: " . $valEspec);
            }

            if (isset($parsedInput['instruments']) && is_array($parsedInput['instruments'])) {
                $data['instruments'] = $parsedInput['instruments'];
            } else {
                $data['instruments'] = [];
            }

            $res = $db->insertKit($data);
            return $res;
        }
        return false;
    }

    public static function handleUpdate($db, $tipo, $id, $data, $conn)
    {
        if ($tipo === 'instrumentos') {
            if (isset($data['nom_especializacion'])) {
                $data['id_especializacion'] = $db->getIdByName('tab_tipo_especializacion', 'id_especializacion', 'nom_espec', $data['nom_especializacion']);
                if (!$data['id_especializacion'])
                    throw new Exception("Especialización inválida");
            }
            $res = $db->updateInstrumento($id, $data);
            if ($res === false || (isset($res['result']) && ($res['result'] === false || $res['result'] === 'f' || $res['result'] === 0))) {
                throw new Exception("Error al actualizar instrumento (Validación BD)");
            }
            echo json_encode(['success' => true, 'message' => 'Instrumento actualizado']);
            $conn->commit();
            exit;
        } else if ($tipo === 'kits') {
            if (isset($data['nom_especializacion'])) {
                $data['id_especializacion'] = $db->getIdByName('tab_tipo_especializacion', 'id_especializacion', 'nom_espec', $data['nom_especializacion']);
                if (!$data['id_especializacion'])
                    throw new Exception("Especialización inválida");
            }
            $res = $db->updateKit($id, $data);
            if ($res === false || (isset($res['result']) && ($res['result'] === false || $res['result'] === 'f' || $res['result'] === 0))) {
                throw new Exception("Error al actualizar kit (Validación BD)");
            }
            echo json_encode(['success' => true, 'message' => 'Kit actualizado']);
            $conn->commit();
            exit;
        }
        return false; // Not handled
    }

    /**
     * MÉTODO: handleDelete
     * PROPÓSITO: Valida si un Instrumento o Kit puede ser inhabilitado según sus dependencias activas.
     * DISPARADOR: Se ejecuta automáticamente en cada intento de borrado desde api_gestion.php.
     * FLUJO: 
     *   1. Si es instrumento, verifica que no esté en un Kit o Producto vigente.
     *   2. Si es kit, verifica que no tenga instrumentos dentro ni esté en un Producto vigente.
     * LLAMADO DESDE: api_gestion.php -> Sección B (Petición POST) -> ApiInstrumentalController::handleDelete
     */
    public static function handleDelete($db, $conn, $tipo, $id)
    {
        if ($tipo === 'instrumentos') {
            // 1. Verificar si el instrumento pertenece a algún Kit activo
            $depStmt = $conn->prepare("SELECT 1 FROM tab_instrumentos_kit WHERE id_instrumento = :id LIMIT 1");
            // .execute -> Verifica la existencia física en la tabla de relación Kit-Instrumento
            $depStmt->execute([':id' => $id]);
            if ($depStmt->fetch())
                throw new Exception("No se puede eliminar: El instrumento pertenece a uno o más kits.");

            // 2. Verificar si el instrumento está vinculado a un Producto de Venta activo
            $depStmt = $conn->prepare("SELECT 1 FROM tab_productos WHERE id_instrumento = :id LIMIT 1");
            $depStmt->execute([':id' => $id]);
            if ($depStmt->fetch())
                throw new Exception("No se puede eliminar: El instrumento está vinculado a un producto de venta.");

            // NOTA: Se eliminó la restricción de Kardex histórico para permitir inhabilitar instrumentos
            // que ya no se usan pero que tienen movimientos antiguos registrados.

        } else if ($tipo === 'kits') {
            // 1. Verificar si tiene instrumentos asociados
            $depStmt = $conn->prepare("SELECT 1 FROM tab_instrumentos_kit WHERE id_kit = :id LIMIT 1");
            $depStmt->execute([':id' => $id]);
            if ($depStmt->fetch())
                throw new Exception("No se puede eliminar: El kit tiene instrumentos asociados.");

            // 2. Verificar si está en productos de venta
            $depStmt = $conn->prepare("SELECT 1 FROM tab_productos WHERE id_kit = :id LIMIT 1");
            $depStmt->execute([':id' => $id]);
            if ($depStmt->fetch())
                throw new Exception("No se puede eliminar: El kit está vinculado a un producto de venta.");

            return true;
        }
        return false; // Let generic delete continue or handle elsewhere
    }
}
?>
<?php
class ApiMatPrimController
{
    public static function handleGet($db, $tipo, $id)
    {
        $soloHabilitados = (isset($_GET['estado']) && $_GET['estado'] === 'false') ? false : true;

        if ($tipo === 'categorias_materia') {
            $data = $db->getCategoriesMateriaPrima($soloHabilitados);
            echo json_encode([
                'data' => $data,
                'columns' => [
                    ['key' => 'id_cat_mat', 'label' => 'ID'],
                    ['key' => 'nom_categoria', 'label' => 'Nombre Categoría']
                ]
            ]);
            exit;
        } else if ($tipo === 'materias_x_cat') {
            $data = $db->getMateriasXCategoria($id, $soloHabilitados);
            echo json_encode([
                'data' => $data,
                'columns' => [
                    ['key' => 'id_mat_prima', 'label' => 'ID'],
                    ['key' => 'nom_materia_prima', 'label' => 'Materia Prima'],
                    ['key' => 'valor_medida', 'label' => 'Valor'],
                    ['key' => 'medida_mat_prima', 'label' => 'Unidad'],
                    ['key' => 'cant_mat_prima', 'label' => 'Cantidad']
                ]
            ]);
            exit;
        } else if ($tipo === 'materias_x_proveedor') {
            error_log("API Debug: Requesting materias for Provider ID: " . $id);
            if (empty($id)) {
                error_log("API Debug: ID is empty.");
                echo json_encode(['success' => false, 'error' => 'ID de proveedor requerido']);
                exit;
            }
            $res = $db->getMateriasByProveedor($id);
            error_log("API Debug: Materias found: " . print_r($res, true));
            echo json_encode(['success' => true, 'data' => $res]);
            exit;
        } else if ($tipo === 'materias_primas_list') {
            $res = $db->getMateriasPrimasList();
            echo json_encode(['success' => true, 'data' => $res]);
            exit;
        } else if ($tipo === 'historico_precios') {
            $res = $db->getHistoricoPrecios($id);
            echo json_encode(['success' => true, 'data' => $res]);
            exit;
        }
        return false;
    }

    public static function handleCreate($db, $tipo, $data)
    {
        if ($tipo === 'categorias_materia') {
            if (empty($data['nom_categoria']))
                throw new Exception("Nombre de categoría es requerido.");
            $res = $db->insertCategoriaMateria($data['nom_categoria']);
            return $res;
        } else if ($tipo === 'materias_primas') {
            $res = $db->insertMateriaPrima($data);
            return $res;
        } else if ($tipo === 'movimiento_materia') {
            if (empty($data['id_materia']) || empty($data['id_proveedor']) || empty($data['tipo_movimiento']) || empty($data['cantidad']) || empty($data['observaciones'])) {
                throw new Exception("Campos obligatorios faltantes (Materia, Proveedor, Tipo, Cantidad o Obs).");
            }

            if (empty($data['valor_medida']) || empty($data['id_unidad_medida'])) {
                $metadata = $db->getMatProvMetadata($data['id_materia'], $data['id_proveedor']);
                if (!$metadata) {
                    throw new Exception("No existe un vínculo registrado entre la materia prima y el proveedor seleccionado.");
                }
                $data['valor_medida'] = $metadata['valor_medida'];
                $data['id_unidad_medida'] = $metadata['id_unidad_medida'];
            }

            $res = $db->registrarMovimientoKardex($data);
            return $res;
        }
        return false;
    }

    public static function handleUpdate($db, $tipo, $id, $data, $conn)
    {
        if ($tipo === 'categorias_materia') {
            if (!isset($data['nom_categoria']))
                throw new Exception("Nombre de categoría requerido");
            $res = $db->updateCategoriaMateria($id, $data['nom_categoria']);
            if ($res === false || (isset($res['result']) && ($res['result'] === false || $res['result'] === 'f'))) {
                throw new Exception("Error al actualizar categoría (BD)");
            }
            echo json_encode(['success' => true, 'message' => 'Categoría actualizada']);
            $conn->commit();
            exit;
        } else if ($tipo === 'materias_primas') {
            if (!empty($data['nom_prov'])) {
                $data['id_prov'] = $db->getIdByName('tab_proveedores', 'id_prov', 'nom_prov', $data['nom_prov']);
            }
            if (!empty($data['nom_unidad'])) {
                $data['id_unidad_medida'] = $db->getIdByName('tab_unidades_medida', 'id_unidad_medida', 'nom_unidad', $data['nom_unidad']);
            }
            $res = $db->updateMateriaPrima($id, $data);
            if ($res === false || (isset($res['result']) && ($res['result'] === false || $res['result'] === 'f' || $res['result'] === 0))) {
                throw new Exception("Error al actualizar materia prima (Validación BD)");
            }
            echo json_encode(['success' => true, 'message' => 'Materia Prima actualizada']);
            $conn->commit();
            exit;
        }
        return false;
    }

    public static function handleDelete($db, $conn, $tipo, $id)
    {
        return true;
    }

    /**
     * MÉTODO: handleRestore
     * PROPÓSITO: Reactiva registros inhabilitados de Materia Prima.
     */
    public static function handleRestore($db, $tipo, $id)
    {
        if ($tipo === 'categorias_materia' || $tipo === 'materias_primas') {
            return $db->restoreGeneric($tipo, $id);
        }
        return false;
    }
}
?>
<?php
class ApiHistorialController
{
    public static function handleGet($db, $tipo, $id)
    {
        if ($tipo === 'listar_historial_kardex') {
            $res = $db->getKardexHistory();
            echo json_encode(['success' => true, 'data' => $res]);
            exit;
        } else if ($tipo === 'listar_historial_ventas_devoluciones') {
            $res = $db->getKardexVentasDevoluciones();
            echo json_encode(['success' => true, 'data' => $res]);
            exit;
        } else if ($tipo === 'buscar_facturas_devolucion') {
            $mes = (int)($_GET['mes'] ?? 0);
            $anio = (int)($_GET['anio'] ?? date('Y'));
            $q = $_GET['q'] ?? '';
            $res = $db->buscarFacturasParaDevolucion($mes, $anio, $q);
            echo json_encode(['success' => true, 'data' => $res]);
            exit;
        } else if ($tipo === 'detalle_factura') {
            $res = $db->getFacturaDetalle($id);
            echo json_encode(['success' => true, 'data' => $res]);
            exit;
        } else if ($tipo === 'listar_devoluciones_pendientes') {
            $res = $db->getDevolucionesPendientes();
            echo json_encode(['success' => true, 'data' => $res]);
            exit;
        }
        return false;
    }

    public static function handleCreate($db, $tipo, $data)
    {
        if ($tipo === 'kardex_movimiento') {
            if (empty($data['id_materia']) || empty($data['id_proveedor']) || empty($data['tipo_movimiento']) || empty($data['cantidad']) || empty($data['observaciones'])) {
                throw new Exception("Campos obligatorios faltantes (Materia, Proveedor, Tipo, Cantidad o Obs).");
            }

            if (empty($data['valor_medida']) || empty($data['id_unidad_medida'])) {
                $metadata = $db->getMatProvMetadata($data['id_materia'], $data['id_proveedor']);
                if (!$metadata) {
                    throw new Exception("No existe un vínculo registrado entre la materia prima y el proveedor seleccionado. Por favor, asigne un proveedor en el maestro de materiales.");
                }
                $data['valor_medida'] = $metadata['valor_medida'];
                $data['id_unidad_medida'] = $metadata['id_unidad_medida'];
            }

            $res = $db->registrarMovimientoKardex($data);

            if ($res === false || (isset($res['result']) && ($res['result'] === false || $res['result'] === 'f'))) {
                throw new Exception("Error al registrar movimiento. Verifique que exista relación entre Proveedor y Materia Prima.");
            }

            return $res;
        } else if ($tipo === 'kardex_producto') {
            if (empty($data['id_item']) || empty($data['tipo_item']) || empty($data['tipo_movimiento']) || empty($data['cantidad'])) {
                throw new Exception("Campos obligatorios faltantes (ID Item, Tipo Item, Tipo Movimiento o Cantidad).");
            }

            $res = $db->insertKardexProducto($data);

            if ($res === false || (isset($res['result']) && ($res['result'] === false || $res['result'] === 'f' || $res['result'] === 0))) {
                throw new Exception("Error al registrar movimiento de producto (Validación BD).");
            }

            return $res;
        } else if ($tipo === 'venta_formal') {
            if (empty($data['id_productos']) || empty($data['cantidades']) || empty($data['id_forma_pago'])) {
                throw new Exception("Campos obligatorios faltantes para la venta (Productos, Cantidades o Forma de Pago).");
            }

            $res = $db->registrarVentaFormal($data);

            if ($res === false || (isset($res['result']) && ($res['result'] === false || $res['result'] === 'f' || $res['result'] === 0))) {
                throw new Exception("Error al registrar la venta formal (Validación BD). Verifique stock disponible.");
            }

            return $res;
        } else if ($tipo === 'devolucion_factura') {
            if (empty($data['id_factura']) || empty($data['id_productos']) || empty($data['cantidades'])) {
                throw new Exception("Datos incompletos para procesar la devolución.");
            }

            $res = $db->registrarDevolucionMultiple($data);

            if ($res === false || (isset($res['result']) && ($res['result'] === false || $res['result'] === 'f' || $res['result'] === 0))) {
                throw new Exception("Error al registrar la devolución (Validación BD).");
            }

            return $res;
        }
        return false;
    }

    public static function handleUpdate($db, $tipo, $id, $data)
    {
        if ($tipo === 'resolver_devolucion') {
            $data['id_devol_reparable'] = $id;
            $res = $db->resolverDevolucion($data);
            return $res;
        }
        return false;
    }

    public static function handleDelete($db, $conn, $tipo, $id)
    {
        return false;
    }
}
?>
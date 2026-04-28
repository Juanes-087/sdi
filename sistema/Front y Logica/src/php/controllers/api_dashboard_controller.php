<?php
class ApiDashboardController
{
    public static function handleGet($db, $tipo)
    {
        if ($tipo === 'auxiliares') {
            echo $db->getAuxiliaresJSON();
            exit;
        } else if ($tipo === 'stats') {
            $info = $db->getStats();
            echo json_encode([
                'success' => true, 
                'data' => [
                    'total_usuarios' => $info['total_usuarios'] ?? 0,
                    'usuarios_mes' => $info['usuarios_mes'] ?? 0,
                    'total_ventas' => (float)($info['total_ventas'] ?? 0),
                    'ventas_diarias' => (float)($info['ventas_diarias'] ?? 0),
                    'total_productos' => (int)($info['total_productos'] ?? 0),
                    'total_instrumentos' => (int)($info['total_instrumentos'] ?? 0),
                    'total_kits' => (int)($info['total_kits'] ?? 0)
                ]
            ]);
            exit;
        } else if ($tipo === 'clientes') {
            $data = $db->getClientes();
            echo json_encode([
                'data' => $data,
                'columns' => [
                    ['key' => 'id_cliente', 'label' => 'ID'],
                    ['key' => 'nombre_completo', 'label' => 'Nombre'],
                    ['key' => 'num_documento', 'label' => 'Documento'],
                    ['key' => 'tel_cliente', 'label' => 'Teléfono'],
                    ['key' => 'dir_cliente', 'label' => 'Dirección'],
                    ['key' => 'ind_profesion', 'label' => 'Profesión']
                ]
            ]);
            exit;
        } else if ($tipo === 'empleados') {
            $data = $db->getEmpleados();
            echo json_encode([
                'data' => $data,
                'columns' => [
                    ['key' => 'id_empleado', 'label' => 'ID'],
                    ['key' => 'nombre_completo', 'label' => 'Nombre'],
                    ['key' => 'nom_cargo', 'label' => 'Cargo'],
                    ['key' => 'tel_empleado', 'label' => 'Teléfono'],
                    ['key' => 'mail_empleado', 'label' => 'Email']
                ]
            ]);
            exit;
        } else if ($tipo === 'proveedores') {
            $data = $db->getProveedores();
            echo json_encode([
                'data' => $data,
                'columns' => [
                    ['key' => 'id_prov', 'label' => 'ID'],
                    ['key' => 'nom_prov', 'label' => 'Proveedor'],
                    ['key' => 'num_documento', 'label' => 'NIT/Doc'],
                    ['key' => 'tel_prov', 'label' => 'Teléfono'],
                    ['key' => 'mail_prov', 'label' => 'Email']
                ]
            ]);
            exit;
        } else if ($tipo === 'usuarios') {
            $data = $db->getUsuarios();
            echo json_encode([
                'data' => $data,
                'columns' => [
                    ['key' => 'id_user', 'label' => 'ID'],
                    ['key' => 'nom_user', 'label' => 'Usuario'],
                    ['key' => 'mail_user', 'label' => 'Email'],
                    ['key' => 'tel_user', 'label' => 'Teléfono'],
                    ['key' => 'ind_vivo', 'label' => 'Activo']
                ]
            ]);
            exit;
        } else if ($tipo === 'nuevos_mes') {
            $data = $db->getNuevosUsuariosMesDetalle();
            echo json_encode([
                'data' => $data,
                'columns' => [
                    ['key' => 'id_user', 'label' => 'ID'],
                    ['key' => 'nom_user', 'label' => 'Usuario'],
                    ['key' => 'mail_user', 'label' => 'Email'],
                    ['key' => 'tel_user', 'label' => 'Teléfono'],
                    ['key' => 'fec_insert', 'label' => 'Fecha Registro']
                ]
            ]);
            exit;
        } else if ($tipo === 'finanzas') {
            $mes = isset($_GET['mes']) ? (int)$_GET['mes'] : (int)date('m');
            $anio = isset($_GET['anio']) ? (int)$_GET['anio'] : (int)date('Y');
            
            $stats = $db->getFinanzasStats($mes, $anio);
            $tickets = $db->getTicketEspecialidad($mes, $anio);
            $alertas = $db->getPrevisionesCompra();
            
            echo json_encode([
                'success' => true,
                'data' => [
                    'stats' => $stats,
                    'tickets' => $tickets,
                    'alertas' => $alertas
                ]
            ]);
            exit;
        } else if ($tipo === 'finanzas_reporte') {
            $mes = isset($_GET['mes']) ? (int)$_GET['mes'] : (int)date('m');
            $anio = isset($_GET['anio']) ? (int)$_GET['anio'] : (int)date('Y');
            
            $data = $db->getReporteFinanzasDetallado($mes, $anio);
            
            echo json_encode([
                'success' => true,
                'data' => $data
            ]);
            exit;
        }
        return false;
    }

    public static function handleCreate($db, $tipo, $data)
    {
        if ($tipo === 'usuarios') {
            if (empty($data['nom_user']) || empty($data['pass_user']))
                throw new Exception("Faltan datos obligatorios");

            $hashed_password = password_hash($data['pass_user'], PASSWORD_DEFAULT);
            $res = $db->insertUser($data['nom_user'], $hashed_password, $data['tel_user'], $data['mail_user']);

            if ($res === false) {
                throw new Exception("La base de datos no pudo procesar la creación del usuario.");
            }
            return $res;
        } else if ($tipo === 'clientes') {
            $data['id_documento'] = $db->getIdByName('tab_tipo_documentos', 'id_documento', 'nom_tipo_docum', $data['nom_documento'] ?? '');
            $data['id_ciudad'] = $db->getIdByName('tab_ciudades', 'id_ciudad', 'nom_ciudad', $data['nom_ciudad'] ?? '');
            // Mapeo estático de género
            $gen = strtolower($data['nom_genero'] ?? '');
            if ($gen === 'masculino' || (isset($data['ind_genero']) && $data['ind_genero'] == 1) || (isset($data['id_genero']) && $data['id_genero'] == 1)) $data['ind_genero'] = 1;
            elseif ($gen === 'femenino' || (isset($data['ind_genero']) && $data['ind_genero'] == 2) || (isset($data['id_genero']) && $data['id_genero'] == 2)) $data['ind_genero'] = 2;
            else $data['ind_genero'] = 3;

            if (!$data['id_documento'])
                throw new Exception("Tipo de documento inválido: " . ($data['nom_documento'] ?? ''));
            if (!$data['id_ciudad'])
                throw new Exception("Ciudad inválida: " . ($data['nom_ciudad'] ?? ''));
            return $db->insertCliente($data);
        } else if ($tipo === 'empleados') {
            $data['id_documento'] = $db->getIdByName('tab_tipo_documentos', 'id_documento', 'nom_tipo_docum', $data['nom_documento'] ?? '');
            $data['id_ciudad'] = $db->getIdByName('tab_ciudades', 'id_ciudad', 'nom_ciudad', $data['nom_ciudad'] ?? '');
            $data['id_cargo'] = $db->getIdByName('tab_cargos', 'id_cargo', 'nom_cargo', $data['nom_cargo'] ?? '');
            $data['id_tipo_sangre'] = $db->getIdByName('tab_tipo_sangre', 'id_tipo_sangre', 'nom_tip_sang', $data['nom_tipo_sangre'] ?? '');
            $data['id_banco'] = $db->getIdByName('tab_bancos', 'id_banco', 'nom_banco', $data['nom_banco'] ?? '');
            
            // Mapeo estático de género
            $gen = strtolower($data['nom_genero'] ?? '');
            if ($gen === 'masculino' || (isset($data['ind_genero']) && $data['ind_genero'] == 1) || (isset($data['id_genero']) && $data['id_genero'] == 1)) $data['ind_genero'] = 1;
            elseif ($gen === 'femenino' || (isset($data['ind_genero']) && $data['ind_genero'] == 2) || (isset($data['id_genero']) && $data['id_genero'] == 2)) $data['ind_genero'] = 2;
            else $data['ind_genero'] = 3;

            if (!$data['id_documento'])
                throw new Exception("Tipo de documento inválido");
            if (!$data['id_ciudad'])
                throw new Exception("Ciudad inválida");
            if (!$data['id_cargo'])
                throw new Exception("Cargo inválido");
            if (!$data['id_banco'])
                throw new Exception("Debe seleccionar un Banco válido.");

            return $db->insertEmpleado($data);
        } else if ($tipo === 'proveedores') {
            $data['id_documento'] = $db->getIdByName('tab_tipo_documentos', 'id_documento', 'nom_tipo_docum', $data['nom_documento'] ?? '');
            $data['id_ciudad'] = $db->getIdByName('tab_ciudades', 'id_ciudad', 'nom_ciudad', $data['nom_ciudad'] ?? '');
            if (!$data['id_documento'])
                throw new Exception("Tipo de documento inválido");
            if (!$data['id_ciudad'])
                throw new Exception("Ciudad inválida");
            return $db->insertProveedor($data);
        } else if ($tipo === 'productos') {
            if (empty($data['nombre_producto']) || empty($data['precio_producto'])) {
                throw new Exception("Faltan datos obligatorios (Nombre o Precio).");
            }
            return $db->insertProducto($data);
        }
        return false;
    }

    public static function handleUpdate($db, $tipo, $id, $data)
    {
        $updateData = [];
        $table = '';
        $idField = '';

        if ($tipo === 'usuarios') {
            if (isset($data['nom_user']))
                $updateData['nom_user'] = $data['nom_user'];
            if (isset($data['mail_user']))
                $updateData['mail_user'] = $data['mail_user'];
            if (isset($data['tel_user']))
                $updateData['tel_user'] = (int) $data['tel_user'];
            $table = 'tab_users';
            $idField = 'id_user';
        } else if ($tipo === 'clientes') {
            // Recopilar todos los campos necesarios para fun_update_clientes
            $updateData = $data;
            $updateData['id_cliente'] = $id;

            // Mapear nombres a IDs si se proporcionan
            if (isset($data['nom_documento'])) {
                $updateData['id_documento'] = $db->getIdByName('tab_tipo_documentos', 'id_documento', 'nom_tipo_docum', $data['nom_documento']);
                if (!$updateData['id_documento']) throw new Exception("Tipo de documento inválido.");
            }
            if (isset($data['nom_ciudad'])) {
                $updateData['id_ciudad'] = $db->getIdByName('tab_ciudades', 'id_ciudad', 'nom_ciudad', $data['nom_ciudad']);
                if (!$updateData['id_ciudad']) throw new Exception("Ciudad inválida: El valor ingresado no coincide con la lista.");
            }
            // Mapeo de género
            if (isset($data['nom_genero']) || isset($data['ind_genero']) || isset($data['id_genero'])) {
                $gen = strtolower($data['nom_genero'] ?? '');
                if ($gen === 'masculino' || (isset($data['ind_genero']) && $data['ind_genero'] == 1) || (isset($data['id_genero']) && $data['id_genero'] == 1)) $updateData['ind_genero'] = 1;
                elseif ($gen === 'femenino' || (isset($data['ind_genero']) && $data['ind_genero'] == 2) || (isset($data['id_genero']) && $data['id_genero'] == 2)) $updateData['ind_genero'] = 2;
                else $updateData['ind_genero'] = 3;
            } else {
                $updateData['ind_genero'] = 3; // Fallback
            }

            // Llamar a la función específica
            $res = $db->updateCliente($updateData);
            return ['done' => true, 'message' => 'Cliente actualizado correctamente'];
        } else if ($tipo === 'empleados') {
            if (isset($data['prim_nom']))
                $updateData['prim_nom'] = $data['prim_nom'];
            if (isset($data['segun_nom']))
                $updateData['segun_nom'] = $data['segun_nom'];
            if (isset($data['prim_apell']))
                $updateData['prim_apell'] = $data['prim_apell'];
            if (isset($data['segun_apell']))
                $updateData['segun_apell'] = $data['segun_apell'];
            if (isset($data['num_documento']))
                $updateData['num_documento'] = $data['num_documento'];
            if (isset($data['ind_fecha_contratacion']))
                $updateData['ind_fecha_contratacion'] = $data['ind_fecha_contratacion'];
            if (isset($data['tel_empleado']))
                $updateData['tel_empleado'] = $data['tel_empleado'];
            if (isset($data['mail_empleado']))
                $updateData['mail_empleado'] = $data['mail_empleado'];
            if (isset($data['dir_emple']))
                $updateData['dir_emple'] = $data['dir_emple'];
            if (isset($data['num_cuenta']))
                $updateData['num_cuenta'] = $data['num_cuenta'];
            if (isset($data['ind_peso']))
                $updateData['ind_peso'] = $data['ind_peso'];
            if (isset($data['ind_altura']))
                $updateData['ind_altura'] = $data['ind_altura'];
            if (isset($data['ult_fec_exam']))
                $updateData['ult_fec_exam'] = $data['ult_fec_exam'];
            if (isset($data['observ']))
                $updateData['observ'] = $data['observ'];

            if (isset($data['nom_banco']))
                $updateData['id_banco'] = $db->getIdByName('tab_bancos', 'id_banco', 'nom_banco', $data['nom_banco']);
            if (isset($data['nom_documento']))
                $updateData['id_documento'] = $db->getIdByName('tab_tipo_documentos', 'id_documento', 'nom_tipo_docum', $data['nom_documento']);
            if (isset($data['nom_ciudad']))
                $updateData['id_ciudad'] = $db->getIdByName('tab_ciudades', 'id_ciudad', 'nom_ciudad', $data['nom_ciudad']);
            if (isset($data['nom_cargo']))
                $updateData['id_cargo'] = $db->getIdByName('tab_cargos', 'id_cargo', 'nom_cargo', $data['nom_cargo']);
            if (isset($data['nom_tipo_sangre']))
                $updateData['id_tipo_sangre'] = $db->getIdByName('tab_tipo_sangre', 'id_tipo_sangre', 'nom_tip_sang', $data['nom_tipo_sangre']);
            if (isset($data['id_genero']) || isset($data['ind_genero']) || isset($data['nom_genero'])) {
                $gen = strtolower($data['nom_genero'] ?? '');
                if ($gen === 'masculino' || (isset($data['ind_genero']) && $data['ind_genero'] == 1) || (isset($data['id_genero']) && $data['id_genero'] == 1)) $updateData['ind_genero'] = 1;
                elseif ($gen === 'femenino' || (isset($data['ind_genero']) && $data['ind_genero'] == 2) || (isset($data['id_genero']) && $data['id_genero'] == 2)) $updateData['ind_genero'] = 2;
                else $updateData['ind_genero'] = 3;
            }

            // Usar la función específica para empleados en lugar de actualización genérica
            $updateData['id_empleado'] = $id;
            $res = $db->updateEmpleado($updateData);
            return ['done' => true, 'message' => 'Empleado actualizado correctamente'];
        } else if ($tipo === 'proveedores') {
            $updateData = $data;
            $updateData['id_prov'] = $id;

            if (isset($data['nom_documento'])) {
                $updateData['id_documento'] = $db->getIdByName('tab_tipo_documentos', 'id_documento', 'nom_tipo_docum', $data['nom_documento']);
                if (!$updateData['id_documento']) throw new Exception("Tipo de documento inválido.");
            }
            if (isset($data['nom_ciudad'])) {
                $updateData['id_ciudad'] = $db->getIdByName('tab_ciudades', 'id_ciudad', 'nom_ciudad', $data['nom_ciudad']);
                if (!$updateData['id_ciudad']) throw new Exception("Ciudad inválida: El valor ingresado no coincide con la lista.");
            }

            $res = $db->updateProveedor($updateData);
            return ['done' => true, 'message' => 'Proveedor actualizado correctamente'];
        } else if ($tipo === 'productos') {
            $res = $db->updateProducto($id, $data);
            if ($res === false || (isset($res['result']) && ($res['result'] === false || $res['result'] === 'f' || $res['result'] === 0))) {
                throw new Exception("Error al actualizar producto (Validación BD)");
            }
            return ['done' => true, 'message' => 'Producto actualizado'];
        }

        if (!empty($table)) {
            return ['done' => false, 'table' => $table, 'idField' => $idField, 'updateData' => $updateData];
        }

        return false;
    }

    public static function handleDelete($db, $conn, $tipo, $id)
    {
        if ($tipo === 'productos') {
            return $db->deleteGeneric('productos', $id);
        } else if ($tipo === 'usuarios' || $tipo === 'nuevos_mes') {
            return $db->deleteGeneric('usuarios', $id);
        }
        return true;
    }

    public static function handleRestore($db, $tipo, $id)
    {
        return $db->restoreGeneric($tipo, $id);
    }
}
?>
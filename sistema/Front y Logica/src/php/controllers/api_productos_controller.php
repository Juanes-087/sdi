<?php
/**
 * Controlador Atómico para la Gestión de Productos (Inventario de Ventas)
 * Maneja la lectura, creación, actualización y validaciones de dependencias.
 */
class ApiProductosController
{
    /**
     * MÉTODO: handleGet
     * PROPÓSITO: Obtiene la lista de productos (Habilitados/Inhabilitados).
     * DISPARADOR: Se ejecuta cuando JS solicita 'read' con tipo=productos.
     */
    public static function handleGet($db, $tipo, $id = 0)
    {
        if ($tipo === 'productos') {
            // Se obtiene el parámetro 'estado' de la URL (true por defecto)
            $estado = isset($_GET['estado']) ? ($_GET['estado'] === 'true') : true;
            
            // Consulta a querys.php -> getProductosAdmin
            $data = $db->getProductosAdmin($estado);
            
            echo json_encode([
                'success' => true,
                'data' => $data,
                'columns' => [
                    ['key' => 'id', 'label' => 'ID'],
                    ['key' => 'tipo', 'label' => 'Tipo'],
                    ['key' => 'nombre', 'label' => 'Producto'],
                    ['key' => 'nombre_origen', 'label' => 'Ref. Instrumento/Kit'],
                    ['key' => 'precio', 'label' => 'Precio']
                ]
            ]);
            exit;
        }
        return false; // Retorna falso si no es el tipo que este controlador maneja
    }

    /**
     * MÉTODO: handleDelete
     * PROPÓSITO: Valida si un producto puede ser eliminado (borrado lógico).
     * NOTA: Los productos no suelen bloquearse por historial, pero se pueden añadir reglas aquí.
     */
    public static function handleDelete($db, $conn, $tipo, $id)
    {
        if ($tipo === 'productos') {
            // Ejemplo de validación: No borrar si tiene facturas asociadas (Opcional según negocio)
            // Por ahora permitimos el borrado lógico directo.
            return true; 
        }
        return false;
    }

    /**
     * MÉTODO: handleRestore
     * PROPÓSITO: Reactiva un producto inhabilitado.
     */
    public static function handleRestore($db, $tipo, $id)
    {
        if ($tipo === 'productos') {
            return $db->restoreGeneric('productos', $id);
        }
        return false;
    }
}
?>

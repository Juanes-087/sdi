<?php
require_once 'conexion.php';
require_once 'querys.php';

$id_factura = $_GET['id'] ?? null;

if (!$id_factura) {
    die("ID de factura no proporcionado.");
}

$db = new CQuerys();
$encabezado = $db->getFacturaEncabezado($id_factura);
$detalles = $db->getFacturaDetalle($id_factura);

if (!$encabezado) {
    die("Factura no encontrada.");
}

function formatCurrency($val) {
    return '$' . number_format($val, 0, ',', '.');
}
?>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>Factura de Venta #<?php echo $id_factura; ?></title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            color: #333;
            margin: 0;
            padding: 40px;
            background-color: #f0f2f5;
        }
        .invoice-box {
            max-width: 850px;
            margin: auto;
            padding: 40px;
            background: #fff;
            border-radius: 12px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
            position: relative;
            overflow: hidden;
        }
        .invoice-box::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            height: 8px;
            background: linear-gradient(90deg, #36498f, #087d4e);
        }
        .header {
            display: flex;
            justify-content: space-between;
            margin-bottom: 40px;
            border-bottom: 2px solid #f0f2f5;
            padding-bottom: 20px;
        }
        .company-info h1 {
            color: #36498f;
            margin: 0;
            font-size: 28px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        .company-info p {
            margin: 5px 0;
            color: #666;
            font-size: 0.9rem;
        }
        .invoice-info {
            text-align: right;
        }
        .invoice-info h2 {
            color: #087d4e;
            margin: 0;
            font-size: 24px;
        }
        .details-container {
            display: flex;
            justify-content: space-between;
            margin-bottom: 40px;
        }
        .client-details h3, .invoice-details h3 {
            font-size: 0.85rem;
            color: #888;
            text-transform: uppercase;
            margin-bottom: 15px;
            border-bottom: 1px solid #eee;
            padding-bottom: 5px;
        }
        .client-details p, .invoice-details p {
            margin: 5px 0;
            font-weight: 500;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 30px;
        }
        th {
            background: #f8f9fa;
            color: #36498f;
            text-align: left;
            padding: 12px 15px;
            font-size: 0.9rem;
            text-transform: uppercase;
        }
        td {
            padding: 15px;
            border-bottom: 1px solid #f0f2f5;
            vertical-align: top;
        }
        .product-name {
            font-weight: 600;
            color: #2c3e50;
        }
        .kit-contents {
            font-size: 0.8rem;
            color: #666;
            background: #fdfdfd;
            padding: 8px 12px;
            border-left: 3px solid #087d4e;
            margin-top: 8px;
            border-radius: 0 4px 4px 0;
        }
        .totals {
            width: 300px;
            margin-left: auto;
        }
        .total-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            font-size: 0.95rem;
        }
        .total-row.grand-total {
            margin-top: 15px;
            padding: 15px 0;
            border-top: 2px solid #36498f;
            font-size: 1.3rem;
            font-weight: 700;
            color: #36498f;
        }
        .footer {
            margin-top: 50px;
            text-align: center;
            color: #999;
            font-size: 0.8rem;
            border-top: 1px solid #eee;
            padding-top: 20px;
        }
        @media print {
            body { background: none; padding: 0; }
            .invoice-box { box-shadow: none; border: 1px solid #eee; }
            .no-print { display: none; }
        }
        .btn-print {
            position: fixed;
            bottom: 30px;
            right: 30px;
            background: #36498f;
            color: white;
            padding: 15px 25px;
            border-radius: 30px;
            text-decoration: none;
            box-shadow: 0 5px 15px rgba(54, 73, 143, 0.4);
            font-weight: 600;
            transition: all 0.3s;
            border: none;
            cursor: pointer;
        }
        .btn-print:hover {
            transform: translateY(-3px);
            box-shadow: 0 8px 20px rgba(54, 73, 143, 0.5);
        }
    </style>
</head>
<body>

    <div class="invoice-box">
        <div class="header">
            <div class="company-info">
                <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 10px;">
                    <img src="../../images/logo central solo.png" alt="Logo" style="height: 50px; width: auto;">
                    <img src="../../images/texto logo.png" alt="Specialized" style="height: 35px; width: auto;">
                </div>
                <p><i class="fa-solid fa-location-dot"></i> Calle 41 #6-68, Lagos 2, Floridablanca, Santander</p>
                <p><i class="fa-solid fa-phone"></i> +57 (607) 649 6730</p>
                <p><i class="fa-solid fa-envelope"></i> specializedinst@yahoo.es</p>
            </div>
            <div class="invoice-info">
                <h2>FACTURA COMERCIAL</h2>
                <p><b>Número:</b> #<?php echo str_pad($id_factura, 6, '0', STR_PAD_LEFT); ?></p>
                <p><b>Fecha:</b> <?php echo date('d/m/Y', strtotime($encabezado['fecha_venta'])); ?></p>
            </div>
        </div>

        <div class="details-container">
            <div class="client-details">
                <h3>Facturado a:</h3>
                <p><b><?php echo $encabezado['cliente_nombre']; ?></b></p>
                <p><?php echo $encabezado['nom_tipo_docum']; ?>: <?php echo $encabezado['num_documento']; ?></p>
                <p><?php echo $encabezado['dir_cliente'] ?: 'Dirección no registrada'; ?></p>
                <p><?php echo $encabezado['nom_ciudad'] ?: ''; ?></p>
            </div>
            <div class="invoice-details">
                <h3>Información de Pago:</h3>
                <p><b>Método:</b> <?php 
                    switch($encabezado['ind_forma_pago']) {
                        case 1: echo "Efectivo"; break;
                        case 2: echo "Transferencia"; break;
                        case 3: echo "Tarjeta"; break;
                        default: echo "Pendiente"; break;
                    }
                ?></p>
                <p><b>Moneda:</b> COP (Peso Colombiano)</p>
            </div>
        </div>

        <table>
            <thead>
                <tr>
                    <th style="width: 50%;">Descripción del Producto</th>
                    <th style="text-align: center;">Cant.</th>
                    <th style="text-align: right;">Precio Unit.</th>
                    <th style="text-align: right;">Total</th>
                </tr>
            </thead>
            <tbody>
                <?php 
                $subtotal = 0;
                foreach ($detalles as $item): 
                    $subtotal += $item['val_bruto'];
                ?>
                <tr>
                    <td>
                        <span class="product-name"><?php echo $item['nombre_producto']; ?></span>
                        <?php if ($item['id_kit']): ?>
                            <div class="kit-contents">
                                <b><i class="fa-solid fa-box-open"></i> Contenido del Kit:</b><br>
                                <?php 
                                    $kit_items = $db->getInstrumentsByKit($item['id_kit']);
                                    foreach ($kit_items as $ki) {
                                        echo "• " . $ki['nom_instrumento'] . " (x" . $ki['cantidad'] . ")<br>";
                                    }
                                ?>
                            </div>
                        <?php endif; ?>
                    </td>
                    <td style="text-align: center;"><?php echo $item['cantidad']; ?></td>
                    <td style="text-align: right;"><?php echo formatCurrency($item['precio_unitario']); ?></td>
                    <td style="text-align: right;"><?php echo formatCurrency($item['val_bruto']); ?></td>
                </tr>
                <?php endforeach; ?>
            </tbody>
        </table>

        <div class="totals">
            <?php 
                $total_descuento = 0;
                foreach ($detalles as $item) {
                    $total_descuento += $item['val_descuento'];
                }
            ?>
            <div class="total-row">
                <span>Subtotal:</span>
                <span><?php echo formatCurrency($subtotal); ?></span>
            </div>
            <?php if ($total_descuento > 0): ?>
            <div class="total-row">
                <span>Descuento:</span>
                <span><?php echo formatCurrency($total_descuento); ?></span>
            </div>
            <?php endif; ?>
            <div class="total-row grand-total">
                <span>Total Factura:</span>
                <span><?php echo formatCurrency($encabezado['val_tot_fact']); ?></span>
            </div>
        </div>

        <div class="footer">
            <p>Esta factura ha sido generada automáticamente por el sistema de gestión <b>SPECIALIZED</b>.</p>
            <p>Registro Sanitario No. 2015DM-0014009</p>
            <p>Gracias por confiar en nosotros.</p>
        </div>
    </div>

    <button onclick="window.print()" class="btn-print no-print">
        <i class="fa-solid fa-print"></i> Imprimir / Descargar PDF
    </button>

</body>
</html>

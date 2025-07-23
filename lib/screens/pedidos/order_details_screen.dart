// ignore_for_file: use_build_context_synchronously

import 'package:ecommerceassim/components/appBar/custom_app_bar.dart';
import 'package:ecommerceassim/screens/pedidos/order_progress_tracker.dart';
import 'package:ecommerceassim/screens/screens_index.dart';
import 'package:ecommerceassim/shared/components/bottomNavigation/BottomNavigation.dart';
import 'package:ecommerceassim/shared/constants/app_text_constants.dart';
import 'package:ecommerceassim/shared/constants/style_constants.dart';
import 'package:ecommerceassim/shared/core/controllers/pedidos_controller.dart';
import 'package:ecommerceassim/shared/core/models/pedidos_model.dart';
import 'package:ecommerceassim/shared/core/user_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class OrderDetailsScreen extends StatelessWidget {
  final int orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatusBadge(String status) {
    Color backgroundColor;
    Color textColor = Colors.white;
    IconData iconData;
    
    switch (status) {
      case 'pagamento pendente':
        backgroundColor = Colors.orange;
        iconData = Icons.payment;
        break;
      case 'comprovante anexado':
        backgroundColor = Colors.blue;
        iconData = Icons.attach_file;
        break;
      case 'aguardando retirada':
        backgroundColor = Colors.purple;
        iconData = Icons.inventory;
        break;
      case 'pedido enviado':
        backgroundColor = Colors.amber;
        iconData = Icons.local_shipping;
        break;
      case 'pedido entregue':
        backgroundColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case 'cancelado':
        backgroundColor = Colors.red;
        iconData = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey;
        iconData = Icons.help_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, color: textColor, size: 16),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PedidoController>(
      builder: (context, controller, child) {
        final order = controller.orders.firstWhere(
          (o) => o.id == orderId,
          orElse: () => PedidoModel(
            id: -1,
            status: 'error',
            tipoEntrega: '',
            subtotal: 0,
            taxaEntrega: 0,
            total: 0,
            formaPagamentoId: 0,
            consumidorId: 0,
            bancaId: 0,
          ),
        );

        if (order.id == -1) {
          return Scaffold(
            appBar: CustomAppBar(),
            bottomNavigationBar: BottomNavigation(
              paginaSelecionada: 2,
            ),
            body: const Center(
              child: Text('Pedido não encontrado'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
              backgroundColor: kDetailColor,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Detalhes do Pedido',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
          bottomNavigationBar: BottomNavigation(
            paginaSelecionada: 2,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho do Pedido
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pedido #${order.id}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Realizado em ${_formatDateTime(order.dataPedido)}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(order.status),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  OrderProgressTracker(currentStatus: order.status),
                  
                  const SizedBox(height: 24),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informações do Pedido',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kDetailColor,
                          ),
                        ),
                        const Divider(),
                        _buildInfoRow('Banca', order.bancaNome ?? 'Banca Desconhecida'),
                        _buildInfoRow('Tipo de Entrega', order.tipoEntrega),
                        _buildInfoRow('Subtotal', 'R\$ ${order.subtotal.toStringAsFixed(2)}'),
                        _buildInfoRow('Taxa de Entrega', 'R\$ ${order.taxaEntrega.toStringAsFixed(2)}'),
                        _buildInfoRow('Total', 'R\$ ${order.total.toStringAsFixed(2)}'),
                        if (order.dataConfirmacao != null)
                          _buildInfoRow('Confirmado em', _formatDateTime(order.dataConfirmacao)),
                        if (order.dataPagamento != null)
                          _buildInfoRow('Pago em', _formatDateTime(order.dataPagamento)),
                        if (order.dataEnvio != null)
                          _buildInfoRow('Enviado em', _formatDateTime(order.dataEnvio)),
                        if (order.dataEntrega != null)
                          _buildInfoRow('Entregue em', _formatDateTime(order.dataEntrega)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Informações de Pagamento (se tiver o PIX)
                  if (order.pix != null && order.pix!.isNotEmpty) 
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informações de Pagamento',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: kDetailColor,
                            ),
                          ),
                          const Divider(),
                          _buildInfoRow('Chave PIX', order.pix!),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Botões de Ação
                  Center(
                    child: Column(
                      children: [
                        if (order.status == 'pagamento pendente' || order.status == 'comprovante anexado')
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context, 
                                Screens.pagamento,
                                arguments: {"orderId": order.id, "status": order.status}
                              );
                            },
                            icon: const Icon(Icons.payment),
                            label: Text(order.status == 'pagamento pendente' 
                                ? 'Enviar Comprovante' 
                                : 'Ver Comprovante'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kDetailColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                          
                        if (order.status == 'aguardando retirada' || order.status == 'pedido enviado')
                          const SizedBox(height: 12),
                          
                        if (order.status == 'aguardando retirada' || order.status == 'pedido enviado')
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                Screens.marcarEnviado,
                                arguments: {"orderId": order.id},
                              );
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Marcar como Entregue'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
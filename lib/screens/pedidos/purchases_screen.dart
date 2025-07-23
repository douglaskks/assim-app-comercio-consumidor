// ignore_for_file: avoid_print

import 'package:ecommerceassim/screens/screens_index.dart';
import 'package:ecommerceassim/shared/components/bottomNavigation/BottomNavigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceassim/shared/constants/style_constants.dart';
import 'package:ecommerceassim/shared/core/controllers/pedidos_controller.dart';
import 'package:ecommerceassim/components/appBar/custom_app_bar.dart';
import 'package:ecommerceassim/components/forms/custom_order.dart';
import 'package:ecommerceassim/components/utils/vertical_spacer_box.dart';
import '../../shared/constants/app_enums.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PedidoController>(context, listen: false).loadOrders();
    });
  }

  void _onOrderTapped(int orderId) {
    print('Pedido com id ID $orderId clicado!');
    // Navegar para a página de detalhes do pedido
    Navigator.pushNamed(
      context, 
      Screens.orderDetails,
      arguments: {"orderId": orderId}
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PedidoController>(
      builder: (context, controller, child) {
        if (controller.status == PedidosStatus.loading) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: const CustomAppBar(),
            bottomNavigationBar: BottomNavigation(
              paginaSelecionada: 2,
            ),
            body: const Center(
              child: CircularProgressIndicator(
                color: kDetailColor,
              ),
            ),
          );
        }

        return Scaffold(
          appBar: const CustomAppBar(),
          bottomNavigationBar: BottomNavigation(
            paginaSelecionada: 2,
          ),
          body: Container(
            color: kOnSurfaceColor,
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.all(20),
            child: controller.orders.isNotEmpty
                ? RefreshIndicator(
                    onRefresh: () => controller.loadOrders(),
                    color: kDetailColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          const VerticalSpacerBox(size: SpacerSize.small),
                          ...List.generate(controller.orders.length, (index) {
                            var order = controller.orders[index];
                            return OrderCard(
                              orderNumber: '#${index + 1}',
                              sellerName: order.bancaNome ?? 'Banca Desconhecida',
                              itemsTotal: order.subtotal,
                              date: formatDate(order.dataPedido),
                              status: order.status,
                              onTap: () => _onOrderTapped(order.id),
                            );
                          }),
                          const VerticalSpacerBox(size: SpacerSize.medium),
                        ],
                      ),
                    ),
                  )
                : _buildEmptyListWidget(context),
          ),
        );
      },
    );
  }
}

Widget _buildEmptyListWidget(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag, color: kDetailColor, size: 60),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward, color: kDetailColor, size: 40),
              const SizedBox(width: 10),
              Icon(Icons.receipt_long, color: Colors.grey[400], size: 60),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Hora de experimentar!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kDetailColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Você ainda não tem pedidos. Encontre produtos incríveis e comece a comprar!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aproveite as ofertas disponíveis em nosso catálogo!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.store),
            label: const Text('Ver catálogo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: kDetailColor,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            onPressed: () {
              Navigator.pushNamed(context, Screens.home);
            },
          ),
        ],
      ),
    ),
  );
}

String formatDate(DateTime? date) {
  if (date == null) return 'Date N/A';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
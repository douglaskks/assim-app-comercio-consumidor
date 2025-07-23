// ignore_for_file: use_build_context_synchronously

import 'package:ecommerceassim/components/appBar/custom_app_bar.dart';
import 'package:ecommerceassim/shared/components/bottomNavigation/BottomNavigation.dart';
import 'package:ecommerceassim/shared/constants/app_text_constants.dart';
import 'package:ecommerceassim/shared/constants/style_constants.dart';
import 'package:ecommerceassim/shared/core/controllers/pedidos_controller.dart';
import 'package:ecommerceassim/shared/core/user_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class MarkAsDeliveredScreen extends StatefulWidget {
  final int orderId;

  const MarkAsDeliveredScreen({super.key, required this.orderId});

  @override
  State<MarkAsDeliveredScreen> createState() => _MarkAsDeliveredScreenState();
}

class _MarkAsDeliveredScreenState extends State<MarkAsDeliveredScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isSuccess = false;
  String _errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _markAsDelivered() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final pedidoController =
          Provider.of<PedidoController>(context, listen: false);
      final userStorage = UserStorage();
      final token = await userStorage.getUserToken();
      
      final response = await http.post(
        Uri.parse('$kBaseURL/transacoes/${widget.orderId}/entregar'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        pedidoController.updateOrderStatus(widget.orderId, 'pedido entregue');
        setState(() {
          _isSuccess = true;
          _isLoading = false;
        });
        
        // Aguarda 2 segundos antes de voltar para a tela anterior
        await Future.delayed(const Duration(seconds: 2));
        Navigator.pop(context);
      } else {
        throw Exception('Falha ao marcar como entregue. Código: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedidoController = Provider.of<PedidoController>(context);
    final order = pedidoController.orders.firstWhere(
      (order) => order.id == widget.orderId,
      orElse: () => throw Exception('Pedido não encontrado'),
    );

    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: BottomNavigation(
        paginaSelecionada: 2,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (_isSuccess) ...[
                    // Animação de sucesso
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 80,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pedido Confirmado!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'O pedido #${widget.orderId} foi marcado como entregue com sucesso.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ] else ...[
                    // Ícone animado
                    GestureDetector(
                      onTapDown: (_) => _animationController.forward(),
                      onTapUp: (_) => _animationController.reverse(),
                      onTapCancel: () => _animationController.reverse(),
                      onTap: _markAsDelivered,
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              width: 150,
                              height: 150,
                              decoration: BoxDecoration(
                                color: kDetailColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: kDetailColor,
                                  width: 3,
                                ),
                              ),
                              child: Icon(
                                Icons.check_circle_outline,
                                color: kDetailColor,
                                size: 80,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Confirmação de Entrega',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: kDetailColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pedido #${widget.orderId}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vendedor: ${order.bancaNome ?? 'Banca Desconhecida'}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Você confirma que recebeu este pedido?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (_isLoading)
                      const CircularProgressIndicator(color: kDetailColor)
                    else
                      ElevatedButton.icon(
                        onPressed: _markAsDelivered,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Confirmar Recebimento'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Text(
                          'Erro: $_errorMessage',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:ecommerceassim/shared/constants/style_constants.dart';

class OrderProgressTracker extends StatelessWidget {
  final String currentStatus;

  const OrderProgressTracker({
    super.key,
    required this.currentStatus,
  });

  int _getStepIndex() {
    switch (currentStatus) {
      case 'pagamento pendente':
        return 0;
      case 'comprovante anexado':
        return 1;
      case 'aguardando retirada':
        return 2;
      /*case 'pedido enviado':
        return 3;*/
      case 'pedido entregue':
        return 3; // Ajustado para 3 já que temos apenas 4 estados agora
      case 'cancelado':
        return -1; // Status especial para cancelado
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int currentStep = _getStepIndex();
    
    // Se o pedido foi cancelado, mostramos um indicador de erro
    if (currentStep == -1) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pedido Cancelado',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Este pedido foi cancelado e não será processado.',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Definição dos passos de progresso
    const steps = [
      {
        'title': 'Aguardando Pagamento',
        'icon': Icons.payment,
        'description': 'Esperando confirmação do pagamento'
      },
      {
        'title': 'Pagamento Recebido',
        'icon': Icons.receipt,
        'description': 'Comprovante enviado'
      },
      {
        'title': 'Em Preparação',
        'icon': Icons.inventory,
        'description': 'Pedido sendo preparado'
      },
      /*{
        'title': 'Em Trânsito',
        'icon': Icons.local_shipping,
        'description': 'Pedido enviado para entrega'
      },*/
      {
        'title': 'Entregue',
        'icon': Icons.check_circle,
        'description': 'Pedido recebido pelo cliente'
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, bottom: 8, top: 8),
          child: Text(
            'Status do Pedido',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kDetailColor,
            ),
          ),
        ),
        // Envolvemos o ListView em um SizedBox com altura fixa
        SizedBox(
          height: 100, // Altura fixa para evitar overflow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final isActive = index <= currentStep;
              final isCurrentStep = index == currentStep;
              
              // Cores com base no estado
              final Color circleColor = isActive ? kDetailColor : Colors.grey.shade300;
              final Color textColor = isActive ? kDetailColor : Colors.grey;
              final Color lineColor = index < currentStep ? kDetailColor : Colors.grey.shade300;
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Primeiro item não tem linha à esquerda
                  if (index == 0) const SizedBox(width: 16),
                  
                  // Step Circle com ícone
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isCurrentStep ? circleColor : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: circleColor,
                            width: 2,
                          ),
                          boxShadow: isCurrentStep
                              ? [
                                  BoxShadow(
                                    color: circleColor.withOpacity(0.3),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
                        child: Icon(
                          steps[index]['icon'] as IconData,
                          color: isCurrentStep ? Colors.white : circleColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 80,
                        child: Text(
                          steps[index]['title'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 80,
                        child: Text(
                          steps[index]['description'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 9,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  // Linha conectora (exceto para o último item)
                  if (index < steps.length - 1)
                    Container(
                      width: 30,
                      height: 2,
                      color: lineColor,
                    ),
                  
                  // Espaço depois do último item
                  if (index == steps.length - 1) const SizedBox(width: 16),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
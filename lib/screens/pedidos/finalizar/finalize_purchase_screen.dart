// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:io';

import 'package:ecommerceassim/components/appBar/custom_app_bar.dart';
import 'package:ecommerceassim/screens/cesta/cart_provider.dart';
import 'package:ecommerceassim/shared/core/controllers/profile_controller.dart';
import 'package:ecommerceassim/shared/core/controllers/purchase_controller.dart';
import 'package:ecommerceassim/shared/core/models/cart_model.dart';
import 'package:ecommerceassim/shared/core/models/endereco_model.dart';
import 'package:ecommerceassim/shared/core/models/pagamento_model.dart';
import 'package:flutter/material.dart';
import 'package:ecommerceassim/components/utils/horizontal_spacer_box.dart';
import 'package:ecommerceassim/components/utils/vertical_spacer_box.dart';
import 'package:ecommerceassim/screens/screens_index.dart';
import 'package:ecommerceassim/shared/constants/app_enums.dart';
import 'package:ecommerceassim/shared/constants/style_constants.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../components/buttons/primary_button.dart';
import 'package:ecommerceassim/shared/core/controllers/pagamento_controller.dart';
import 'package:ecommerceassim/shared/core/repositories/pagamento_repository.dart';
import 'package:ecommerceassim/shared/core/models/pedidos_model.dart';

class FinalizePurchaseScreen extends StatefulWidget {
  final List<CartModel> cartModel;
  final Map<String, dynamic>? addressData;

  const FinalizePurchaseScreen(this.cartModel, {this.addressData, super.key});

  @override
  State<FinalizePurchaseScreen> createState() => _FinalizePurchaseScreenState();
}

class _FinalizePurchaseScreenState extends State<FinalizePurchaseScreen> {
  String _deliveryMethod = 'retirada';
  int _paymentMethodId = 1;
  AddressModel? userAddress;
  bool isLoading = true;
  late int selectedAddressId;
  String? pixCode;
  XFile? _comprovanteImage;
  bool _isPickerActive = false;

  @override
void initState() {
  super.initState();
  _loadUserAddress();
  
  // Use Future.delayed para permitir que o widget seja construído primeiro
  Future.delayed(Duration.zero, () {
    if (Get.isRegistered<PurchaseController>()) {
      _loadPixCode();
    } else {
      print('PurchaseController será inicializado no build');
    }
  });
}

  Future<void> _loadUserAddress() async {
    final profileController =
        Provider.of<ProfileController>(context, listen: false);
    await profileController.fetchUserAddresses();
    setState(() {
      if (profileController.addresses.isNotEmpty) {
        userAddress = profileController.addresses.first;
        selectedAddressId = userAddress!.id;
      }
      isLoading = false;
    });
  }

  Future<void> _loadPixCode() async {
  try {
    // Verifica se o controller já existe
    if (!Get.isRegistered<PurchaseController>()) {
      print('PurchaseController ainda não está registrado, aguardando...');
      // Não faz nada neste momento, pois o controller será inicializado no build
      return;
    }
    
    final controller = Get.find<PurchaseController>();
    
    // Se o bancaModel já foi carregado e tem PIX
    if (controller.bancaModel != null && controller.bancaModel!.pix != null) {
      setState(() {
        pixCode = controller.bancaModel!.pix;
        print('Chave PIX definida: $pixCode');
      });
    } else {
      print('PIX não disponível no modelo atual');
      setState(() {
        pixCode = "Chave PIX não disponível";
      });
    }
  } catch (e) {
    print('Erro ao carregar chave PIX: $e');
    setState(() {
      pixCode = "Chave PIX não disponível";
    });
  }
}

  void _chooseAddress(
      BuildContext context, ProfileController controller) async {
    final AddressModel? selectedAddress = await showDialog<AddressModel>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Escolha um endereço!',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: SizedBox(
            width: double.minPositive,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: controller.addresses.length,
              itemBuilder: (BuildContext context, int index) {
                var address = controller.addresses[index];
                return ListTile(
                  leading: Text(
                    '${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  title: Text('${address.rua}, ${address.numero}'),
                  subtitle:
                      Text('${address.cidadeNome}, ${address.bairroNome} '),
                  onTap: () => Navigator.pop(context, address),
                );
              },
            ),
          ),
        );
      },
    );
    if (selectedAddress != null) {
      setState(() {
        userAddress = selectedAddress;
        selectedAddressId = selectedAddress.id;
        print("ENDEREÇO: $selectedAddressId");
      });
    }
  }

  Future<void> _chooseComprovante() async {
    if (_isPickerActive) return; // Evita múltiplas chamadas

    try {
      _isPickerActive = true;
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _comprovanteImage = image;
        });
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
    } finally {
      _isPickerActive = false;
    }
  }

  void showSuccessDialog(BuildContext context) {
  String title = 'Pedido realizado!';
  Widget content;
  
  // Verifica se o método de pagamento é dinheiro (ID 1)
  if (_paymentMethodId == 1) {
    title = 'Pedido realizado com Dinheiro!';
    content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.shopping_bag, size: 80, color: kDetailColor),
        const SizedBox(height: 10),
        const Text(
          'Seu pedido com pagamento em dinheiro será aguardado por até 1 hora para retirada.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  } else {
    content = const Icon(Icons.shopping_bag, size: 100, color: kDetailColor);
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.white,
        content: content,
        actions: <Widget>[
          PrimaryButton(
            text: "OK",
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                Screens.home,
                (Route<dynamic> route) => false,
              );
            },
            color: kDetailColor,
          ),
        ],
      );
    },
  );
}

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Erro',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.white,
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            PrimaryButton(
              text: "OK",
              onPressed: () {
                Navigator.of(context).pop();
              },
              color: kDetailColor,
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartListProvider = Provider.of<CartProvider>(context);
    Size size = MediaQuery.of(context).size;
    final profileController =
        Provider.of<ProfileController>(context, listen: false);
    
    // Preparando o controller de pagamento
    PagamentoRepository pagamentoRepository = PagamentoRepository();
    PagamentoController pagamentoController =
        PagamentoController(pagamentoRepository);

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Scaffold(
              backgroundColor: Colors.white,
              appBar: CustomAppBar(),
              body:
                  Center(child: CircularProgressIndicator(color: kDetailColor)))
          : GetBuilder<PurchaseController>(
              init: PurchaseController(listCartModel: widget.cartModel),
              builder: (controller) {
                controller.listCartModel = widget.cartModel;
                if (controller.bancaModel != null && controller.bancaModel!.pix != null) {
                if (pixCode != controller.bancaModel!.pix) {
                  // Execute em microtask para evitar setState durante o build
                  Future.microtask(() {
                    setState(() {
                      pixCode = controller.bancaModel!.pix;
                      print('PIX atualizado pelo builder: $pixCode');
                    });
                  });
                }
              }
                return Scaffold(
                  backgroundColor: Colors.white,
                  appBar: const CustomAppBar(),
                  body: Container(
                    color: Colors.white,
                    width: size.width,
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'Forma de entrega',
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                  overlayColor:
                                      WidgetStateProperty.all(kDetailColor),
                                  value: 'retirada',
                                  groupValue: _deliveryMethod,
                                  activeColor: kDetailColor,
                                  focusColor: kDetailColor,
                                  hoverColor: kDetailColor,
                                  onChanged: (value) {
                                    setState(() {
                                      _deliveryMethod = value.toString();
                                      print("Tipo de entrega: $_deliveryMethod");
                                    });
                                  }),
                              const Text(
                                'Retirada',
                                style: TextStyle(
                                    fontSize: 20, color: kTextButtonColor),
                              ),
                              const HorizontalSpacerBox(size: SpacerSize.small),
                              const HorizontalSpacerBox(size: SpacerSize.small),
                            ],
                          ),
                          const VerticalSpacerBox(size: SpacerSize.medium),
                          const Row(
                            children: [
                              Text(
                                'Forma de pagamento',
                                style: TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const VerticalSpacerBox(size: SpacerSize.small),
                          DropdownButtonFormField<int>(
                            value: _paymentMethodId,
                            onChanged: (int? value) {
                              setState(() {
                                _paymentMethodId = value ?? 1;
                              });
                            },
                            items: const [
                              DropdownMenuItem<int>(
                                value: 1,
                                child: Text(
                                  'Dinheiro',
                                  style:
                                      TextStyle(fontWeight: FontWeight.normal),
                                ),
                              ),
                              DropdownMenuItem<int>(
                                value: 2,
                                child: Text(
                                  'Pix',
                                  style:
                                      TextStyle(fontWeight: FontWeight.normal),
                                ),
                              ),
                            ],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding:
                                  const EdgeInsets.fromLTRB(13, 13, 13, 13),
                            ),
                          ),
                          // Novo bloco para Pix
                          if (_paymentMethodId == 2)
                            Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Chave PIX do Vendedor:",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SelectableText(
                                      pixCode != null ? 'Chave Pix: $pixCode' : 'Pix não disponível',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  const Text(
                                    "Comprovante de PIX:",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () async {
                                            await _chooseComprovante();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: kDetailColor,
                                          ),
                                          child: const Text(
                                            "Anexar Comprovante de PIX", 
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        if (_comprovanteImage != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 10.0),
                                            child: Column(
                                              children: [
                                                const Text("Visualização do comprovante:"),
                                                const SizedBox(height: 8),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.grey),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Image.file(
                                                    File(_comprovanteImage!.path),
                                                    height: 200,
                                                    width: double.infinity,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      print("Erro ao carregar imagem: $error");
                                                      return const Text("Erro ao carregar a imagem");
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const VerticalSpacerBox(size: SpacerSize.medium),
                          InkWell(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: kOnSurfaceColor,
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(15)),
                                boxShadow: [
                                  BoxShadow(
                                    color: kTextButtonColor.withOpacity(0.5),
                                    spreadRadius: 0,
                                    blurRadius: 3,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                                border: Border(
                                  left: BorderSide(
                                    color: kTextButtonColor.withOpacity(0.5),
                                    width: 1,
                                  ),
                                  right: BorderSide(
                                    color: kTextButtonColor.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Text(
                                        'Resumo de valores',
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Spacer(),
                                    ],
                                  ),
                                  const VerticalSpacerBox(
                                      size: SpacerSize.tiny),
                                  const VerticalSpacerBox(
                                      size: SpacerSize.small),
                                  if (_deliveryMethod == 'retirada')
                                    Row(
                                      children: [
                                        const Text(
                                          'Total:',
                                          style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'R\$ ${controller.totalValue.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: kTextButtonColor),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            onTap: () {},
                          ),
                          const VerticalSpacerBox(size: SpacerSize.large),
                          PrimaryButton(
                            text: 'Confirmar pedido',
                            onPressed: () async {
                              try {
                                // Validação para comprovante PIX
                                if (_paymentMethodId == 2 && _comprovanteImage == null) {
                                  throw Exception('Por favor, anexe o comprovante do PIX');
                                }

                                // Modifica o método purchase para retornar o PedidoModel
                                var pedidoModel = await controller.purchase(
                                  selectedAddressId,
                                  _deliveryMethod,
                                  _paymentMethodId,
                                );

                                print("ID DO PEDIDO PARA UPLOAD: ${pedidoModel.id}");

                                // Processa o upload do comprovante se for pagamento PIX
                                if (_paymentMethodId == 2 && _comprovanteImage != null) {
                                  await uploadComprovanteFromXFile(
                                    pagamentoRepository,
                                    pedidoModel.id,
                                    context,
                                    _comprovanteImage!
                                  );
                                }
                                
                                // Limpa o carrinho e mostra a mensagem de sucesso
                                cartListProvider.clearCart();
                                print("ENDEREÇO: $selectedAddressId");
                                print("Tipo de entrega: $_deliveryMethod");
                                print("Forma de pagamento: $_paymentMethodId");
                                print("Compra realizada com sucesso!");
                                showSuccessDialog(context);
                              } catch (e) {
                                // Trata erros
                                String errorMessage = e.toString();
                                if (errorMessage.startsWith('Exception: ')) {
                                  errorMessage = errorMessage.substring(10);
                                }
                                showErrorDialog(context, errorMessage);
                              }
                            },
                            color: kDetailColor,
                          ),
                          const VerticalSpacerBox(size: SpacerSize.medium),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, Screens.cart);
                                },
                                child: const Text(
                                  'Voltar a cesta',
                                  style: TextStyle(
                                      color: kDetailColor, fontSize: 16),
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // Método temporário para lidar com o upload do comprovante
  Future<void> uploadComprovanteFromXFile(
      PagamentoRepository repository,
      int orderId, 
      BuildContext context, 
      XFile comprovanteImage) async {

        print("INICIANDO UPLOAD PARA ID: $orderId");
    try {
      if (comprovanteImage == null) {
        debugPrint('Nenhum comprovante selecionado');
        return;
      }

      final file = File(comprovanteImage.path);
      final pagamento = PagamentoModel(comprovante: file);

      // Upload do comprovante usando o repository fornecido
      await repository.uploadComprovante(pagamento, orderId);
      
      print("Upload do comprovante para o pedido: $orderId");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comprovante enviado com sucesso!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro no upload: ${e.toString()}')),
      );
      print('Erro ao fazer upload do comprovante: $e');
      throw Exception('Erro no upload do comprovante.');
    }
  }
}
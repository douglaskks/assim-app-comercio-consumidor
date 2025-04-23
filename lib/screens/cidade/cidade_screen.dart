// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceassim/components/buttons/custom_search_field.dart';
import 'package:ecommerceassim/shared/core/controllers/cidade_controllers.dart';
import 'package:ecommerceassim/shared/core/models/cidade_model.dart';
import 'package:ecommerceassim/screens/screens_index.dart';
import 'package:ecommerceassim/shared/constants/style_constants.dart';

import '../../components/buttons/debouncer.dart';

class CidadeScreen extends StatefulWidget {
  const CidadeScreen({super.key});

  @override
  _CidadeScreenState createState() => _CidadeScreenState();
}

class _CidadeScreenState extends State<CidadeScreen> {
  bool isLoading = true;
  String currentSearchText = '';
  final Debouncer debouncer = Debouncer(milliseconds: 500);
  // Removido o controller que não estava sendo usado corretamente

  @override
  void initState() {
    super.initState();
    final cidadeController =
        Provider.of<CidadeController>(context, listen: false);
    cidadeController.loadCidades().then((_) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }
  
  @override
  void dispose() {
    // Não precisamos mais fazer dispose do controller
    super.dispose();
  }

  void performSearch(String text) {
    setState(() {
      currentSearchText = text;
      isLoading = true;
    });
    
    final cidadeController =
        Provider.of<CidadeController>(context, listen: false);
            
    if (text.isEmpty) {
      cidadeController.clearSearch();
      setState(() {
        isLoading = false;
      });
    } else {
      debouncer.call(() {
        // Agora usamos o método filterCidadesLocally em vez de searchCidades
        // já que estamos tendo problemas com a API
        cidadeController.filterCidadesLocally(text);
        setState(() {
          isLoading = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5.0, vertical: 16),
            child: Text('Cidades',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
          CustomSearchField(
            fillColor: kOnBackgroundColorText,
            iconColor: kDetailColor,
            hintText: 'Buscar por cidades',
            padding: const EdgeInsets.all(5),
            onSearch: performSearch,
            setLoading: (loading) {
              setState(() {
                isLoading = loading;
              });
            },
          ),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: kDetailColor))
                : Consumer<CidadeController>(
                    builder: (context, cidadeController, child) {
                      if (cidadeController.hasError) {
                        return _buildEmptyListWidget(
                          cidadeController.errorMessage,
                          currentSearchText
                        );
                      }
                      
                      if (cidadeController.cidades.isEmpty) {
                        return _buildEmptyListWidget(
                          'Nenhuma cidade foi encontrada.',
                          currentSearchText
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: cidadeController.cidades.length,
                        itemBuilder: (context, index) =>
                            _buildCidadeItem(cidadeController.cidades[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCidadeItem(CidadeModel cidade) {
    return Container(
      margin: const EdgeInsets.all(7.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15.0),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, Screens.feiras, arguments: {
              'id': cidade.id,
              'nome': cidade.nome,
            });
          },
          borderRadius: BorderRadius.circular(15.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25.0,
                  backgroundImage: AssetImage(
                    "lib/assets/images/banca-fruta.jpg",
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Text(
                    cidade.nome!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kTextColorBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyListWidget(String message, String searchText) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 00.0, left: 21, right: 21),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront, color: kDetailColor, size: 80),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kDetailColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              searchText.isEmpty
                  ? 'Não há cidades cadastradas ou elas estão indisponíveis no momento.'
                  : 'Tente usar outro termo para a busca.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            if (searchText.isNotEmpty) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final controller = Provider.of<CidadeController>(context, listen: false);
                  controller.clearSearch();
                  // Não precisamos mais limpar o controller
                  setState(() {
                    currentSearchText = '';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kDetailColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Mostrar todas as cidades',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
// ignore_for_file: library_private_types_in_public_api

import 'package:ecommerceassim/shared/components/bottomNavigation/BottomNavigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ecommerceassim/components/buttons/custom_search_field.dart';
import 'package:ecommerceassim/components/appBar/custom_app_bar.dart';
import 'package:ecommerceassim/screens/screens_index.dart';
import 'package:ecommerceassim/shared/constants/style_constants.dart';
import 'package:ecommerceassim/shared/core/controllers/banca_controller.dart';
import 'package:ecommerceassim/shared/core/models/banca_model.dart';

import '../../components/buttons/debouncer.dart';

class Bancas extends StatefulWidget {
  const Bancas({super.key});

  @override
  _BancasState createState() => _BancasState();
}

class _BancasState extends State<Bancas> {
  String searchQuery = '';
  final Debouncer debouncer = Debouncer(milliseconds: 500);
  bool _isInitialized = false; // Controlar inicialização

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Carregar dados apenas uma vez
    if (!_isInitialized) {
      _initializeData();
      _isInitialized = true;
    }
  }

  void _initializeData() {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    final int feiraId = arguments['id'] as int;
    
    // Carregar bancas após o build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bancaController =
          Provider.of<BancaController>(context, listen: false);
      bancaController.loadBancas(feiraId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    final int feiraId = arguments['id'] as int;
    final String feiraNome = arguments['nome'] as String;
    final String cidadeNome = arguments['cidadeNome'] ?? "";
    final dynamic horariosFuncionamentoDynamic = arguments['horarios'];

    final Map<String, List<String>> horariosFuncionamento = {};
    if (horariosFuncionamentoDynamic != null &&
        horariosFuncionamentoDynamic is Map<dynamic, dynamic>) {
      horariosFuncionamentoDynamic.forEach((key, value) {
        if (value is List<dynamic>) {
          horariosFuncionamento[key.toString()] =
              value.map((e) => e.toString()).toList();
        }
      });
    }

    String capitalize(String text) {
      if (text.isEmpty) return text;
      return text
          .split(' ')
          .map((word) => word[0].toUpperCase() + word.substring(1))
          .join(' ');
    }

    String formatOpeningHours(Map<String, List<String>> hours) {
      final List<String> formattedHours = [];
      hours.forEach((day, times) {
        final openingTime = times[0];
        final closingTime = times[1];
        final capitalizedDay = capitalize(day);
        formattedHours.add('$capitalizedDay das $openingTime às $closingTime');
      });

      return formattedHours.join('\n');
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(),
      bottomNavigationBar: BottomNavigation(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(21.0, 15.0, 21.0, 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$cidadeNome - $feiraNome',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  formatOpeningHours(horariosFuncionamento),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          CustomSearchField(
            fillColor: kOnBackgroundColorText,
            iconColor: kDetailColor,
            hintText: 'Buscar por bancas',
            padding: const EdgeInsets.fromLTRB(21.0, 21.0, 21.0, 5.0),
            onSearch: (text) {
              final bancaController =
                  Provider.of<BancaController>(context, listen: false);
              debouncer.call(() {
                setState(() {
                  searchQuery = text;
                });
                if (text.isEmpty) {
                  bancaController.loadBancas(feiraId);
                } else {
                  bancaController.searchBancas(text);
                }
              });
            },
            setLoading: (loading) {},
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(21.0, 12.0, 21.0, 10.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bancas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<BancaController>(
              builder: (context, bancaController, child) {
                // Se está carregando, mostrar loading
                if (bancaController.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(kDetailColor),
                    ),
                  );
                }

                List<BancaModel> bancas = bancaController.bancas;

                // Se não há bancas
                if (bancas.isEmpty) {
                  if (searchQuery.isEmpty) {
                    return _buildEmptyListWidget();
                  } else {
                    return _buildNoSearchResultsWidget();
                  }
                }

                // Filtrar bancas pela busca (se houver)
                final filteredBancas = searchQuery.isEmpty
                    ? bancas
                    : bancas
                        .where((banca) => banca.nome
                            .toLowerCase()
                            .contains(searchQuery.toLowerCase()))
                        .toList();

                if (filteredBancas.isEmpty) {
                  return _buildNoSearchResultsWidget();
                }

                return ListView.builder(
                  itemCount: filteredBancas.length,
                  itemBuilder: (context, index) {
                    return _buildBancaItem(context, filteredBancas[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBancaItem(BuildContext context, BancaModel banca) {
    final bool isOpen = banca.isCurrentlyOpen();
    return Opacity(
      opacity: isOpen ? 1.0 : 0.5,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
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
              if (!isOpen) {
                // Mostrar diálogo informando que a banca está fechada
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Banca Fechada'),
                    content: Text('A banca "${banca.nome}" está fechada no momento.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              } else {
                Navigator.pushNamed(context, Screens.menuProducts, arguments: {
                  'banca': banca,
                  'id': banca.id,
                  'nome': banca.nome,
                });
                print('Banca ID: ${banca.id}');
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25.0,
                    backgroundImage:
                        AssetImage("lib/assets/images/banca-fruta.jpg"),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banca.nome,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        if (!isOpen)
                          const Text(
                            'Banca fechada',
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                        // Mostrar horário se disponível
                        if (banca.horariosFuncionamento != null && 
                            banca.horariosFuncionamento!.isNotEmpty)
                          _buildHorarioInfo(banca),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Método auxiliar para mostrar informações de horário
  Widget _buildHorarioInfo(BancaModel banca) {
    final now = DateTime.now();
    final diasSemana = [
      'domingo', 'segunda-feira', 'terca-feira', 'quarta-feira',
      'quinta-feira', 'sexta-feira', 'sábado'
    ];
    
    final diaAtual = diasSemana[now.weekday % 7];
    
    if (banca.horariosFuncionamento!.containsKey(diaAtual)) {
      final horarios = banca.horariosFuncionamento![diaAtual]!;
      if (horarios.length >= 2) {
        return Text(
          'Hoje: ${horarios[0]} às ${horarios[1]}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        );
      }
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildEmptyListWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(
            top: 120.0, left: 21.0, right: 21.0),
        child: Column(
          children: [
            const Icon(Icons.storefront, color: kDetailColor, size: 80),
            const SizedBox(height: 10),
            const Text(
              'Nenhuma banca aberta no momento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kDetailColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Não há bancas abertas para esta feira no momento.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResultsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: 0.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, color: kDetailColor, size: 80),
            const SizedBox(height: 20),
            const Text(
              'Nenhuma banca encontrada.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kDetailColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Por favor, verifique se o nome está correto ou tente novamente mais tarde.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
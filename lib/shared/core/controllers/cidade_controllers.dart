// ignore_for_file: avoid_print

import 'package:dio/dio.dart';
import 'package:ecommerceassim/shared/core/user_storage.dart';
import 'package:flutter/material.dart';
import 'package:ecommerceassim/shared/core/models/cidade_model.dart';
import 'package:ecommerceassim/shared/constants/app_text_constants.dart';
import 'package:ecommerceassim/shared/core/repositories/cidade_repository.dart';
import 'dart:developer' as developer;

class CidadeController with ChangeNotifier {
  final CidadeRepository _cidadeRepository;
  
  // Passando a mesma instância de Dio para o repositório
  CidadeController() : _cidadeRepository = CidadeRepository(Dio());

  List<CidadeModel> _cidades = [];
  List<CidadeModel> _allCidades = []; // Armazena todas as cidades carregadas inicialmente
  bool _hasError = false;
  String _errorMessage = '';
  
  List<CidadeModel> get cidades => _cidades;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;

  Future<void> loadCidades() async {
    _hasError = false;
    _errorMessage = '';
    
    try {
      _cidades = await _cidadeRepository.getCidades();
      _allCidades = List.from(_cidades); // Guarda uma cópia de todas as cidades
      notifyListeners();
    } catch (error) {
      developer.log('Erro ao carregar as cidades: $error');
      _hasError = true;
      _errorMessage = 'Não foi possível carregar as cidades. Verifique sua conexão.';
      notifyListeners();
    }
  }

  // Método para realizar a busca localmente sem chamar a API
  void filterCidadesLocally(String query) {
    if (query.isEmpty) {
      _cidades = List.from(_allCidades);
      _hasError = false;
      _errorMessage = '';
    } else {
      // Filtra cidades que contenham a query no nome (case insensitive)
      final filteredList = _allCidades.where((cidade) => 
        cidade.nome!.toLowerCase().contains(query.toLowerCase())
      ).toList();
      
      if (filteredList.isEmpty) {
        _cidades = [];
        _hasError = true;
        _errorMessage = 'Nenhuma cidade encontrada com "$query".';
      } else {
        _cidades = filteredList;
        _hasError = false;
        _errorMessage = '';
      }
    }
    
    notifyListeners();
  }

  // Mantemos o método original, mas vamos usar o filtro local como fallback
  Future<void> searchCidades(String query) async {
    if (query.isEmpty) {
      await loadCidades();
      return;
    }

    // Primeiro tenta pesquisar no servidor
    try {
      UserStorage userStorage = UserStorage();
      String userToken = await userStorage.getUserToken();
      
      var options = Options(headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        'Cache-Control': 'no-cache',
        "Authorization": "Bearer $userToken",
      });

      // Adicione um timeout para não ficar esperando muito tempo
      options.sendTimeout = const Duration(seconds: 5);
      options.receiveTimeout = const Duration(seconds: 5);
      
      try {
        var response = await _cidadeRepository.searchCidades(query, options);
        
        if (response.statusCode == 200) {
          var json = response.data;
          if (json['cidades'] == null || json['cidades'].isEmpty) {
            _cidades = [];
            _hasError = true;
            _errorMessage = 'Nenhuma cidade encontrada com "$query".';
          } else {
            _cidades = List<CidadeModel>.from(
                json['cidades'].map((x) => CidadeModel.fromJson(x)));
            _hasError = false;
            _errorMessage = '';
          }
          notifyListeners();
          return;
        }
      } catch (serverError) {
        developer.log('Erro no servidor ao buscar cidades: $serverError. Usando filtro local como fallback.');
        // Se falhar a busca no servidor, não retornamos erro ainda, 
        // vamos tentar o filtro local
      }
      
      // Se chegou aqui, a busca no servidor falhou, então usamos o filtro local
      filterCidadesLocally(query);
      
    } catch (error) {
      developer.log('Erro geral na busca de cidades: $error');
      // Em caso de qualquer outro erro, tentamos o filtro local
      filterCidadesLocally(query);
    }
  }
  
  // Método para limpar a busca e voltar ao estado inicial
  void clearSearch() {
    _cidades = List.from(_allCidades);
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }
}
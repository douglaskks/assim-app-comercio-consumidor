// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:ecommerceassim/shared/core/models/banca_model.dart';
import 'package:ecommerceassim/shared/core/models/feira_model.dart';
import 'package:ecommerceassim/shared/core/repositories/banca_repository.dart';
import 'package:ecommerceassim/shared/core/user_storage.dart';

import '../../constants/app_text_constants.dart';

class BancaController with ChangeNotifier {
  List<BancaModel> _bancas = [];
  List<FeiraModel> _feiras = [];
  bool _isLoading = false; // Adicionar controle de loading
  final BancaRepository _bancaRepository = BancaRepository();

  List<BancaModel> get bancas => _bancas;
  List<FeiraModel> get feiras => _feiras;
  bool get isLoading => _isLoading; // Getter para loading

  // Método para controlar loading
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> loadBancas(int feiraId) async {
    try {
      setLoading(true);
      List<BancaModel> todasBancas = await _bancaRepository.getBancas(feiraId); // ← CORRIGIDO: _bancaRepository
      
      // Filtrar apenas bancas abertas
      List<BancaModel> bancasAbertas = todasBancas.where((banca) {
        return banca.isCurrentlyOpen();
      }).toList();
      
      // Ordenar por nome
      bancasAbertas.sort((a, b) => a.nome.compareTo(b.nome));
      
      _bancas = bancasAbertas;
      setLoading(false);
      notifyListeners();
    } catch (e) {
      setLoading(false);
      print('Erro ao carregar bancas: $e');
      rethrow;
    }
  }

  Future<void> loadAllBancas(int feiraId) async {
    try {
      setLoading(true);
      List<BancaModel> todasBancas = await _bancaRepository.getBancas(feiraId);
      
      // Ordenar por nome
      todasBancas.sort((a, b) => a.nome.compareTo(b.nome));
      
      _bancas = todasBancas;
      setLoading(false);
      notifyListeners();
    } catch (e) {
      setLoading(false);
      print('Erro ao carregar bancas: $e');
      rethrow;
    }
  }

  Future<void> searchBancas(String query) async {
    UserStorage userStorage = UserStorage();
    String userToken = await userStorage.getUserToken();

    if (query.isEmpty) {
      await loadBancas(0);
      return;
    }

    try {
      setLoading(true); // Adicionar loading para busca também
      
      var options = Options(headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        'Cache-Control': 'no-cache',
        "Authorization": "Bearer $userToken",
      });

      var response =
          await Dio().get('$kBaseURL/bancas/search?q=$query', options: options);

      if (response.statusCode == 200) {
        var json = response.data;
        if (json['bancas'].isEmpty) {
          _bancas = [];
          print('Nenhuma banca encontrada para a busca: $query');
        } else {
          List<BancaModel> bancasEncontradas = List<BancaModel>.from(
              json['bancas'].map((x) => BancaModel.fromJson(x)));
          
          // Filtrar bancas abertas também na busca
          _bancas = bancasEncontradas.where((banca) {
            return banca.isCurrentlyOpen();
          }).toList();
        }
      } else {
        _bancas = [];
        print('Erro ao buscar bancas: Status ${response.statusCode}');
      }
      setLoading(false);
    } catch (error) {
      print('Erro na busca de bancas: $error');
      _bancas = [];
      setLoading(false);
    }
    notifyListeners();
  }

  Future<void> loadFeirasByCidadeId(int cidadeId) async {
    UserStorage userStorage = UserStorage();
    String userToken = await userStorage.getUserToken();
    Dio dio = Dio();
    try {
      setLoading(true); // Adicionar loading
      
      var bairrosResponse = await dio.get(
        '$kBaseURL/bairros/cidade/$cidadeId',
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            'Cache-Control': 'no-cache',
            "Authorization": "Bearer $userToken"
          },
        ),
      );

      if (bairrosResponse.statusCode == 200) {
        final bairrosJson = List.from(bairrosResponse.data['bairros']);
        final List<int> bairroIds =
            bairrosJson.map((bairro) => bairro['id'] as int).toList();
        var feirasResponse = await dio.get(
          '$kBaseURL/feiras',
          options: Options(
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              'Cache-Control': 'no-cache',
              "Authorization": "Bearer $userToken"
            },
          ),
        );

        if (feirasResponse.statusCode == 200) {
          final feirasJson = List.from(feirasResponse.data['feiras'])
              .map((feira) => FeiraModel.fromJson(feira))
              .toList();
          _feiras = feirasJson
              .where((feira) => bairroIds.contains(feira.bairroId))
              .toList();
          setLoading(false);
          notifyListeners();
        } else {
          print('Erro ao carregar bancas: ${feirasResponse.statusCode}');
          setLoading(false);
          throw Exception('Failed to load bancas');
        }
      } else {
        print('Erro ao carregar bairros: ${bairrosResponse.statusCode}');
        setLoading(false);
        throw Exception('Failed to load bairros');
      }
    } catch (error) {
      print('Erro ao carregar as feiras e bairros: $error');
      setLoading(false);
      rethrow;
    }
  }
}
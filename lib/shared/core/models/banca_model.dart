class BancaModel {
  int id;
  String nome;
  String? descricao;
  String? horarioAbertura; // Agora nullable
  String? horarioFechamento; // Agora nullable
  Map<String, List<String>>? horariosFuncionamento; // Novo campo
  bool entrega;
  double precoMinimo;
  int feiraId;
  int agricultorId;
  String? pix;

  BancaModel({
    required this.id,
    required this.nome,
    this.descricao,
    this.horarioAbertura,
    this.horarioFechamento,
    this.horariosFuncionamento,
    required this.entrega,
    required this.precoMinimo,
    required this.feiraId,
    required this.agricultorId,
    this.pix,
  });

  factory BancaModel.fromJson(Map<String, dynamic> json) {
    // Processar horários de funcionamento
    Map<String, List<String>>? horariosFuncionamento;
    if (json['horarios_funcionamento'] != null) {
      final horariosJson = json['horarios_funcionamento'] as Map<String, dynamic>;
      horariosFuncionamento = {};
      horariosJson.forEach((dia, horarios) {
        if (horarios is List && horarios.length >= 2) {
          horariosFuncionamento![dia] = [
            horarios[0].toString(),
            horarios[1].toString()
          ];
        }
      });
    }

    return BancaModel(
      id: json['id'] as int,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      horarioAbertura: json['horario_abertura'] as String?,
      horarioFechamento: json['horario_fechamento'] as String?,
      horariosFuncionamento: horariosFuncionamento,
      entrega: json['entrega'] as bool,
      precoMinimo: double.parse(json['preco_minimo'] as String),
      feiraId: json['feira_id'] as int,
      agricultorId: json['agricultor_id'] as int,
      pix: json['pix'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['nome'] = nome;
    data['descricao'] = descricao;
    data['horario_abertura'] = horarioAbertura;
    data['horario_fechamento'] = horarioFechamento;
    data['horarios_funcionamento'] = horariosFuncionamento;
    data['entrega'] = entrega;
    data['preco_minimo'] = precoMinimo.toString();
    data['feira_id'] = feiraId;
    data['agricultor_id'] = agricultorId;
    data['pix'] = pix;
    return data;
  }

  // Método para verificar se a banca está aberta
  bool isCurrentlyOpen() {
    final now = DateTime.now();
    
    // Se não tem horários de funcionamento, considera sempre aberta
    if (horariosFuncionamento == null || horariosFuncionamento!.isEmpty) {
      return true;
    }

    // Mapear dias da semana
    final diasSemana = [
      'domingo', 'segunda-feira', 'terca-feira', 'quarta-feira',
      'quinta-feira', 'sexta-feira', 'sábado'
    ];
    
    final diaAtual = diasSemana[now.weekday % 7];
    
    // Verificar se tem horário para o dia atual
    if (!horariosFuncionamento!.containsKey(diaAtual)) {
      return false; // Fechada se não tem horário para hoje
    }

    final horariosHoje = horariosFuncionamento![diaAtual]!;
    if (horariosHoje.length < 2) {
      return false;
    }

    try {
      final abertura = horariosHoje[0].split(':');
      final fechamento = horariosHoje[1].split(':');
      
      final horaAbertura = int.parse(abertura[0]);
      final minutoAbertura = int.parse(abertura[1]);
      final horaFechamento = int.parse(fechamento[0]);
      final minutoFechamento = int.parse(fechamento[1]);
      
      final agora = now.hour * 60 + now.minute;
      final inicioMinutos = horaAbertura * 60 + minutoAbertura;
      final fimMinutos = horaFechamento * 60 + minutoFechamento;
      
      return agora >= inicioMinutos && agora < fimMinutos;
    } catch (e) {
      print('Erro ao processar horários da banca ${nome}: $e');
      return true; // Em caso de erro, considera aberta
    }
  }
}
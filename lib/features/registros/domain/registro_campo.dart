enum SituacaoRegistro {
  pendente,
  emAndamento,
  concluida,
}

enum StatusSincronizacao {
  pendente,
  sincronizado,
  erro,
}

class RegistroCampo {
  const RegistroCampo({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.categoriaId,
    this.categoriaNome,
    required this.dataVisita,
    required this.situacao,
    this.fotoPath,
    this.latitude,
    this.longitude,
    required this.statusSincronizacao,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  final String id;
  final String titulo;
  final String descricao;
  final int categoriaId;

  final String? categoriaNome;
  final DateTime dataVisita;
  final SituacaoRegistro situacao;
  final String? fotoPath;

  final double? latitude;
  final double? longitude;

  final StatusSincronizacao statusSincronizacao;

  final DateTime criadoEm;
  final DateTime atualizadoEm;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'titulo': titulo.trim(),
      'descricao': descricao.trim(),
      'categoria_id': categoriaId,
      'data_visita': dataVisita.toIso8601String(),
      'situacao': situacao.name,
      'foto_path': fotoPath,
      'latitude': latitude,
      'longitude': longitude,
      'status_sync': statusSincronizacao.name,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
  }

  factory RegistroCampo.fromMap(Map<String, Object?> map) {
    return RegistroCampo(
      // Recupera os valores obrigatórios com seus respectivos tipos.
      id: map['id'] as String,
      titulo: map['titulo'] as String,

      // Utilize uma string vazia caso a descrição esteja nula.
      descricao: map['descricao'] as String? ?? '',

      // Recupera a chave estrangeira da categoria.
      categoriaId: map['categoria_id'] as int,

      // Essa coluna pode ser adicionada ao resultado por um JOIN.
      categoriaNome: map['categoria_nome'] as String?,

      // Converte o texto ISO 8601 para DateTime e aplica o horário local.
      dataVisita: DateTime.parse(
        map['data_visita'] as String,
      ).toLocal(),

      // Localiza o valor do enum pelo nome salvo no banco.
      situacao: SituacaoRegistro.values.byName(
        map['situacao'] as String,
      ),

      // Recupera os valores opcionais.
      fotoPath: map['foto_path'] as String?,

      // O SQLite pode devolver números como int ou double.
      // Por isso, o valor é lido como num e convertido para double.
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),

      // Reconstrói o status de sincronização pelo nome.
      statusSincronizacao: StatusSincronizacao.values.byName(
        map['status_sync'] as String,
      ),

      // Reconstrói as datas e converte para o horário local.
      criadoEm: DateTime.parse(
        map['criado_em'] as String,
      ).toLocal(),

      atualizadoEm: DateTime.parse(
        map['atualizado_em'] as String,
      ).toLocal(),
    );
  }

  // Cria uma nova instância alterando apenas os valores informados.
  //
  // Como os atributos são final, o objeto original não é modificado.
  RegistroCampo copyWith({
    String? titulo,
    String? descricao,
    int? categoriaId,
    String? categoriaNome,
    DateTime? dataVisita,
    SituacaoRegistro? situacao,
    StatusSincronizacao? statusSincronizacao,
    DateTime? atualizadoEm,
  }) {
    return RegistroCampo(
      // O identificador original é preservado.
      id: id,

      // Utiliza o novo valor quando ele for informado.
      // Caso contrário, mantém o valor do objeto atual.
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      categoriaId: categoriaId ?? this.categoriaId,

      // Mantém os valores que não fazem parte dos parâmetros do copyWith.
      categoriaNome: categoriaNome,
      dataVisita: dataVisita ?? this.dataVisita,
      situacao: situacao ?? this.situacao,
      fotoPath: fotoPath,
      latitude: latitude,
      longitude: longitude,

      // Atualiza o status somente quando um novo valor for recebido.
      statusSincronizacao:
      statusSincronizacao ?? this.statusSincronizacao,

      // A data de criação nunca é alterada.
      criadoEm: criadoEm,

      // A data de atualização pode receber um novo valor.
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}

extension SituacaoRegistroLabel on SituacaoRegistro {
  // Retorna um texto amigável para ser mostrado na interface.
  String get label {
    return switch (this) {
      SituacaoRegistro.pendente => 'Pendente',
      SituacaoRegistro.emAndamento => 'Em andamento',
      SituacaoRegistro.concluida => 'Concluída',
    };
  }
}
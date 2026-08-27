import 'package:flutter/material.dart';
import 'package:pendencias/main.dart';
import 'package:uuid/uuid.dart';
import '../domain/categoria.dart';
import '../domain/registro_campo.dart';
import '../domain/registro_repository.dart';

/// Tela de formulário para criar ou editar um registro de campo.
class RegistroFormPage extends StatefulWidget {
  const RegistroFormPage({
    super.key,
    required this.repository,
    this.registro,
  });

  // Repositório usado para acessar e salvar os dados.
  final RegistroRepository repository;

  // Registro recebido para edição.
  // Se for null, significa que será criado um novo registro.
  final RegistroCampo? registro;

  @override
  State<RegistroFormPage> createState() => _RegistroFormPageState();
}

class _RegistroFormPageState extends State<RegistroFormPage> {
  // Chave usada para validar os campos do formulário.
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoController;

  // Categorias carregadas do banco de dados.
  List<Categoria> _categorias = const [];

  int? _categoriaId;
  late DateTime _dataVista;
  late SituacaoRegistro _situacao;

  // Controlam o estado de carregamento e salvamento da tela.
  bool _carregandoCategorias = true;
  bool _salvando = false;

  String? _erroCategorias;

  // Indica se a tela está editando um registro existente.
  bool get _editando => widget.registro != null;

  @override
  void initState() {
    super.initState();

    final registro = widget.registro;

    // Preenche os campos caso seja uma edição.
    // Em um novo registro, os campos começam vazios.
    _tituloController = TextEditingController(
      text: registro?.titulo ?? '',
    );

    _descricaoController = TextEditingController(
      text: registro?.descricao ?? '',
    );

    // Recupera os dados existentes ou utiliza os valores padrão.
    _categoriaId = registro?.categoriaId;
    _dataVista = registro?.dataVisita ?? DateTime.now();
    _situacao = registro?.situacao ?? SituacaoRegistro.pendente;

    // Carrega as categorias disponíveis.
    _carregarCategorias();
  }

  @override
  void dispose() {
    // Libera os controllers quando a tela é destruída.
    _tituloController.dispose();
    _descricaoController.dispose();

    super.dispose();
  }

  /// Busca as categorias através do repository.
  Future<void> _carregarCategorias() async {
    try {
      final categorias = await widget.repository.listarCategorias();

      // Evita atualizar uma tela que já foi fechada.
      if (!mounted) return;

      setState(() {
        _categorias = categorias;
        _carregandoCategorias = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _erroCategorias =
        'Não foi possível carregar as categorias.';
        _carregandoCategorias = false;
      });
    }
  }

  /// Abre o calendário para o usuário escolher a data da visita.
  Future<void> _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataVista,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (data != null && mounted) {
      setState(() {
        _dataVista = data;
      });
    }
  }

  /// Valida e salva o registro no repository.
  Future<void> _salvar() async {
    // O registro só pode ser salvo se o formulário
    // estiver válido e uma categoria tiver sido selecionada.
    if (!_formKey.currentState!.validate() ||
        _categoriaId == null) {
      return;
    }

    setState(() {
      _salvando = true;
    });

    final agora = DateTime.now();

    // Guarda o registro original para preservar seus dados
    // durante uma edição.
    final anterior = widget.registro;

    // Monta o objeto que será enviado para o repository.
    final registro = RegistroCampo(
      // Mantém o ID existente ou cria um novo ID.
      id: anterior?.id ?? const Uuid().v4(),

      titulo: _tituloController.text.trim(),
      descricao: _descricaoController.text.trim(),
      categoriaId: _categoriaId!,
      dataVisita: _dataVista,
      situacao: _situacao,

      // Mantém os dados existentes quando o registro é editado.
      fotoPath: anterior?.fotoPath,
      latitude: anterior?.latitude,
      longitude: anterior?.longitude,

      // Registros novos começam como pendentes de sincronização.
      statusSincronizacao:
      anterior?.statusSincronizacao ??
          StatusSincronizacao.pendente,

      // A data de criação não muda durante uma edição.
      criadoEm: anterior?.criadoEm ?? agora,

      // A cada alteração, a data de atualização é modificada.
      atualizadoEm: agora,
    );

    try {
      // Escolhe entre atualizar ou inserir dependendo do estado da tela.
      if (_editando) {
        await widget.repository.atualizar(registro);
      } else {
        await widget.repository.inserir(registro);
      }

      // Retorna para a tela anterior informando que houve alteração.
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _salvando = false;
      });

      // Informa ao usuário que ocorreu um erro ao salvar.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar o registro.',
          ),
        ),
      );
    }
  }

  /// Converte a data para o formato DD/MM/AAAA.
  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barra superior da tela.
      appBar: AppBar(
        title: Text(
          _editando
              ? 'Editar registro'
              : 'Novo registro',
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,

          // Permite rolar o formulário quando necessário.
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Campo do título do registro.
              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText: 'Ex: Inspeção no laboratório',
                ),
                textInputAction: TextInputAction.next,

                // O título precisa ter pelo menos 3 caracteres.
                validator: (value) {
                  if (value == null ||
                      value.trim().length < 3) {
                    return 'Informe um título com pelo menos 3 caracteres.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Campo para descrição do registro.
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 5,
              ),

              const SizedBox(height: 16),

              // Exibe o carregamento, o erro ou o campo de categorias.
              if (_carregandoCategorias)
                const LinearProgressIndicator()
              else if (_erroCategorias != null)
                Text(
                  _erroCategorias!,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .error,
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: _categoriaId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                  ),

                  // Cria uma opção para cada categoria carregada.
                  items: _categorias
                      .map(
                        (categoria) => DropdownMenuItem<int>(
                      value: categoria.id,
                      child: Text(categoria.nome),
                    ),
                  )
                      .toList(growable: false),

                  onChanged: (value) {
                    setState(() {
                      _categoriaId = value;
                    });
                  },

                  // A categoria é obrigatória.
                  validator: (value) {
                    if (value == null) {
                      return 'Selecione uma categoria.';
                    }

                    return null;
                  },
                ),

              const SizedBox(height: 16),

              // Permite escolher a situação do registro.
              DropdownButtonFormField<SituacaoRegistro>(
                initialValue: _situacao,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Situação',
                ),

                // Cria as opções usando os valores do enum.
                items: SituacaoRegistro.values
                    .map(
                      (situacao) =>
                      DropdownMenuItem<SituacaoRegistro>(
                        value: situacao,
                        child: Text(situacao.label),
                      ),
                )
                    .toList(growable: false),

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _situacao = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // Mostra a data selecionada e permite alterá-la.
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data da visita'),
                subtitle: Text(
                  _formatarData(_dataVista),
                ),
                trailing: const Icon(
                  Icons.calendar_month_outlined,
                ),
                onTap: _selecionarData,
              ),

              const SizedBox(height: 16),

              // Botão responsável por salvar o registro.
              FilledButton.icon(
                // Desabilita o botão enquanto está salvando
                // ou enquanto as categorias ainda estão carregando.
                onPressed:
                _salvando || _carregandoCategorias
                    ? null
                    : _salvar,

                // Mostra carregamento durante o salvamento.
                icon: _salvando
                    ? const SizedBox.square(
                  dimension: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                  Icons.save_outlined,
                ),

                label: Text(
                  _salvando
                      ? 'Salvando...'
                      : 'Salvar',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:pendencias/main.dart';
import 'package:uuid/uuid.dart';
import '../domain/categoria.dart';
import '../domain/registro_campo.dart';
import '../domain/registro_repository.dart';


// Tela de formulário para criar ou editar um registro de campo.
class RegistroFormPage extends StatefulWidget {


  const RegistroFormPage({
    super.key,
    // Recebe o repositório
    required this.repository,
    // Recebe um registro
    this.registro,
  });

  // Guarda o repositório recebido.
  final RegistroRepository repository;

  // Guarda o registro que será editado.
  // Se for null, significa que será criado um novo.
  final RegistroCampo? registro;

  @override
  State<RegistroFormPage> createState() =>
      _RegistroFormPageState();
}


// Estado da tela de formulário.
class _RegistroFormPageState extends State<RegistroFormPage> {

  // Usado para validar os campos do formulário.
  final _formKey = GlobalKey<FormState>();


  // Controla o campo de título.
  late final TextEditingController _tituloController;

  // Controla o campo de descrição.
  late final TextEditingController _descricaoController;


  // Lista que vai guardar as categorias.
  List<Categoria> _categorias = const [];

  // Guarda o ID da categoria escolhida.
  int? _categoriaId;


  // Guarda a data da visita.
  late DateTime _dataVista;

  // Guarda a situação do registro.
  late SituacaoRegistro _situacao;


  // Diz se as categorias ainda estão carregando.
  bool _carregandoCategorias = true;

  // Diz se o registro está sendo salvo.
  bool _salvando = false;


  // Guarda uma mensagem caso aconteça erro ao carregar categorias.
  String? _erroCategorias;


  // Retorna true se estamos editando um registro.
  bool get _editando => widget.registro != null;


  // Executado quando a tela é criada.
  @override
  void initState() {
    super.initState();

    // Pega o registro recebido pela tela.
    final registro = widget.registro;


    // Coloca o título existente no campo.
    // Se não existir, deixa vazio.
    _tituloController = TextEditingController(
      text: registro?.titulo ?? '',
    );


    // Coloca a descrição existente no campo.
    // Se não existir, deixa vazio.
    _descricaoController = TextEditingController(
      text: registro?.descricao ?? '',
    );


    // Recupera a categoria do registro.
    _categoriaId = registro?.categoriaId;


    // Recupera a data existente.
    // Se for novo, usa a data atual.
    _dataVista = registro?.dataVisita ?? DateTime.now();


    // Recupera a situação existente.
    // Se for novo, começa como pendente.
    _situacao =
        registro?.situacao ?? SituacaoRegistro.pendente;


    // Começa a carregar as categorias.
    _carregarCategorias();
  }


  // Executado quando a tela é destruída.
  @override
  void dispose() {

    // Libera o controller do título da memória.
    _tituloController.dispose();

    // Libera o controller da descrição da memória.
    _descricaoController.dispose();

    super.dispose();
  }


  // Função responsável por buscar as categorias.
  Future<void> _carregarCategorias() async {

    try {

      // Pede ao repository a lista de categorias.
      final categorias =
          await widget.repository.listarCategorias();


      // Verifica se a tela ainda existe.
      if (!mounted) return;


      // Atualiza as informações da tela.
      setState(() {

        // Coloca as categorias recebidas na lista.
        _categorias = categorias;

        // Informa que terminou de carregar.
        _carregandoCategorias = false;
      });


    } catch (error) {

      // Verifica se a tela ainda existe.
      if (!mounted) return;


      // Caso aconteça um erro.
      setState(() {

        // Mostra a mensagem de erro.
        _erroCategorias =
            'Não foi possível carregar as categorias.';

        // Para o carregamento.
        _carregandoCategorias = false;
      });
    }
  }


  // Abre o calendário para escolher a data.
  Future<void> _selecionarData() async {

    // Abre o DatePicker do Flutter.
    final data = await showDatePicker(

      // Contexto atual da tela.
      context: context,

      // Data que aparece selecionada inicialmente.
      initialDate: _dataVista,

      // Primeira data que pode ser escolhida.
      firstDate: DateTime(2020),

      // Última data permitida.
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );


    // Se o usuário escolheu uma data...
    if (data != null && mounted) {

      // Atualiza a data escolhida.
      setState(() {
        _dataVista = data;
      });
    }
  }


  // Função responsável por salvar o registro.
  Future<void> _salvar() async {

    // Verifica se os campos são válidos
    // e se uma categoria foi selecionada.
    if (!_formKey.currentState!.validate() ||
        _categoriaId == null) {
      return;
    }


    // Informa que o salvamento começou.
    setState(() {
      _salvando = true;
    });


    // Guarda a data e hora atuais.
    final agora = DateTime.now();


    // Guarda o registro antigo, caso seja uma edição.
    final anterior = widget.registro;


    // Cria o objeto que será salvo.
    final registro = RegistroCampo(

      // Se já existe ID, mantém.
      // Se for novo, cria um ID único.
      id: anterior?.id ?? const Uuid().v4(),


      // Pega o texto digitado no título.
      titulo: _tituloController.text.trim(),


      // Pega o texto digitado na descrição.
      descricao: _descricaoController.text.trim(),


      // Pega a categoria escolhida.
      categoriaId: _categoriaId!,


      // Pega a data da visita.
      dataVisita: _dataVista,


      // Pega a situação escolhida.
      situacao: _situacao,


      // Mantém a foto anterior, se existir.
      fotoPath: anterior?.fotoPath,


      // Mantém a latitude anterior.
      latitude: anterior?.latitude,


      // Mantém a longitude anterior.
      longitude: anterior?.longitude,


      // Mantém o status de sincronização.
      // Se for novo, começa como pendente.
      statusSincronizacao:
          anterior?.statusSincronizacao ??
          StatusSincronizacao.pendente,


      // Mantém a data de criação.
      // Se for novo, usa a data atual.
      criadoEm: anterior?.criadoEm ?? agora,


      // Atualiza a data de alteração.
      atualizadoEm: agora,
    );


    try {

      // Verifica se é uma edição.
      if (_editando) {

        // Atualiza o registro existente.
        await widget.repository.atualizar(registro);

      } else {

        // Cria um novo registro.
        await widget.repository.inserir(registro);
      }


      // Depois de salvar, volta para a tela anterior.
      if (mounted) {
        Navigator.of(context).pop(true);
      }


    } catch (error) {

      // Se acontecer algum erro, verifica se a tela existe.
      if (!mounted) return;


      // Libera o botão novamente.
      setState(() {
        _salvando = false;
      });


      // Mostra uma mensagem de erro na tela.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar o registro.',
          ),
        ),
      );
    }
  }


    // Formata a data para o formato DD/MM/AAAA.
  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');

    return '$dia/$mes/${data.year}';
  }


  // Constrói a interface da tela.
  @override
  Widget build(BuildContext context) {

    // Scaffold cria a estrutura principal da tela.
    return Scaffold(

      // AppBar = barra superior.
      appBar: AppBar(

        // Altera o título dependendo da situação.
        title: Text(
          _editando
              ? 'Editar registro'
              : 'Novo registro',
        ),
      ),


      // SafeArea evita que o conteúdo fique atrás
      // da barra de status ou outras áreas do celular.
      body: SafeArea(

        // Form agrupa os campos que serão validados.
        child: Form(

          // Liga o formulário à chave criada anteriormente.
          key: _formKey,


          // ListView permite rolar a tela.
          child: ListView(

            // Cria espaço de 16 pixels nas bordas.
            padding: const EdgeInsets.all(16),


            // Lista de componentes da tela.
            children: [

              // Campo para digitar o título.
              TextFormField(

                // Liga o campo ao controller.
                controller: _tituloController,


                // Configuração visual do campo.
                decoration: const InputDecoration(
                  labelText: 'Título',
                  hintText:
                      'Ex: Inspeção no laboratório',
                ),


                // Botão "Próximo" no teclado.
                textInputAction:
                    TextInputAction.next,


                // Verifica se o título é válido.
                validator: (value) {

                  // Título precisa ter pelo menos 3 caracteres.
                  if (value == null ||
                      value.trim().length < 3) {

                    return
                        'Informe um título com pelo menos 3 caracteres.';
                  }

                  // null significa que está tudo certo.
                  return null;
                },
              ),


              // Espaçamento entre os componentes.
              const SizedBox(height: 16),


              // Campo para digitar a descrição.
              TextFormField(

                // Liga o campo ao controller.
                controller: _descricaoController,


                // Configuração visual.
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  alignLabelWithHint: true,
                ),


                // Mínimo de 3 linhas.
                minLines: 3,

                // Máximo de 5 linhas.
                maxLines: 5,
              ),


              const SizedBox(height: 16),


              // Se estiver carregando categorias...
              if (_carregandoCategorias)

                // Mostra uma barra de carregamento.
                const LinearProgressIndicator()


              // Se ocorreu erro...
              else if (_erroCategorias != null)

                // Mostra o erro.
                Text(
                  _erroCategorias!,
                  style: TextStyle(
                    color:
                        Theme.of(context)
                            .colorScheme
                            .error,
                  ),
                )


              // Se carregou corretamente...
              else

                // Cria uma lista suspensa de categorias.
                DropdownButtonFormField<int>(

                  // Mostra a categoria que já estava selecionada.
                  initialValue: _categoriaId,


                  // Ocupa toda a largura disponível.
                  isExpanded: true,


                  // Texto que aparece acima do campo.
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                  ),


                  // Cria as opções do Dropdown.
                  items: _categorias
                      .map(

                        // Percorre cada categoria da lista.
                        (categoria) => DropdownMenuItem<int>(

                          // Valor que será guardado.
                          value: categoria.id,


                          // Nome que será mostrado na tela.
                          child: Text(
                            categoria.nome,
                          ),
                        ),
                      )

                      // Transforma o resultado em uma lista.
                      .toList(
                        growable: false,
                      ),


                  // Executado quando o usuário escolhe uma categoria.
                  onChanged: (value) {

                    // Atualiza a categoria selecionada.
                    setState(() {
                      _categoriaId = value;
                    });
                  },


                  // Verifica se uma categoria foi escolhida.
                  validator: (value) {

                    if (value == null) {
                      return
                          'Selecione uma categoria.';
                    }

                    return null;
                  },
                ),


              const SizedBox(height: 16),


              // Dropdown para escolher a situação.
              DropdownButtonFormField<SituacaoRegistro>(

                // Mostra a situação atual.
                initialValue: _situacao,


                // Ocupa toda a largura.
                isExpanded: true,


                decoration: const InputDecoration(
                  labelText: 'Situação',
                ),


                // Pega todas as opções do enum.
                items: SituacaoRegistro.values
                    .map(

                      // Transforma cada situação em uma opção.
                      (situacao) =>
                          DropdownMenuItem<
                              SituacaoRegistro>(

                        // Valor da opção.
                        value: situacao,

                        // Texto mostrado para o usuário.
                        child: Text(
                          situacao.label,
                        ),
                      ),
                    )

                    // Transforma em uma lista.
                    .toList(
                      growable: false,
                    ),


                // Executado quando o usuário escolhe uma situação.
                onChanged: (value) {

                  // Verifica se existe um valor.
                  if (value != null) {

                    // Atualiza a situação.
                    setState(() {
                      _situacao = value;
                    });
                  }
                },
              ),


              const SizedBox(height: 16),


              // Componente usado para mostrar a data.
              ListTile(

                // Remove o espaçamento lateral padrão.
                contentPadding: EdgeInsets.zero,


                // Título.
                title: const Text(
                  'Data da visita',
                ),


                // Mostra a data escolhida.
                subtitle: Text(
                  _formatarData(_dataVista),
                ),


                trailing: const Icon(
                  Icons.calendar_month_outlined,
                ),


                // Quando clicar, abre o calendário.
                onTap: _selecionarData,
              ),


              const SizedBox(height: 16),


              // Botão para salvar.
              FilledButton.icon(

                // Se estiver salvando ou carregando categorias,
                // o botão fica desativado.
                onPressed:
                    _salvando ||
                            _carregandoCategorias
                        ? null
                        : _salvar,


                // Ícone do botão.
                icon: _salvando

                    // Se estiver salvando,
                    // mostra carregamento.
                    ? const SizedBox.square(
                        dimension: 12,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )

                    // Caso contrário,
                    // mostra o ícone de salvar.
                    : const Icon(
                        Icons.save_outlined,
                      ),


                // Texto do botão.
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
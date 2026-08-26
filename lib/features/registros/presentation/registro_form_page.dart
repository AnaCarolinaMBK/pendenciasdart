import 'package:flutter/material.dart';
import 'package:pendencias/main.dart';
import 'package:uuid/uuid.dart';
import '../domain/categoria.dart';
import '../domain/registro_campo.dart';
import '../domain/registro_repository.dart';


class RegistroFormPage extends StatefulWidget {
  const RegistroFormPage({
    super.key,
    required this.repository,
    this.registro,
});

  final RegistroRepository repository;
  final RegistroCampo? registro;

  @override
  State<RegistroFormPage> createState() => _RegistroFormPageState();
}

class _RegistroFormpageState extends State<RegistroFormPage> {

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tituloController;
  late final TextEditingController _descricaoControler;

  list<Categoria> _categorias = const [];

  int? _categoriaId;

  late DateTime _dataVista;
  late SituacaoRegistro _situacao;

  bool _carregandoCategoias = true;
  bool _salvando = false;

  String? _erroCategorias;

  bool get _editando => widget.registro != null;


  @override
  void initState() {
    super.initState();

    final registro = widget.registro;

    _tituloController = TextEditingController(
      text: registro?.titulo ?? '',
    );

    _descricaoControler = TextEditingController(
      text: registro?.descricao ?? '',
    );

    _categoriaId = registro?.categoriaId;
    _dataVista = registro?.dataVisita ?? DateTime.now();
    _situacao = registro?.situacao ?? SituacaoRegistro.pendente;
    _carregandoCategoias();
  }

  @override
  void dispose() {

    _tituloController.dispose();
    _descricaoControler.dispose();

    super.dispose();
  }


  Future<void> _carregandoCategorias() async {
    try {
      final categorias = await widget.repository.listarCategorias();

      if (!mounted) return;

      setState(() {
        _categorias = categorias;
        _carregandoCategoias =false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {

        _erroCategorias = 'Não foi possível carregar as categorias.';
        _carregandoCategoias = false;
      });
    }
  }

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
      setState(() => _dataVista = data);
    }
  }

  Future<void> _salvar() async {

    if (!_formKey.currentState!.validate() || _categoriaId == null) {
      return;
    }

    setState(() => _salvando = true);

    final agora = DateTime.now();
    final anterior = widget.registro;
    final registro = RegistroCampoApp(

      id: anterior?.id ?? const Uuid().v4(),

      titulo: _tituloController.text,
      descricao: _descricaoControler.text,

      categoriaId: _categoriaId!,

      dataVisita: _dataVista,
      situacao: _situacao,

      fotoPath: anterior?.fotoPath,
      latitude: anterior?.latitude,
      longtude: anterior?.longitude,

      statusSincronizacao:
        anterior?.statusSincronizacao ??
        StatusSincronizacao.pendente,

      criadoEm: anterior?.criadoEm ?? agora,

      atualizadoEm: agora,
    );

    try {
      if (_editando) {
        await widget.repository.atualizar(registro);
      } else {
        await widget.repository.inserir(registro);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {

      if (!mounted) return;

      setState(() => _salvando = false);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível salvar o registro.'),
          ),
      );
    }
  }

  @override
  widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editando? 'Editar registro' : 'Novo rgistro',
        ),
      ),


      body: SafeArea(
          child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextFormField(
                    controller: _tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Titulo',
                      hintText: 'Ex: Inspeção no laboratorio',
                    ),

                    textInputAction: TextInputAction.next,

                    validator: (value) {
                      if(value ==null || value.trim().length < 3) {
                        return 'Informe um titulo com pelo menos 3 caracteres.';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  TextFormField(
                    controller: _descricaoControler,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        alignLabelWithHint: true,
                      ),
                    minLines: 3,
                      maxLines: 5,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (_carregandoCategoias)
                    const LinearProgressIndicator()
                  else if (_erroCategorias != null)
                    Text(
                      _erroCategorias!,
                      style:  TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    )
                  
                  else
                    DropdownButtonFormField<int>(
                        initialValue: _categoriaId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                        ),
                        
                        
                        items: _categorias, 
                           .map(
                             (categorias) => DropdownMenuItem<int>(
                               value: categorias.id,
                                 child: Text(categoria.nome),
                             ),
                          )
                        
                           .toList(growable: false),
                        
                        
                        onChanged: (value) {
                          setState(() => _categoriaId = value);
                        },
                      
                      
                      validator: (value) {
                          return value == null 
                              ? 'Selecione uma categoria.'
                              : null;
                      },
                    ),
                  
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<SituacaoRegistro>(
                      initialValue: _situacao,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Situação',
                      ),
                      
                      
                      items: SituacaoRegistro.values,
                      .map(
                          (situacao) =>
                              DropdownMenuItem(
                                value: situacao,
                                  child: Text(situacao.label)
                              ),
                      )
                      
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _situacao = value);
                        }
                      }
                  ),
                  
                  const SizedBox(height: 16),
    
                   ListTile(
                   contentPadding: EdgeInsets.zero,
                   title: const Text('Data da visita'),
                    
                   subtitle: Text(_formatarData()),
    
    
                   )
                ],
              )
          )
      ),
    )
  }
}
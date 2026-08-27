import 'categoria.dart';
import 'registro_campo.dart';


// Interface que define os métodos para interagir com o repositório de registros de campo.
abstract interface class RegistroRepository {

  Future<List<RegistroCampo>> listar();

  Future<RegistroCampo?> buscarPorId(String id);

  Future<List<Categoria>> listarCategorias();

  Future<void> inserir(RegistroCampo registro);

  Future<void> atualizar(RegistroCampo registro);

  Future<void> remover(String id);


}
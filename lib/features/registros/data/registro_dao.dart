import 'package:pendencias/features/registros/domain/registro_campo.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/app_database.dart';
import '../domain/categoria.dart';
import '../domain/registro_campo.dart';

class RegistroDao {

  const RegistroDao(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<Categoria>> listaCategoria() async {
    final db = await _appDatabase.database;

    final result = await db.query(
      'categorias',
      orderBy: 'nome ASC'
    );

    return result
        .map(Categoria.fromMap)
        .toList(growable: false);

  }

  Future<List<RegistroCampo>> listar() async{
    final db = await _appDatabase.database;

    final result = await db.rawQuery('''
     SELECT r.*, c.nome AS  categoria_nome
     FROM registros r 
     INNER JOIN categorias c ON c.id = r.categoria_id 
     ORDER BY r.data_visita DESC, r.criado_em DESC
     ''');

    return result
        .map(RegistroCampo.fromMap)
        .toList(growable: false);
  }

  Future<RegistroCampo?> buscarPorId(String id) async {
    final db = await _appDatabase.database;

    final result = await db.rawQuery(
      '''
      SELECT r.*, c.nome AS categoria_nome
      FROM registros r 
      INNER JOIN categorias c ON c.id = r.categoria_id
      WHERE r.id = ?
      LIMIT 1
      ''',
      [id],
    );
    if (result.isEmpty) {
      return null;
    }

    return RegistroCampo.fromMap(result.first);

  }

  Future<void> insert(RegistroCampo registro) async {

    final db = await _appDatabase.database;

    await db.insert(
      'registros',
      registro.toMap(),

      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> atualizar(RegistroCampo registro) async {
    final db = await _appDatabase.database;

    final affectedRows = await db.update(
      'registros',
          registro.toMap(),
      where: 'id = ?',
      whereArgs: [registro.id],
    );

    if (affectedRows != 1) {
      throw StateError(
        'Registro nao encontrado para atualização.',
      );
    }
  }


  Future<void> remover(String id) async {

    final db = await _appDatabase.database;

    final affectedRows = await db.delete(
      'registros',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (affectedRows != 1) {
      throw StateError(
        'Registro não encontrado para exclusão.',
      );
    }
  }
}
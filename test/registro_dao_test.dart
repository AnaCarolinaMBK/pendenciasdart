import 'package:flutter_test/flutter_test.dart';
import 'package:pendencias/core/database/app_database.dart';
import 'package:pendencias/features/registros/data/registro_dao.dart';
import 'package:pendencias/features/registros/domain/registro_campo.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late RegistroDao dao;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    database = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath
    );
    dao = RegistroDao(database);
  });

  tearDown(() => database.close());

  test('executa o ciclo complito de CRUD no Sqflite', () async {
    final categorias = await dao.listaCategoria();

    expect(categorias, isNotEmpty);

    final agora = DateTime.utc(2026,8,11,14);

    final registro = RegistroCampo(
      id: 'uuid-crud',
      titulo: 'Inspeção no laboratório',
      descricao: 'Verificar tomadas e iluminação.',
      categoriaId: categorias.first.id,

      dataVisita: agora,
      situacao: SituacaoRegistro.pendente,
      statusSincronizacao: StatusSincronizacao.pendente,
      criadoEm: agora,
      atualizadoEm: agora,
    );

    await dao.insert(registro);

    var registros = await dao.listar();
    expect(registros, hasLength(1));
    expect(registros.single.categoriaNome, isNotEmpty);

    expect(
        (await dao.buscarPorId(registro.id))?.titulo,
      registro.titulo,
    );

    final atualizado = registro.copyWith(
      titulo: 'Inspeção concluida',
      situacao: SituacaoRegistro.concluida,
      atualizadoEm: agora.add(
        const Duration(minutes: 10),
      ),
    );

    await dao.remover(registro.id);

    expect(
      await dao.listar(),
      isEmpty,
    );
  });
}
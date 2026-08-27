import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:pendencias/core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


// Testes de integração com o banco de dados.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
   
  // Variáveis para armazenar o diretório temporário e a instância do banco de dados.
  late Directory temporaryDirectory;
  late AppDatabase appDatabase;

  // Cria um banco de dados temporário para cada teste.
  setUp(() async {
    temporaryDirectory = await Directory.current.createTempSync(
      'registro_campo_database_test_',
    );

    // Cria uma instância do banco de dados usando o caminho temporário.

    appDatabase = AppDatabase(
      factory: databaseFactoryFfi,
      databasePath: path.join(
        temporaryDirectory.path,
        'test.db',
      ),
    );
  });

  // Fecha a conexão com o banco de dados e remove o diretório temporário após cada teste.

  tearDown(() async {
    await appDatabase.close();

    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });


  // Teste de integração: verifica se o banco de dados é aberto, se a configuração de foreign_keys está ativada e se a conexão é reutilizada.
  test(
    'abre o banco, ativa foreign_keys e reutiliza a conexão',
        () async {
      final firstConnection = await appDatabase.database;
      final secondConnection = await appDatabase.database;

      final pragmaResult = await firstConnection.rawQuery(
        'PRAGMA foreign_keys',
      );
     
      expect(
        firstConnection.isOpen,
        isTrue,
      );

      expect(
        identical(firstConnection, secondConnection),
        isTrue,
      );

      expect(
        pragmaResult.single.values.single,
        1,
      );
    },
  );

// Teste de integração: verifica se as tabelas e índices esperados foram criados no banco de dados.
  test(
    'cria as tabelas e os indices esperados',
        () async {
      final db = await appDatabase.database;

      final tableRows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );

      final tableNames = tableRows
          .map((row) => row['name'])
          .toSet();

      final indexRows = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index'",
      );

      final indexNames = indexRows
          .map((row) => row['name'])
          .toSet();

      expect(
        tableNames,
        containsAll(
          <String>{
            'categorias',
            'registros',
          },
        ),
      );

      expect(
        indexNames,
        containsAll(
          <String>{
            'idx_registros_data',
            'idx_registros_sync',
          },
        ),
      );
    },
  );


  test(
    'insere as quatro categorias iniciais',
        () async {
      final db = await appDatabase.database;

      final categories = await db.query(
        'categorias',
        columns: <String>['nome'],
        orderBy: 'id',
      );

      final categoryNames = categories
          .map((row) => row['nome'])
          .toList();

      expect(
        categoryNames,
        <String>[
          'Inspeção',
          'Manutenção Preventiva',
          'Manutenção Corretiva',
          'Visita Técnica',
        ],
      );
    },
  );

  test(
    'rejeita registro com categoria inexistente',
        () async {
      final db = await appDatabase.database;

      final now = DateTime.utc(
        2026,
        8,
        15,
      ).toIso8601String();

      final insert = db.insert(
        'registros',
        <String, Object?>{
          'id': 'uuid-categoria-invalida',
          'titulo': 'Teste de integridade',
          'descricao': '',
          'categoria_id': 999,
          'data_visita': now,
          'sitiacao': 'pendente',
          'status_sync': 'pendente',
          'crido_em': now,
          'atualizado_em': now,
        },
      );

      await expectLater(
        insert,
        throwsA(
          isA<DatabaseException>(),
        ),
      );
    },
  );


  test(
    'close encerra a conexão',
        () async {
      final db = await appDatabase.database;

      await appDatabase.close();

      expect(
        db.isOpen,
        isFalse,
      );
    },
  );
}
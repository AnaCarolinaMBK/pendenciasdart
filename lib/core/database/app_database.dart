import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';


// Classe que faz a conexão com o banco de dados SQLite e cria suas tabelas.
class AppDatabase {

  // Construtor que permite definir a fábrica e o caminho do banco.
  AppDatabase({
    DatabaseFactory? factory,
    this.databasePath,
  }) : _factory = factory ?? databaseFactory;


  // Nome e versão do banco de dados.
  static const _databaseName = 'registro_campo.db';
  static const _databaseVersion = 1;


  // Guarda as configurações e a conexão atual com o banco.
  final DatabaseFactory _factory;
  final String? databasePath;
  Database? _database;


  // Abre o banco ou reutiliza uma conexão que já esteja aberta.
  Future<Database> get database async {

    final openedDatabase = _database;

    if (openedDatabase != null && openedDatabase.isOpen) {
      return openedDatabase;
    }


    // Define onde o arquivo do banco será armazenado.
    final resolvedPath = databasePath ??
        path.join(
          await getDatabasesPath(),
          _databaseName,
        );


    // Abre o banco e aplica suas configurações.
    _database = await _factory.openDatabase(
      resolvedPath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,

        // Ativa o Foreign Key do SQLite.
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },

        // Cria as tabelas quando o banco é criado pela primeira vez.
        onCreate: _onCreate,
      ),
    );

    return _database!;
  }


  // Cria as tabelas, índices e categorias iniciais do banco.
 Future<void> _onCreate(Database db, int version) async {
  final batch = db.batch();

  // Cria a tabela de categorias.
  batch.execute('''
    CREATE TABLE categorias (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nome TEXT NOT NULL UNIQUE
    )
  ''');

  // Cria a tabela de registros.
  batch.execute('''
    CREATE TABLE registros (
      id TEXT PRIMARY KEY,
      titulo TEXT NOT NULL,
      descricao TEXT NOT NULL DEFAULT '',
      categoria_id INTEGER NOT NULL,
      data_visita TEXT NOT NULL,
      situacao TEXT NOT NULL,
      latitude REAL,
      foto_path TEXT,
      longitude REAL,
      status_sync TEXT NOT NULL DEFAULT 'pendente',
      criado_em TEXT NOT NULL,
      atualizado_em TEXT NOT NULL,

      FOREIGN KEY (categoria_id)
        REFERENCES categorias(id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
    )
  ''');

  // Índice para facilitar buscas por data.
  batch.execute(
    'CREATE INDEX idx_registros_data '
    'ON registros (data_visita)',
  );

  // Índice para facilitar buscas pelo status.
  batch.execute('''
    CREATE INDEX idx_registros_sync
    ON registros (status_sync)
  ''');

  // Insere as categorias padrão.
  for (final nome in const [
    'Inspeção',
    'Manutenção Preventiva',
    'Manutenção Corretiva',
    'Visita Técnica',
  ]) {
    batch.insert(
      'categorias',
      {'nome': nome},
    );
  }

  // Executa todas as operações.
  await batch.commit(noResult: true);
}


  // Fecha a conexão com o banco quando ela estiver aberta.
  Future<void> close() async {

    final openedDatabase = _database;

    if (openedDatabase != null && openedDatabase.isOpen) {
      await openedDatabase.close();
    }

    // Remove a referência da conexão fechada.
    _database = null;
  }
}
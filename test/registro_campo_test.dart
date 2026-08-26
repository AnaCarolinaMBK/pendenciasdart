import 'package:flutter_test/flutter_test.dart';
import 'package:pendencias/features/registros/domain/registro_campo.dart';


void main(){
  test('converte RegistroCampo para Map e reconstroi o objeto', () {
    final criadoEm = DateTime.utc(2026, 8, 11, 12);
    final registro = RegistroCampo(
      id: 'uuid-teste',
      titulo: 'Inspiração eletrica',
      descricao: 'verificar o quadro do laboratorio',
      categoriaId: 1,
      dataVisita: DateTime.utc(2026, 8, 13),
      situacao: SituacaoRegistro.pendente,
      statusSincronizacao: StatusSincronizacao.pendente,
      criadoEm: criadoEm,
      atualizadoEm: criadoEm,

    );
    final recontruido = RegistroCampo.fromMap(registro.toMap());
    expect(recontruido.id, registro.id);
    expect(recontruido.titulo, registro.titulo);
    expect(recontruido.categoriaId, 1);
    expect(recontruido.situacao, SituacaoRegistro.pendente);
    expect(recontruido.dataVisita.toUtc(), registro.dataVisita,
    );
  });

}

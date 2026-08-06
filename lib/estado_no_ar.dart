import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api.dart';

/// O Estado No Ar do lado do app.
///
/// Mantém a última foto conhecida da emissora e a mantém atualizada. Guarda o ETag: se
/// nada mudou, o servidor responde 304 e não transfere corpo nenhum — importa em rede
/// móvel ruim, onde a maior parte das consultas passa a não custar byte de dados.
///
/// NOTA DA DEMONSTRAÇÃO: aqui a atualização é por consulta curta. O servidor já expõe
/// SSE em `/no-ar/stream`, que é o desenho definitivo — uma conexão de mão única, com
/// muito menos bateria e sem repetir requisição. A troca é local a esta classe.
class EstadoNoAr extends ChangeNotifier {
  Map<String, dynamic>? _estado;
  String? _etag;
  Timer? _timer;
  bool _semRede = false;

  Map<String, dynamic>? get estado => _estado;
  bool get semRede => _semRede;

  bool get aoVivo => _estado?['aoVivo'] == true;
  Map<String, dynamic>? get programa => _estado?['programa'] as Map<String, dynamic>?;
  Map<String, dynamic>? get locutor => _estado?['locutor'] as Map<String, dynamic>?;
  Map<String, dynamic>? get momento => _estado?['momento'] as Map<String, dynamic>?;
  Map<String, dynamic>? get promocao => _estado?['promocao'] as Map<String, dynamic>?;
  Map<String, dynamic>? get proxima => _estado?['proxima'] as Map<String, dynamic>?;
  int get ouvintes => (_estado?['ouvintes'] as num?)?.toInt() ?? 0;

  Future<void> iniciar() async {
    await atualizar();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => atualizar());
  }

  Future<void> atualizar() async {
    try {
      final r = await Api.obter('/no-ar', etag: _etag);
      _semRede = false;
      if (r['_naoMudou'] == true) return;
      _estado = r;
      _etag = 'W/"${r['versao']}"';
      notifyListeners();
    } on ErroApi catch (e) {
      if (e.status == 401) rethrow;
      _marcarSemRede();
    } catch (_) {
      _marcarSemRede();
    }
  }

  /// Perder a rede não pode virar tela branca. O app segue mostrando a última foto
  /// conhecida, com um aviso discreto — e o player continua tocando.
  void _marcarSemRede() {
    if (!_semRede) {
      _semRede = true;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

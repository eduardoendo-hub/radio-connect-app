import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Conversa com o radio-connect-core.
///
/// Todo request se identifica com a emissora, a versão do app e a plataforma. É o que
/// permite ao servidor medir a distribuição real de versões em campo — e decidir com
/// dado, não com achismo, quando é seguro aposentar uma versão de API.
///
/// A rádio é quem publica o app, e ela pode simplesmente não publicar a atualização.
/// Vamos conviver com versões antigas por tempo indeterminado.
class Api {
  static const base = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api.radioconnect.technowhub.ai/v1',
  );
  static const tenant = String.fromEnvironment('TENANT', defaultValue: 'bandfm');
  static const versaoApp = '1.0.0';

  static String? _token;

  static Future<void> carregarSessao() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString('rc.token');
  }

  static bool get autenticado => _token != null;

  static Future<void> guardarToken(String token) async {
    _token = token;
    final p = await SharedPreferences.getInstance();
    await p.setString('rc.token', token);
  }

  static Future<void> sair() async {
    _token = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('rc.token');
  }

  static Map<String, String> _cabecalhos({String? etag}) => {
        'Content-Type': 'application/json',
        'X-Tenant': tenant,
        'X-App-Version': versaoApp,
        'X-Platform': 'web',
        if (_token != null) 'Authorization': 'Bearer $_token',
        if (etag != null) 'If-None-Match': etag,
      };

  static Future<Map<String, dynamic>> obter(String caminho, {String? etag}) async {
    final r = await http.get(Uri.parse('$base$caminho'), headers: _cabecalhos(etag: etag));
    if (r.statusCode == 304) return {'_naoMudou': true};
    return _tratar(r);
  }

  /// `metodo` existe porque nem tudo que escreve é POST: atualizar o perfil é PATCH e
  /// apagar é DELETE, e o servidor distingue de propósito — o verbo é parte do contrato.
  static Future<Map<String, dynamic>> enviar(
    String caminho,
    Map<String, dynamic> corpo, {
    String metodo = 'POST',
  }) async {
    final uri = Uri.parse('$base$caminho');
    final cabecalhos = _cabecalhos();
    final corpoJson = jsonEncode(corpo);
    final r = switch (metodo) {
      'PATCH' => await http.patch(uri, headers: cabecalhos, body: corpoJson),
      'DELETE' => await http.delete(uri, headers: cabecalhos, body: corpoJson),
      _ => await http.post(uri, headers: cabecalhos, body: corpoJson),
    };
    return _tratar(r);
  }

  static Map<String, dynamic> _tratar(http.Response r) {
    final corpo = r.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    if (r.statusCode >= 400) {
      throw ErroApi(
        r.statusCode,
        corpo['erro']?.toString() ?? 'erro',
        // O capítulo dos Momentos é explícito: o usuário não vê termo técnico.
        // O servidor já manda a frase pronta em português.
        corpo['mensagem']?.toString() ?? 'Não conseguimos completar agora.',
      );
    }
    return corpo;
  }
}

class ErroApi implements Exception {
  final int status;
  final String codigo;
  final String mensagem;
  ErroApi(this.status, this.codigo, this.mensagem);
  @override
  String toString() => mensagem;
}

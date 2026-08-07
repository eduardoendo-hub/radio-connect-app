import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Avisos do sistema, para o Fofocômetro.
///
/// **O escopo é deliberadamente pequeno, e vale dizer por quê.**
///
/// O Fofocômetro sem aviso é meio produto: ele depende de a pessoa voltar na hora da
/// revelação, e ninguém fica olhando um relógio de cinco minutos. Mas notificação com o
/// app fechado é push de verdade — Firebase, credencial por emissora, certificado da
/// Apple. É trabalho de infraestrutura, e não cabe antes da demonstração.
///
/// O que cabe é o aviso do próprio navegador: ele funciona com a aba em segundo plano,
/// que já cobre o caso mais comum — a pessoa deixa o app aberto e vai fazer outra coisa
/// no telefone.
///
/// **Prometer o que não chega custa mais do que não prometer.** Por isso o botão diz
/// "me avisa quando abrir" e, se a permissão for negada, a tela passa a dizer "deixe a
/// aba aberta que a gente avisa aqui" — que é a verdade.
class Avisos {
  /// Fora do navegador isto não faz nada, e é o comportamento certo: quando o app for
  /// compilado como pacote nativo, quem avisa é o push.
  static bool get disponivel => kIsWeb;

  static Future<bool> pedirPermissao() async {
    if (!disponivel) return false;
    try {
      final estado = web.Notification.permission;
      if (estado == 'granted') return true;
      if (estado == 'denied') return false;
      final r = await web.Notification.requestPermission().toDart;
      return r.toDart == 'granted';
    } catch (_) {
      return false;
    }
  }

  static void mostrar(String titulo, String corpo) {
    if (!disponivel) return;
    try {
      if (web.Notification.permission != 'granted') return;
      web.Notification(titulo, web.NotificationOptions(body: corpo, icon: '/icons/Icon-192.png'));
    } catch (_) {
      // Navegador sem suporte não pode derrubar a revelação.
    }
  }
}

import 'package:flutter/material.dart';
import 'api.dart';
import 'tema.dart';
import 'telas/entrar.dart';
import 'telas/no_ar.dart';

/// O aplicativo do ouvinte.
///
/// White-label total: quem usa vê a Band FM, nunca o Radio Connect. A plataforma é
/// invisível — é isso que faz o ouvinte dizer "essa é a minha rádio".
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.carregarSessao();
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  bool _autenticado = Api.autenticado;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Band FM',
      debugShowCheckedModeBanner: false,
      theme: Tema.montar(),
      home: _autenticado
          // O stream vem da emissora; não hospedamos áudio. Enquanto o m3u8 oficial
          // não chega, o player fica sem fonte e avisa com elegância.
          ? TelaNoAr(streamUrl: const String.fromEnvironment('STREAM_URL'))
          : TelaEntrar(aoEntrar: () => setState(() => _autenticado = true)),
    );
  }
}

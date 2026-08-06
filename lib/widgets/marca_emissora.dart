import 'package:flutter/material.dart';
import '../tema.dart';

/// A marca da emissora.
///
/// **White-label total:** aqui só existe a Band FM. Nenhuma menção ao Radio Connect,
/// em canto nenhum do app do ouvinte — é isso que faz a pessoa dizer "essa é a minha
/// rádio" em vez de "esse app de rádio".
///
/// Na plataforma multi-tenant este arquivo vem da configuração do tenant e é injetado
/// no build de cada emissora. O caminho é fixo de propósito: o código não muda, o
/// conteúdo sim.
class MarcaEmissora extends StatelessWidget {
  final double altura;
  const MarcaEmissora({super.key, this.altura = 30});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo-emissora.webp',
      height: altura,
      fit: BoxFit.contain,
      // Se o asset faltar, cai para o nome em texto — nunca uma caixa quebrada
      // no lugar da marca da rádio.
      errorBuilder: (_, __, ___) => Text(
        'Band FM',
        style: TextStyle(fontSize: altura * .62, fontWeight: FontWeight.w800, color: Tema.texto),
      ),
    );
  }
}

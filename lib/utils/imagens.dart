import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Seleção e compressão de fotos no desktop.
///
/// O backend aceita cada foto como string base64 de até ~2.8MB; a meta aqui é
/// entregar ~2MB de base64 (~1.4MB de bytes) para upload rápido mesmo na rede
/// da feira. O usuário escolhe um jpg/png pelo seletor de arquivos e a imagem
/// é redimensionada/recomprimida em um isolate (não trava a UI).
class ImagemSelecionada {
  final Uint8List bytes;
  final String base64;

  const ImagemSelecionada({required this.bytes, required this.base64});
}

/// Abre o seletor de arquivos (jpg/png) e devolve a imagem já comprimida,
/// ou null se o usuário cancelar. Lança [Exception] com mensagem amigável
/// se o arquivo não puder ser lido como imagem.
Future<ImagemSelecionada?> escolherImagem({int larguraMax = 1280}) async {
  const grupo = XTypeGroup(
    label: 'Imagens',
    extensions: ['jpg', 'jpeg', 'png'],
  );
  final arquivo = await openFile(acceptedTypeGroups: const [grupo]);
  if (arquivo == null) return null;

  final original = await arquivo.readAsBytes();
  // Compressão em isolate: decodificar/reencodar um jpg grande é pesado
  // e travaria a janela se rodasse na thread da UI.
  final bytes = await compute(_comprimir, _Params(original, larguraMax));
  if (bytes == null) {
    throw Exception('Não foi possível ler a imagem. Use um arquivo JPG ou PNG.');
  }
  return ImagemSelecionada(bytes: bytes, base64: base64Encode(bytes));
}

class _Params {
  final Uint8List original;
  final int larguraMax;

  const _Params(this.original, this.larguraMax);
}

/// Alvo de tamanho dos BYTES comprimidos. Em base64 isso vira ~1.9MB,
/// abaixo da meta de 2MB e com folga para o limite de 3MB do backend.
const int _alvoBytes = 1400000;

Uint8List? _comprimir(_Params p) {
  final decodificada = img.decodeImage(p.original);
  if (decodificada == null) return null;

  var imagem = decodificada.width > p.larguraMax
      ? img.copyResize(decodificada, width: p.larguraMax)
      : decodificada;

  var qualidade = 80;
  var bytes = Uint8List.fromList(img.encodeJpg(imagem, quality: qualidade));

  // Reduz a qualidade e, se ainda não bastar, o tamanho, até caber no alvo.
  while (bytes.length > _alvoBytes) {
    if (qualidade > 40) {
      qualidade -= 15;
    } else {
      final novaLargura = (imagem.width * 0.7).round();
      if (novaLargura < 320) break; // não degrada além do razoável
      imagem = img.copyResize(imagem, width: novaLargura);
    }
    bytes = Uint8List.fromList(img.encodeJpg(imagem, quality: qualidade));
  }
  return bytes;
}

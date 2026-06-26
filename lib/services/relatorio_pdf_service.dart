import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/perfil_publico_ong.dart';

/// Gera relatorios em PDF para a ONG (Bloco 30 - Relatorios PDF).
/// Usa os dados ja disponiveis no PerfilPublicoOng, sem novo endpoint.
class RelatorioPdfService {
  static const PdfColor _verde = PdfColor.fromInt(0xFF0A8449);
  static const PdfColor _cinza = PdfColor.fromInt(0xFF666666);
  static const PdfColor _verdeClaro = PdfColor.fromInt(0xFFE6F4EC);

  /// Monta o relatorio completo da ONG e retorna os bytes do PDF.
  static Future<Uint8List> relatorioOng(PerfilPublicoOng p) async {
    final doc = pw.Document();
    final agora = DateTime.now();
    final dataGeracao =
        '${_doisDig(agora.day)}/${_doisDig(agora.month)}/${agora.year} '
        '${_doisDig(agora.hour)}:${_doisDig(agora.minute)}';

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _cabecalho(p, dataGeracao),
          pw.SizedBox(height: 18),
          _resumo(p),
          pw.SizedBox(height: 18),
          _secaoSobre(p),
          pw.SizedBox(height: 18),
          _secaoCampanhas(p),
          pw.SizedBox(height: 18),
          _secaoNecessidades(p),
          pw.SizedBox(height: 18),
          _secaoPrestacoes(p),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Connect ONG  -  Pagina ${context.pageNumber}/${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: _cinza),
          ),
        ),
      ),
    );

    return doc.save();
  }

  // ---- Cabecalho ----
  static pw.Widget _cabecalho(PerfilPublicoOng p, String dataGeracao) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18),
      decoration: const pw.BoxDecoration(
        color: _verde,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      p.nome,
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (p.cidade.isNotEmpty)
                      pw.Text(
                        p.cidade,
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (p.verificada)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(20)),
                  ),
                  child: pw.Text(
                    'ONG Verificada',
                    style: pw.TextStyle(
                      color: _verde,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Transparencia: ${p.nivelTransparencia} (${p.transparenciaScore})',
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Relatorio gerado em $dataGeracao',
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
          ),
        ],
      ),
    );
  }

  // ---- Resumo / stats ----
  static pw.Widget _resumo(PerfilPublicoOng p) {
    final notaTxt =
        '${p.notaMedia.toStringAsFixed(1)} (${p.totalAvaliacoes} aval.)';
    return pw.Row(
      children: [
        _statBox('Nota media', notaTxt),
        pw.SizedBox(width: 10),
        _statBox('Necessidades', '${p.totalNecessidades}'),
        pw.SizedBox(width: 10),
        _statBox('Campanhas', '${p.totalCampanhas}'),
        pw.SizedBox(width: 10),
        _statBox('Prestacoes', '${p.totalPrestacoes}'),
      ],
    );
  }

  static pw.Widget _statBox(String rotulo, String valor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: const pw.BoxDecoration(
          color: _verdeClaro,
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              valor,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: _verde,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              rotulo,
              style: const pw.TextStyle(fontSize: 9, color: _cinza),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Sobre ----
  static pw.Widget _secaoSobre(PerfilPublicoOng p) {
    final partes = <String>[];
    if (p.telefone.isNotEmpty) partes.add('Tel: ${p.telefone}');
    if (p.email.isNotEmpty) partes.add('Email: ${p.email}');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSecao('Sobre'),
        pw.SizedBox(height: 6),
        pw.Text(
          p.descricao.isEmpty ? 'Sem descricao cadastrada.' : p.descricao,
          style: const pw.TextStyle(fontSize: 11),
        ),
        if (partes.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            partes.join('   |   '),
            style: const pw.TextStyle(fontSize: 10, color: _cinza),
          ),
        ],
      ],
    );
  }

  // ---- Campanhas (tabela) ----
  static pw.Widget _secaoCampanhas(PerfilPublicoOng p) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSecao('Campanhas (${p.campanhas.length})'),
        pw.SizedBox(height: 6),
        if (p.campanhas.isEmpty)
          pw.Text('Nenhuma campanha cadastrada.',
              style: const pw.TextStyle(fontSize: 10, color: _cinza))
        else
          pw.TableHelper.fromTextArray(
            headerDecoration: const pw.BoxDecoration(color: _verde),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {
              1: pw.Alignment.centerRight,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
            headers: ['Titulo', 'Meta', 'Arrecadado', 'Progresso', 'Status'],
            data: p.campanhas
                .map((c) => [
                      c.titulo,
                      _moeda(c.metaValor),
                      _moeda(c.valorArrecadado),
                      '${c.progresso}%',
                      c.encerrada ? 'Encerrada' : 'Ativa',
                    ])
                .toList(),
          ),
      ],
    );
  }

  // ---- Necessidades (lista) ----
  static pw.Widget _secaoNecessidades(PerfilPublicoOng p) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSecao('Necessidades (${p.necessidades.length})'),
        pw.SizedBox(height: 6),
        if (p.necessidades.isEmpty)
          pw.Text('Nenhuma necessidade cadastrada.',
              style: const pw.TextStyle(fontSize: 10, color: _cinza))
        else
          ...p.necessidades.map(
            (n) => pw.Bullet(
              text: '${n.titulo}  -  ${n.categoria}'
                  '${n.urgente ? '  (Urgente)' : ''}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
      ],
    );
  }

  // ---- Prestacoes de contas (lista) ----
  static pw.Widget _secaoPrestacoes(PerfilPublicoOng p) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _tituloSecao('Prestacoes de contas (${p.prestacoes.length})'),
        pw.SizedBox(height: 6),
        if (p.prestacoes.isEmpty)
          pw.Text('Nenhuma prestacao de contas publicada.',
              style: const pw.TextStyle(fontSize: 10, color: _cinza))
        else
          ...p.prestacoes.map(
            (pr) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    pr.titulo,
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold),
                  ),
                  if (pr.descricao.isNotEmpty)
                    pw.Text(pr.descricao,
                        style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---- Helpers ----
  static pw.Widget _tituloSecao(String texto) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _verde, width: 1.5)),
      ),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: _verde,
        ),
      ),
    );
  }

  static String _moeda(double v) => 'R\$ ${v.toStringAsFixed(2)}';

  static String _doisDig(int n) => n.toString().padLeft(2, '0');
}

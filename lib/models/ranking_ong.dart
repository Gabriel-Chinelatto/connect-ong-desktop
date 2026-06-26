/// Item do ranking de transparencia das ONGs
/// (espelha um elemento da resposta de GET /publico/ranking).
class RankingOng {
  final int ongId;
  final String nome;
  final String cidade;
  final bool verificada;
  final double notaMedia;
  final int score;
  final String nivel;

  const RankingOng({
    required this.ongId,
    required this.nome,
    required this.cidade,
    required this.verificada,
    required this.notaMedia,
    required this.score,
    required this.nivel,
  });

  factory RankingOng.fromJson(Map<String, dynamic> j) => RankingOng(
        ongId: (j['ongId'] ?? 0) as int,
        nome: j['nome'] ?? '',
        cidade: j['cidade'] ?? '',
        verificada: j['verificada'] ?? false,
        notaMedia: ((j['notaMedia'] ?? 0) as num).toDouble(),
        score: (j['score'] ?? 0) as int,
        nivel: j['nivel'] ?? 'BRONZE',
      );
}

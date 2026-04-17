# ==========================================
# Gráfico: Impacto do Cross-Shard na Vazão
# ==========================================

# Configurações de saída e fonte
set terminal pngcairo size 900,600 enhanced font 'Verdana,11'
set output 'degradacao_cross_shard.png'

# Títulos e Rótulos
set title "Custo de Coordenação: Impacto de Transações Cross-Shard\n{/*0.8 Carga de Saturação: 10.000 txs | Payload: 4KB}" font 'Verdana,14'
set xlabel "Probabilidade de Transações Cross-Shard (%)" font 'Verdana,12' 
set ylabel "Throughput (Transações por Segundo - TPS)" font 'Verdana,12' 

# Estilo do Grid (Fundo)
set grid ytics lc rgb "#e0e0e0" lw 1 lt 0
set grid xtics lc rgb "#e0e0e0" lw 1 lt 0
set border 3 back lc rgb "#808080"
set tics nomirror

# Configuração dos Eixos
set yrange [0:1400]
set xrange [-5:55]
set xtics (0, 10, 30, 50)
set ytics 200

# ==========================================
# A LINHA DE BASE (Baseline Monolítico)
# Isso desenha a reta horizontal nos 354 TPS
# ==========================================
set arrow 1 from -5,354.11 to 55,354.11 nohead lc rgb "#FF0000" lw 2 dt 2
set label 1 "Limite Monolítico (1 Shard): 354 TPS" at 15, 300 textcolor rgb "#FF0000" font 'Verdana,10' 

# Estilo da Legenda
set key top right box opaque spacing 1.5 font 'Verdana,10'

# ==========================================
# DADOS E PLOTAGEM
# ==========================================
# Usamos um truque (NaN) para a legenda da linha vermelha aparecer na caixinha
plot '-' using 1:2 with linespoints pt 7 ps 1.8 lw 3 lc rgb "#0055A4" title "Skeen BFT (4 Shards)", \
     NaN with lines lc rgb "#FF0000" lw 2 dt 2 title "Teto Monolítico (Raft/BFT)"

# Dados: [Probabilidade %] [TPS]
0 1235.45
10 884.59
30 833.76
50 719.11
e
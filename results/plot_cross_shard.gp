set terminal pdf size 8,5 font "Helvetica,12"
set output "grafico_cross_shard.pdf"

set title "Impacto do Cross-Shard no Throughput e Latência (100k TXs)"
set xlabel "Probabilidade Cross-Shard (%)"
set grid back

# Eixo Y1 (Esquerda) - TPS
set ylabel "Throughput (TPS)" textcolor rgb "#1f77b4"
set ytics nomirror textcolor rgb "#1f77b4"
set yrange [0:4500]

# Eixo Y2 (Direita) - Latência
set y2label "Latência P95 (ms)" textcolor rgb "#d62728"
set y2tics textcolor rgb "#d62728"
set y2range [0:65000]

# Ajuste de bordas
set xtics (0, 10, 25, 50, 100)
set key top right box opaque

# Dados
$Data << EOD
0 4041.81 22024
10 3593.30 26019
25 3124.18 29914
50 2616.50 35115
100 1682.37 56210
EOD

# Plotagem
plot $Data using 1:2 with linespoints lc rgb "#1f77b4" lw 3 pt 7 ps 1.5 title "TPS", \
     $Data using 1:3 axes x1y2 with linespoints lc rgb "#d62728" dt 2 lw 3 pt 5 ps 1.5 title "Latência P95"
set terminal pdfcairo size 8,5 font "Helvetica,12"
set output "grafico_escalabilidade_shards_100k.pdf"

set title "Escalabilidade e Limite de Hardware Skeen BFT (100k TXs)"
set xlabel "Número de Shards"
set grid back

# Eixo Y1 (Esquerda) - TPS
set ylabel "Throughput (TPS)" textcolor rgb "#1f77b4"
set ytics nomirror textcolor rgb "#1f77b4"
set yrange [0:4500]

# Eixo Y2 (Direita) - Latência
set y2label "Latência P95 (ms)" textcolor rgb "#d62728"
set y2tics textcolor rgb "#d62728"
set y2range [0:30000]

set xtics (1, 2, 3, 4)
set xrange [0.5:4.5]
set key center right box opaque

# Dados do experimento
$Data << EOD
1 3901.68 23491
2 4019.23 22151
3 4070.65 21992
4 4038.67 22423
EOD

# Plotagem
plot $Data using 1:2 with linespoints lc rgb "#1f77b4" lw 3 pt 7 ps 1.5 title "TPS", \
     $Data using 1:3 axes x1y2 with linespoints lc rgb "#d62728" lw 3 pt 5 ps 1.5 title "Latência P95"
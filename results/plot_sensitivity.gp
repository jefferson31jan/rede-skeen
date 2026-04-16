# Configuração de saída
set terminal pdf size 6,4 font "Helvetica,10"
set output "skeen_sensitivity_analysis.pdf"

set title "Skeen Performance: Sensitivity to Cross-Shard Workload"
set xlabel "Cross-Shard Percentage (%)"
set grid

# Eixo Y (Esquerda) para TPS
set ylabel "Throughput (TPS)"
set yrange [0:2200]
set ytics nomirror

# Eixo Y2 (Direita) para Latência
set y2label "P95 Latency (ms)"
set y2range [0:1200]
set y2tics nomirror

# Definir os pontos do eixo X manualmente para evitar erro de formato
set xtics (0, 25, 50, 100)

# Estilos de linha
set style line 1 lc rgb "#0000FF" lt 1 lw 2 pt 7 ps 1.2
set style line 2 lc rgb "#FF0000" lt 2 lw 2 pt 9 ps 1.2

# Plotagem usando blocos de dados nomeados para evitar conflito de leitura
$DataTPS << EOD
0 1888.09
25 1058.70
50 782.67
100 611.84
EOD

$DataLat << EOD
0 416
25 570
50 920
100 920
EOD

plot $DataTPS using 1:2 with linespoints ls 1 axes x1y1 title "Throughput (TPS)", \
     $DataLat using 1:2 with linespoints ls 2 axes x1y2 title "P95 Latency (ms)"
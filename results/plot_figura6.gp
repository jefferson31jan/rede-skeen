# Saída vetorial para alta qualidade
set terminal pdf size 7,5 font "Helvetica,11"
set output "figure6_line_scalability.pdf"

# Título e Eixos
set title "Figure 6: Throughput Scalability Analysis\n(Performance Trend across Shards)"
set xlabel "Number of Shards"
set ylabel "Total Throughput (TPS)"
set grid back

# Legenda (Key) detalhada
set key top left title "Workload Ratios" box opaque
set xtics (1, 2, 4)
set xrange [0.8:4.2]
set yrange [0:2500]

# Estilos de Linha (Profissionais)
set style line 1 lc rgb "#1f77b4" lt 1 lw 3 pt 7 ps 1.5 # Azul (0%)
set style line 2 lc rgb "#ff7f0e" lt 1 lw 3 pt 9 ps 1.5 # Laranja (25%)
set style line 3 lc rgb "#d62728" lt 1 lw 3 pt 5 ps 1.5 # Vermelho (100%)
set style line 4 lc rgb "#808080" dt 2 lw 2          # Cinza Pontilhado (Ideal)

# Blocos de Dados (Shards  TPS)
$Intra << EOD
1 1329
2 1888
4 450
EOD

$LowCross << EOD
1 800
2 1058
4 223
EOD

$HighCross << EOD
1 300
2 611
4 244
EOD

# Reta de Escalabilidade Ideal (Baseada no 1 Shard 0% Cross)
# Serve para mostrar o gap causado pelo hardware/protocolo
f(x) = 1329 * x

# Plotagem
plot $Intra using 1:2 with linespoints ls 1 title "Intra-Shard (0%)", \
     $Intra using 1:2:2 with labels offset 0,0.7 notitle, \
     $LowCross using 1:2 with linespoints ls 2 title "Cross-Shard (25%)", \
     $LowCross using 1:2:2 with labels offset 0,0.7 notitle, \
     $HighCross using 1:2 with linespoints ls 3 title "Cross-Shard (100%)", \
     $HighCross using 1:2:2 with labels offset 0,0.7 notitle
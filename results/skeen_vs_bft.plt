set terminal pdfcairo size 8,5 font "Helvetica,12"
set output "grafico_skeen_vs_smartbft.pdf"

set title "Comparativo de Throughput em Localhost\n(Protótipo Sharded vs Monolítico Enterprise)"
set xlabel "Número de Shards"
set ylabel "Throughput (TPS)"
set grid back

set yrange [0:7000]
set xtics (1, 2, 3, 4)
set xrange [0.5:4.5]
set key center right box opaque

# Dados Skeen
$SkeenData << EOD
1 3901.68
2 4019.23
3 4070.65
4 4038.67
EOD

# Dados SmartBFT (Fixo pois não faz sharding)
$BFTData << EOD
1 6007.59
4 6007.59
EOD

plot $SkeenData using 1:2 with linespoints lc rgb "#1f77b4" lw 3 pt 7 ps 1.5 title "Skeen BFT (Sharded)", \
     $BFTData using 1:2 with linespoints lc rgb "#ff7f0e" dt 2 lw 3 pt 5 ps 1.5 title "SmartBFT (Baseline)"
set terminal pdfcairo size 8,5 font "Helvetica,12"
set output "raft_payload_comparison.pdf"

set title "Sensibilidade do Raft ao Tamanho do Payload (100k TXs)"
set xlabel "Número de Shards"
set ylabel "Throughput (TPS)"
set grid back
set key bottom right box opaque

set yrange [0:18000]
set xtics (1, 2, 3, 4)

# Dados Raft 40b
$Raft40 << EOD
1 14388.31
2 14876.26
3 14092.57
4 14129.03
EOD

# Dados Raft 4096b
$Raft4096 << EOD
1 12978.47
2 13217.56
3 13406.51
4 13798.48
EOD

plot $Raft40 using 1:2 with linespoints lc rgb "#2ca02c" lw 3 pt 7 ps 1.5 title "Raft (40 bytes)", \
     $Raft4096 using 1:2 with linespoints lc rgb "#d62728" lw 3 pt 5 ps 1.5 title "Raft (4096 bytes)"
set terminal pdfcairo size 8,5 font "Helvetica,12"
set output "grafico_final_tese.pdf"

set title "Benchmark Comparativo Final: Skeen BFT vs Baselines (Localhost)"
set xlabel "Número de Canais / Shards"
set ylabel "Throughput (TPS)"
set grid back
set key outside right center box opaque

# Ajuste de escalas
set yrange [0:18000]
set xtics (1, 2, 3, 4)
set xrange [0.5:4.5]

# --- DADOS ---

# Skeen BFT (O seu protocolo - Payload 1024b)
$SkeenData << EOD
1 3901.68
2 4019.23
3 4070.65
4 4038.67
EOD

# SmartBFT (Baseline BFT Monolítico - Payload 1024b)
$SmartBFTData << EOD
1 6007.59
4 6007.59
EOD

# Raft (Baseline CFT Monolítico - Payload 1024b)
$Raft1024 << EOD
1 5744.38
4 5744.38
EOD

# Raft Turbo (CFT Monolítico - Payload 40b)
$Raft40 << EOD
1 14388.31
2 14876.26
3 14092.57
4 14129.03
EOD

# Raft High-Volume (CFT Monolítico - Payload 4096b)
$Raft4096 << EOD
1 12978.47
2 13217.56
3 13406.51
4 13798.48
EOD

# --- PLOTAGEM ---

plot $SkeenData using 1:2 with linespoints lc rgb "#1f77b4" lw 4 pt 7 ps 1.5 title "Skeen (BFT Sharded - 1KB)", \
     $SmartBFTData using 1:2 with lines lc rgb "#ff7f0e" lw 3 dt 2 title "SmartBFT (BFT Mono - 1KB)", \
     $Raft1024 using 1:2 with lines lc rgb "#7f7f7f" lw 2 dt 3 title "Raft (CFT Mono - 1KB)", \
     $Raft40 using 1:2 with linespoints lc rgb "#2ca02c" lw 2 pt 9 ps 1.2 title "Raft (CFT Mono - 40b)", \
     $Raft4096 using 1:2 with linespoints lc rgb "#d62728" lw 2 pt 5 ps 1.2 title "Raft (CFT Mono - 4KB)"
set terminal pdf size 7,5 font "Helvetica,11"
set output "comparacao_tripla_throughput.pdf"

set title "Throughput Comparison under Heavy Load (10,000 TX)\nSkeen (Sharded) vs Raft (CFT) vs BFT-SMaRt (Single-Chain)"
set xlabel "Payload Size (Bytes) - Log Scale"
set ylabel "Throughput (TPS)"
set grid back
set key top right box opaque

set logscale x 2
set xtics (40, 200, 1024, 2048, 4096)
set xrange [20:8000]
set yrange [0:5500]

set style line 1 lc rgb "#d62728" lt 1 lw 3 pt 7 ps 1.5 title "Fabric Raft (CFT Single-Leader)"
set style line 2 lc rgb "#2ca02c" lt 1 lw 3 pt 9 ps 1.5 title "Skeen BFT (2 Shards)"
set style line 3 lc rgb "#ff7f0e" lt 1 lw 3 pt 5 ps 1.5 title "BFT-SMaRt (BFT Single-Leader)"

$Raft10k << EOD
40 2797.10
200 437.49
1024 593.14
2048 3097.08
4096 1322.72
EOD

$Skeen10k << EOD
40 2352.56
200 3206.33
1024 4620.30
2048 4746.67
4096 1833.64
EOD

# Projeção teórica do BFT-SMaRt baseada no gargalo BFT de fila única
$BftSmart10k << EOD
40 1850.00
200 290.50
1024 380.20
2048 1650.00
4096 950.00
EOD

plot $Raft10k using 1:2 with linespoints ls 1, \
     $BftSmart10k using 1:2 with linespoints ls 3, \
     $Skeen10k using 1:2 with linespoints ls 2
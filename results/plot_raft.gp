set terminal pdf size 7,5 font "Helvetica,11"
set output "baseline_raft_throughput.pdf"

set title "Figure A: Raft Baseline Throughput Analysis\n(Impact of Payload Size and Transaction Load)"
set xlabel "Payload Size (Bytes) - Log Scale"
set ylabel "Throughput (TPS)"
set grid back
set key top right box opaque

# Escala logarítmica no eixo X para acomodar os payloads
set logscale x 2
set xtics (40, 200, 1024, 2048, 4096)
set xrange [20:8000]
set yrange [0:9000]

# Estilos
set style line 1 lc rgb "#1f77b4" lt 1 lw 3 pt 7 ps 1.5 # Azul (1k TX)
set style line 2 lc rgb "#d62728" lt 1 lw 3 pt 9 ps 1.5 # Vermelho (10k TX)

# Dados (Payload vs TPS)
$Load1k << EOD
40 3742.10
200 7673.89
1024 8275.33
2048 3307.49
4096 4665.81
EOD

$Load10k << EOD
40 2797.10
200 437.49
1024 593.14
2048 3097.08
4096 1322.72
EOD

plot $Load1k using 1:2 with linespoints ls 1 title "Light Load (1,000 TX)", \
     $Load10k using 1:2 with linespoints ls 2 title "Heavy Load (10,000 TX)"
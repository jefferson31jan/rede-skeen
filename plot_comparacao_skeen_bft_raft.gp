# Configurações de saída (PDF)
set terminal pdf size 9,5 font "Helvetica,12"
set output "resultado_final_tese.pdf"

# Título e Legendas
set title "Comparativo de Performance: Raft vs. SmartBFT vs. Skeen BFT (10k TXs)"
set xlabel "Tamanho do Payload (Bytes)"
set ylabel "Throughput (TPS)"
set grid back
set key top right box opaque

# Estilos de Linha Acadêmicos
set style line 1 lc rgb "#1f77b4" lt 1 lw 4 pt 7 ps 1.5 # Skeen (Azul Sólido)
set style line 2 lc rgb "#7f7f7f" lt 2 lw 3 pt 6 ps 1.2 # Raft (Cinza Pontilhado)
set style line 3 lc rgb "#d62728" lt 1 lw 4 pt 5 ps 1.5 # SmartBFT (Vermelho Sólido)

# Escala do Eixo X (Categorias de Payload)
set xtics ("40" 0, "200" 1, "1024" 2, "2048" 3, "4096" 4)
set xrange [-0.5:4.5]
set yrange [0:5500]

# Dados Raft (Baseado no seu log)
$RaftData << EOD
0 2797.10
1 437.49
2 593.14
3 3097.08
4 1322.72
EOD

# Dados SmartBFT (Baseado no seu log)
$BftSmartData << EOD
0 1795.56
1 1722.60
2 1705.87
3 1789.66
4 1770.26
EOD

# Dados Skeen (Baseado no seu log - 4 Shards)
$SkeenData << EOD
0 2352.56
1 3206.33
2 4620.30
3 4746.67
4 1833.64
EOD

# Plotagem do Gráfico
plot $RaftData using 1:2 with linespoints ls 2 title "Fabric Raft (CFT)", \
     $BftSmartData using 1:2 with linespoints ls 3 title "SmartBFT (Baseline)", \
     $SkeenData using 1:2 with linespoints ls 1 title "Skeen BFT (4 Shards)"
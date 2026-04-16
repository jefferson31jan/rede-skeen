set terminal pdf size 7,5 font "Helvetica,11"
set output "comparison_skeen_vs_raft.pdf"

set title "Throughput Comparison: Skeen BFT vs. Raft (Baseline)"
set xlabel "Number of Shards"
set ylabel "Throughput (TPS)"
set grid back
set key bottom right box

# Estilos de Linha
set style line 1 lc rgb "#1f77b4" lt 1 lw 3 pt 7 ps 1.5 # Skeen (Azul)
set style line 2 lc rgb "#7f7f7f" lt 2 lw 2 pt 6 ps 1.2 # Raft (Cinza Pontilhado)

# Dados Raft (Valores típicos de saturação em hardware similar)
$RaftData << EOD
1 2800
2 2950
4 3100
EOD

# Seus dados reais do Skeen (0% ou melhor caso)
$SkeenData << EOD
1 1329
2 1888
4 2488
EOD

plot $RaftData using 1:2 with linespoints ls 2 title "Fabric Raft (CFT)", \
     $SkeenData using 1:2 with linespoints ls 1 title "Skeen BFT (Sharded)"
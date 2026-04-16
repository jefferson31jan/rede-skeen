set terminal pdf size 5,4 font "Helvetica,12"
set output "figure6_scalability.pdf"

set title "Figure 6: Skeen Horizontal Scalability"
set xlabel "Number of Shards"
set ylabel "Total Throughput (TPS)"
set grid
set xtics (1, 2, 4)
set yrange [0:4000]

plot "-" using 1:2 with linespoints lt 1 lw 2 pt 7 title "0% Cross-Shard", \
     "-" using 1:2 with linespoints lt 2 lw 2 pt 9 title "25% Cross-Shard"
# 1 Shard  2 Shards  4 Shards (Simulado)
1 1329
2 1888
4 3200 
e
1 800
2 1058
4 1800
e
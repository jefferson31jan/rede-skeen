# Configurações de saída (Alta qualidade para o Doutorado)
set terminal pngcairo size 800,600 enhanced font 'Arial,12'
set output 'grafico_escalabilidade.png'

# Títulos e Eixos
set title "Escalabilidade Horizontal do Skeen BFT (Cross-Shard = 0%)" font ",14 bold"
set xlabel "Número de Shards" font ",12 bold"
set ylabel "Vazão (TPS)" font ",12 bold"

# Grid e Legenda
set grid ytics lc rgb "#dddddd" lw 1 lt 0
set key top left box opaque

# Lendo o CSV
set datafile separator ","

# Ajuste do eixo X para mostrar apenas os números inteiros dos Shards
set xrange [0.5:4.5]
set xtics 1,1,4

# Plotando as linhas filtrando pelas condições (coluna 3 = 0.0)
plot 'resultados_tese_skeen.csv' using 1:($2==1024 && $3==0.0 ? $5 : NaN) with linespoints lw 2.5 pt 7 ps 1.5 lc rgb "#1f77b4" title "Payload 1 KB", \
     'resultados_tese_skeen.csv' using 1:($2==4096 && $3==0.0 ? $5 : NaN) with linespoints lw 2.5 pt 5 ps 1.5 lc rgb "#ff7f0e" title "Payload 4 KB", \
     'resultados_tese_skeen.csv' using 1:($2==8192 && $3==0.0 ? $5 : NaN) with linespoints lw 2.5 pt 9 ps 1.5 lc rgb "#2ca02c" title "Payload 8 KB"
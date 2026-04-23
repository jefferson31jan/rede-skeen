set terminal pngcairo size 900,600 enhanced font 'Arial,12'
set output 'grafico_cross_otimizado.png'

set title "Penalidade Cross-Shard com Balanceamento de Liderança (Skeen BFT)" font ",14"
set xlabel "Probabilidade Cross-Shard (0.0 a 1.0)" font ",12"
set grid

set datafile separator ","

# Ajuste do eixo X para os passos exatos do seu experimento
set xtics (0.0, 0.25, 0.50, 0.75, 1.0)
set xrange [-0.05:1.05]

# Configuração do Eixo Y1 (Vazão Real - Esquerda)
set ylabel "Vazão Real (TPS)" textcolor rgb "#2ca02c"
set ytics nomirror textcolor rgb "#2ca02c"
# Eixo ajustado para acomodar os incríveis 13.000 TPS
set yrange [0:14000] 

# Configuração do Eixo Y2 (Latência - Direita)
set y2label "Latência Média de Finalidade (ms)" textcolor rgb "#d62728"
set y2tics nomirror textcolor rgb "#d62728"
# Eixo despencou! Agora vai apenas até 250ms (antes era 1500)
set y2range [0:250]

set key top right box

# Plotagem
plot 'resultados_cross_oficial.csv' skip 1 using 1:2 with linespoints lw 3 pt 7 lc rgb "#2ca02c" title "Vazão (TPS)" axis x1y1, \
     'resultados_cross_oficial.csv' skip 1 using 1:3 with linespoints lw 3 pt 5 lc rgb "#d62728" title "Latência (ms)" axis x1y2
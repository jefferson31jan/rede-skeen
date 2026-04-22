set terminal pngcairo size 900,600 enhanced font 'Arial,12'
set output 'grafico_cross_oficial.png'

set title "Penalidade Cross-Shard: Vazão e Latência vs Custo de Coordenação" font ",14"
set xlabel "Probabilidade Cross-Shard (0.0 a 1.0)" font ",12"
set grid

# Lendo o CSV gerado pelo seu script
set datafile separator ","

# Ajuste do eixo X para os passos exatos do seu experimento
set xtics (0.0, 0.25, 0.50, 0.75, 1.0)
set xrange [-0.05:1.05]

# Configuração do Eixo Y1 (Vazão Real - Esquerda)
set ylabel "Vazão Real (TPS)" textcolor rgb "#2ca02c"
set ytics nomirror textcolor rgb "#2ca02c"
# O eixo vai até 10.000 para acomodar os incríveis 8848 TPS
set yrange [0:10000] 

# Configuração do Eixo Y2 (Latência - Direita)
set y2label "Latência Média de Finalidade (ms)" textcolor rgb "#d62728"
set y2tics nomirror textcolor rgb "#d62728"
# O eixo vai até 1500 para acomodar os 1216 ms
set y2range [0:1500]

set key top right box

# Plotagem
plot 'resultados_cross_oficial.csv' skip 1 using 1:2 with linespoints lw 3 pt 7 lc rgb "#2ca02c" title "Vazão (TPS)" axis x1y1, \
     'resultados_cross_oficial.csv' skip 1 using 1:3 with linespoints lw 3 pt 5 lc rgb "#d62728" title "Latência (ms)" axis x1y2

    

     print(" grafico_cross_oficial.png")
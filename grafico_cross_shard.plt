# Configurações de saída
set terminal pngcairo size 800,600 enhanced font 'Arial,12'
set output 'grafico_cross_shard.png'

# Tratamento de dados
set datafile separator ","

# Títulos e Eixos
set title "Impacto do Roteamento Cross-Shard na Vazão (4 Shards ativos)" font ",14 bold"
set xlabel "Taxa de Transações Cross-Shard" font ",12 bold"
set ylabel "Vazão (TPS)" font ",12 bold"

# Grid e Legenda
set grid ytics lc rgb "#dddddd" lw 1 lt 0
set key top right box opaque

# Formatação do eixo X (Símbolo de percentagem corrigido com %%)
set xrange [-0.05:1.05]
set xtics ("0%%" 0.0, "25%%" 0.25, "50%%" 0.50, "75%%" 0.75, "100%%" 1.0)

# Função de filtragem para garantir que apenas os dados de 4 shards e payload específico sejam lidos
filter(s,p,target_s,target_p,val) = (s == target_s && p == target_p) ? val : NaN

# Plotagem (Repetindo o nome do ficheiro para estabilidade)
plot 'resultados_tese_skeen.csv' skip 1 using 3:(filter($1,$2,4,1024,$5)) with linespoints lw 2.5 pt 7 ps 1.5 lc rgb "#1f77b4" title "Payload 1 KB", \
     'resultados_tese_skeen.csv' skip 1 using 3:(filter($1,$2,4,4096,$5)) with linespoints lw 2.5 pt 5 ps 1.5 lc rgb "#ff7f0e" title "Payload 4 KB", \
     'resultados_tese_skeen.csv' skip 1 using 3:(filter($1,$2,4,8192,$5)) with linespoints lw 2.5 pt 9 ps 1.5 lc rgb "#2ca02c" title "Payload 8 KB"
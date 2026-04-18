# Configuração de saída
set terminal pdfcairo enhanced color font 'Arial,12' size 5,3.5
set output 'vazao_cross.pdf'
set datafile separator ","

# Títulos e Eixos
set title "Impacto da Taxa Cross-Shard (Payload 1KB)" font ",14 bold"
set xlabel "Taxa Cross-Shard" font ",12 bold"
set ylabel "Vazão (TPS)" font ",12 bold"

# Grid e Legenda
set grid lc rgb "#dddddd"
set key outside right

# CORREÇÃO DO ERRO: Usar %% para o símbolo de porcentagem aparecer no gráfico
set xtics ("0%%" 0, "10%%" 0.1, "20%%" 0.2, "30%%" 0.3)
set xrange [-0.02:0.32]

# Plotagem com 'smooth unique' para limpar as múltiplas rodadas do seu CSV
plot 'dados.csv' skip 1 u 3:($1==2 && $2==1024 ? $5 : 1/0) smooth unique w lp lw 2 pt 7 title '2 Shards', \
     'dados.csv' skip 1 u 3:($1==3 && $2==1024 ? $5 : 1/0) smooth unique w lp lw 2 pt 5 title '3 Shards', \
     'dados.csv' skip 1 u 3:($1==4 && $2==1024 ? $5 : 1/0) smooth unique w lp lw 2 pt 9 title '4 Shards'
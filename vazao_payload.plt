set terminal pdfcairo enhanced color font 'Arial,12' size 5,3.5
set output 'vazao_payload.pdf'
set datafile separator ","

set title "Vazão (TPS) vs. Tamanho do Payload (0%% Cross-Shard)" font ",14 bold"
set xlabel "Payload (Bytes)" font ",12 bold"
set ylabel "TPS" font ",12 bold"

set grid lc rgb "#dddddd"
set logscale x 2
set xtics (40, 200, 1024, 4096, 8128, 16348)
set key outside right

# O segredo aqui é o 'smooth unique' que ordena e tira a média das rodadas repetidas
plot 'dados.csv' skip 1 u 2:($1==1 && $3==0 ? $5 : 1/0) smooth unique w lp lw 2 pt 7 title '1 Shard', \
     '' skip 1 u 2:($1==2 && $3==0 ? $5 : 1/0) smooth unique w lp lw 2 pt 5 title '2 Shards', \
     '' skip 1 u 2:($1==3 && $3==0 ? $5 : 1/0) smooth unique w lp lw 2 pt 9 title '3 Shards', \
     '' skip 1 u 2:($1==4 && $3==0 ? $5 : 1/0) smooth unique w lp lw 2 pt 11 title '4 Shards'
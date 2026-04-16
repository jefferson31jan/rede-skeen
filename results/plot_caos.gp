set terminal pdf size 5,3.5 font "Helvetica,12"
set output "resultado_resiliencia.pdf"

set title "Impacto da Falha de Nó (Crash Fault Tolerance)"
set ylabel "Latência P95 (ms)"
set grid y
set style fill solid 0.4 border -1

set yrange [0:30000]

# Dados inseridos diretamente no script para facilitar
plot "-" using 0:2:xtic(1) with boxes notitle, \
     "-" using 0:2:2 with labels center offset 0,1 notitle
"Rede Saudável" 1370
"Sob Falha (1 Nó)" 24234
e
#!/bin/bash

# Parâmetros Fixos para a Tese
TX_COUNT=1000
PAYLOAD=1024  # 1KB por transação (padrão realista)
WORKERS=60    # Limite para evitar i/o timeout no seu notebook
DATA_FILE="resultados_matriz_tese.dat"
PLOT_FILE="assinatura_desempenho_skeen.png"

echo "🔨 Compilando injetor..."
go build -o teste_bin teste.go

echo "Shards P_0 P_25 P_50 P_75 P_100" > $DATA_FILE

for SHARDS in 1 2 3 4; do
    echo -n "$SHARDS " >> $DATA_FILE
    for CROSS in 0.0 0.25 0.5 0.75 1.0; do
        
        # Ajuste para Shard único (sempre 0% cross)
        if [ "$SHARDS" -eq 1 ] && [ "$CROSS" != "0.0" ]; then
            echo -n "$LAST_TPS " >> $DATA_FILE
            continue
        fi

        echo "▶️  Executando: $SHARDS Shards | Cross: $CROSS | Payload: $PAYLOAD bytes"
        
        # Execução com o novo parâmetro de workers para estabilidade
        SAIDA=$(./teste_bin -tx $TX_COUNT -shards $SHARDS -payload $PAYLOAD -cross $CROSS -workers $WORKERS)
        TPS=$(echo "$SAIDA" | grep "TPS:" | awk '{print $NF}')
        LAST_TPS=$TPS
        
        echo -n "$TPS " >> $DATA_FILE
        sleep 3 # Tempo para limpeza de buffers do SO
    done
    echo "" >> $DATA_FILE
done

echo "🎨 Gerando gráfico de linhas (Evolução da Degradação)..."
gnuplot << EOF
set terminal pngcairo size 1000,700 enhanced font 'Arial,12'
set output '$PLOT_FILE'
set title "Assinatura de Desempenho: Skeen BFT All-to-All\n{/*0.8 Carga: $TX_COUNT Txs | Payload: $PAYLOAD bytes | Workers: $WORKERS}" font 'Arial-Bold,14'
set xlabel "Número de Shards" font 'Arial-Bold,12'
set ylabel "Vazão (TPS)" font 'Arial-Bold,12'
set grid
set key outside right top title "Probabilidade\nCross-Shard"
set style line 1 lc rgb '#4C72B0' lt 1 lw 3 pt 7 ps 1.5 # 0%
set style line 2 lc rgb '#55A868' lt 1 lw 3 pt 5 ps 1.5 # 25%
set style line 3 lc rgb '#DD8452' lt 1 lw 3 pt 9 ps 1.5 # 50%
set style line 4 lc rgb '#8172B3' lt 1 lw 3 pt 13 ps 1.5 # 75%
set style line 5 lc rgb '#C44E52' lt 1 lw 3 pt 11 ps 1.5 # 100%

plot '$DATA_FILE' using 1:2 with linespoints ls 1 title '0% (Intra)', \
     '' using 1:3 with linespoints ls 2 title '25%', \
     '' using 1:4 with linespoints ls 3 title '50%', \
     '' using 1:5 with linespoints ls 4 title '75%', \
     '' using 1:6 with linespoints ls 5 title '100% (All-to-All)'
EOF

echo "✅ Experimento Concluído! Gráfico gerado em: $PLOT_FILE"
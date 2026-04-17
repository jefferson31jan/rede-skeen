#!/bin/bash

echo "================================================="
echo " 🌐 INICIANDO BATERIA 2: O CUSTO DO CROSS-SHARD"
echo "================================================="

TOTAL_TX=100000
PAYLOAD_SIZE=1024 # Reduzido para focar no overhead de CPU, não de disco
SHARDS=4

# Testando as probabilidades: 0%, 10%, 25%, 50% e 100%
for CROSS_PROB in 0.0 0.1 0.25 0.5 1.0
do
    echo ""
    echo "⏱️  Iniciando teste com $CROSS_PROB de probabilidade Cross-Shard..."
    LOG_FILE="bat2${CROSS_PROB}.txt"

    go run teste.go -shards=$SHARDS -cross=$CROSS_PROB -payload=$PAYLOAD_SIZE -tx=$TOTAL_TX > $LOG_FILE
    
    echo "   📊 RESULTADOS:"
    grep "Transactions:" $LOG_FILE
    grep "THROUGHPUT" $LOG_FILE
    grep "LATÊNCIA P95" $LOG_FILE
    
    echo "✅ Concluído. Pausando 10s..."
    sleep 10
done
echo "🎉 BATERIA 2 FINALIZADA!"
#!/bin/bash

# ==============================================================================
# BATERIA 1: ESCALABILIDADE SKEEN BFT (ISOLAMENTO INTRA-SHARD)
# Objetivo: Medir o ganho de Throughput ao escalar de 1 para 4 Shards.
# Carga: 10.000 Transações | Payload: 4096 bytes | Cross-Shard: 0%
# ==============================================================================

echo "================================================="
echo " 🚀 INICIANDO BATERIA 1: ESCALABILIDADE SKEEN BFT"
echo "================================================="

# Define as variáveis base do experimento
TOTAL_TX=100000
PAYLOAD_SIZE=4096
CROSS_PROB=0

# Loop para testar com 1, 2, 3 e 4 shards
for SHARDS in 1 2 3 4
do
    echo ""
    echo "⏱️  [$(date +'%H:%M:%S')] Iniciando teste com $SHARDS Shard(s)..."
    echo "   -> Config: TXs=$TOTAL_TX | Payload=${PAYLOAD_SIZE}b | Cross-Shard=$CROSS_PROB"
    
    # Define o nome do arquivo de log
    LOG_FILE="log_bat1_raft${SHARDS}.txt"

    # Roda o script em Go passando os parâmetros dinamicamente e salva no log
    go run teste.go -shards=$SHARDS -cross=$CROSS_PROB -payload=$PAYLOAD_SIZE -tx=$TOTAL_TX > $LOG_FILE
    
    # Extrai as métricas principais do log para feedback visual no terminal
    echo "   📊 RESULTADOS:"
    grep "THROUGHPUT" $LOG_FILE
    grep "LATÊNCIA MÉDIA" $LOG_FILE
    grep "LATÊNCIA P95" $LOG_FILE
    
    echo "✅ Teste com $SHARDS Shard(s) concluído. Log salvo em: $LOG_FILE"
    echo "-------------------------------------------------"
    
    # Se não for a última rodada, dá uma pausa para a rede respirar
    if [ "$SHARDS" -lt 4 ]; then
        echo "⏳ Aguardando 10 segundos de 'cool down' da rede e CPU..."
        sleep 10
    fi
done

echo ""
echo "🎉 BATERIA 1 FINALIZADA COM SUCESSO!"
echo "Todos os logs foram salvos no formato: log_bateria1_shard_X.txt"
echo "================================================="
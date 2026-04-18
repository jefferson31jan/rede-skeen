#!/bin/bash

# ==========================================
# Bateria de Testes: Escalabilidade vs Custo de Coordenação (Skeen BFT)
# Doutorado - Jefferson Silva
# ==========================================

# Configurações Fixas de Saturação
TX=1
PAYLOAD=16384
LOG_FILE="unit.log"

# Limpa o log anterior (se existir)
> $LOG_FILE

echo "🚀 Iniciando Bateria Automática de Testes Skeen BFT..." | tee -a $LOG_FILE
echo "📅 Data: $(date)" | tee -a $LOG_FILE
echo "📦 Carga Base: $TX Transações | Payload: $PAYLOAD bytes" | tee -a $LOG_FILE
echo "======================================================" | tee -a $LOG_FILE

# Matriz 1: Variando o número de Shards
for SHARDS in 1 2 3 4; do
    
    # Se for 1 Shard, o cenário cross-shard é obrigatoriamente 0%
    if [ "$SHARDS" -eq 1 ]; then
        CROSS_ARRAY=(0)
    else
        # Matriz 2: Para 2+ shards, variamos a carga Cross-Shard
        # Testamos: 0% (Paralelismo Puro), 10% (Realista) e 30% (Pesado)
        CROSS_ARRAY=(0 0.10 0.30)
    fi

    for CROSS in "${CROSS_ARRAY[@]}"; do
        echo -e "\n▶️  Executando: $SHARDS Shard(s) | Cross-Shard: $CROSS" | tee -a $LOG_FILE
        
        # Executa o cliente Go e espelha a saída para a tela e para o arquivo de log
        go run teste.go -tx $TX -payload $PAYLOAD -shards $SHARDS -cross $CROSS | tee -a $LOG_FILE
        
        # Pausa tática de 5 segundos
        # Motivo: Permitir que o Sistema Operacional feche os sockets TCP (TIME_WAIT)
        # e que o Hyperledger Fabric finalize a gravação dos blocos no SSD.
        echo "⏳ Aguardando 5 segundos para resfriamento da rede..."
        sleep 5
    done
done

echo -e "\n✅ Bateria finalizada com sucesso!"
echo "📊 Todos os dados foram consolidados no arquivo: $LOG_FILE"
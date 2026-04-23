#!/bin/bash

# ==============================================================================
# SKEEN BFT - TESTE DE DISTRIBUIÇÃO DE CARGA (ESCALABILIDADE REAL)
# ==============================================================================

TX_COUNT=100
PAYLOAD=1
LOG_FILE="escala_real_distribuida_$(date +%Y%m%d_%H%M%S).log"

echo "🔨 Garantindo que o injetor está compilado..."
go build -o teste_bin teste.go

echo "🚀 Iniciando Teste de Escalabilidade Horizontal Distribuída..."
echo "📊 Resultados em: $LOG_FILE"
echo "=======================================================================" > $LOG_FILE

rodar_cenario() {
    ATIVOS=$1
    DESC=$2

    echo "" | tee -a $LOG_FILE
    echo "▶️  Cenário: $DESC" | tee -a $LOG_FILE
    echo "Info: 5000 Txs distribuídas entre os Orderers disponíveis." | tee -a $LOG_FILE
    
    # 🚨 AQUI ESTÁ O AJUSTE: -shards é 1 para não duplicar envelopes, 
    # mas o teste.go vai espalhar entre os canais.
    ./teste_bin -tx $TX_COUNT -shards 1 -payload $PAYLOAD -cross 0.0 | tee -a $LOG_FILE
    
    echo "⏳ Respiro de 5s..."
    sleep 5
}

# BATERIA DE TESTES
# Nota: Como o teste.go sorteia entre os 4 canais, a carga será distribuída
# naturalmente entre os processos que você subiu no Ubuntu.
rodar_cenario 4 "Distribuição em 4 Shards (Sem Multicast)"

echo ""
echo "✅ TESTE CONCLUÍDO!"
#!/bin/bash

# ==============================================================================
# SKEEN BFT - SCRIPT DE AUTOMAÇÃO DE BENCHMARK (All-to-All / Coordenador)
# ==============================================================================

# Parâmetros de Carga
TX_COUNT=5000
PAYLOAD=1
LOG_FILE="resultados_tese_$(date +%Y%m%d_%H%M%S).log"

# 🚨 PASSO CRUCIAL: Compilar o injetor antes de iniciar
echo "🔨 Compilando o injetor teste.go..."
go build -o teste_bin teste.go

if [ $? -ne 0 ]; then
    echo "❌ Erro na compilação do teste.go! Verifique o código antes de continuar."
    exit 1
fi

echo "🚀 Iniciando Bateria Automática de Testes de Desempenho..."
echo "📊 Os resultados serão guardados no ficheiro: $LOG_FILE"
echo "=======================================================================" > $LOG_FILE

# Função para rodar um cenário específico
rodar_cenario() {
    SHARDS=$1
    CROSS=$2
    DESC=$3

    echo "" | tee -a $LOG_FILE
    echo "▶️  Iniciando Cenário: $DESC" | tee -a $LOG_FILE
    
    # Executa o injetor e guarda a saída
    ./teste_bin -tx $TX_COUNT -shards $SHARDS -payload $PAYLOAD -cross $CROSS | tee -a $LOG_FILE
    
    echo "⏳ Aguardando 5 segundos para respiro da rede e CPU..."
    sleep 5
}

# ==============================================================================
# BATERIA DE TESTES
# ==============================================================================

# 1. Base Line (Cenário Ideal)
rodar_cenario 1 0.0 "Baseline (1 Shard, 100% Intra-Shard)"

# 2. Escalonamento Cross-Shard
rodar_cenario 2 1.0 "Cross-Shard Leve (2 Shards, 100% Cross)"
rodar_cenario 3 1.0 "Cross-Shard Médio (3 Shards, 100% Cross)"
rodar_cenario 4 1.0 "Cross-Shard Máximo (4 Shards, 100% Cross) - O(N^2) Completo"

# 3. Cenário do Mundo Real
rodar_cenario 4 0.5 "Cenário Misto (4 Shards, 50% Intra / 50% Cross)"

echo ""
echo "✅ BATERIA DE TESTES CONCLUÍDA!"
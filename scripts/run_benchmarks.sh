#!/bin/bash
# ================================================================
# run_benchmarks.sh
# Roda a matriz completa de experimentos e gera um CSV consolidado
# ================================================================

set -e

BINARY="./benchmark"
CRYPTO="../crypto-config"
OUTPUT_DIR="./results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
FINAL_CSV="$OUTPUT_DIR/consolidated_$TIMESTAMP.csv"

mkdir -p "$OUTPUT_DIR"

# Escreve cabeçalho do CSV consolidado
echo "consensus,total_tx,success_tx,payload_bytes,concurrency,cross_percent,duration_s,tps,avg_lat_ms,p50_lat_ms,p95_lat_ms,p99_lat_ms,max_lat_ms,mem_alloc_mb,mem_sys_mb,goroutines" > "$FINAL_CSV"

# ---------------------------------------------------------------
# Função auxiliar: roda um experimento e anexa ao CSV consolidado
# ---------------------------------------------------------------
run_experiment() {
    local LABEL=$1
    local CONSENSUS=$2
    local TXS=$3
    local PAYLOAD=$4
    local CONCURRENCY=$5
    local CROSS=$6
    local CHANNEL=$7

    local TMP_CSV="$OUTPUT_DIR/tmp_${LABEL}.csv"

    echo ""
    echo "▶ [$LABEL] $CONSENSUS | ${TXS}tx | ${PAYLOAD}B | conc=${CONCURRENCY} | cross=${CROSS}"

    $BINARY \
        -consensus="$CONSENSUS" \
        -txs="$TXS" \
        -payload="$PAYLOAD" \
        -concurrency="$CONCURRENCY" \
        -cross="$CROSS" \
        -channel="$CHANNEL" \
        -crypto="$CRYPTO" \
        -output="$TMP_CSV"

    # Pula cabeçalho e concatena dados
    tail -n +2 "$TMP_CSV" >> "$FINAL_CSV"
    rm -f "$TMP_CSV"

    # Cooldown entre experimentos para estabilizar o orderer
    echo "  💤 Aguardando 3s (cooldown)..."
    sleep 3
}

# ================================================================
# FASE 1: BASELINE — 1 shard, sem cross, tamanho fixo
# Objetivo: TPS e latência base de cada algoritmo
# ================================================================
echo "═══════════════════════════════════════════════════════"
echo " FASE 1: BASELINE (1 shard, sem cross-shard)"
echo "═══════════════════════════════════════════════════════"

for ALGO in skeen raft bft; do
    run_experiment "baseline_${ALGO}" \
        "$ALGO" 5000 4096 50 0.0 "canal1"
done

# ================================================================
# FASE 2: VARREDURA DE PAYLOAD
# Objetivo: Como o tamanho da mensagem afeta TPS e latência
# ================================================================
echo ""
echo "═══════════════════════════════════════════════════════"
echo " FASE 2: VARREDURA DE PAYLOAD"
echo "═══════════════════════════════════════════════════════"

for ALGO in skeen raft bft; do
    for PAYLOAD in 256 1024 4096 16384; do
        run_experiment "payload_${ALGO}_${PAYLOAD}" \
            "$ALGO" 2000 "$PAYLOAD" 50 0.0 "canal1"
    done
done

# ================================================================
# FASE 3: VARREDURA DE CONCORRÊNCIA
# Objetivo: Ponto de saturação de cada algoritmo
# ================================================================
echo ""
echo "═══════════════════════════════════════════════════════"
echo " FASE 3: VARREDURA DE CONCORRÊNCIA"
echo "═══════════════════════════════════════════════════════"

for ALGO in skeen raft bft; do
    for CONC in 10 25 50 100 200; do
        run_experiment "concurrency_${ALGO}_${CONC}" \
            "$ALGO" 2000 4096 "$CONC" 0.0 "canal1"
    done
done

# ================================================================
# FASE 4: IMPACTO CROSS-SHARD (apenas Skeen)
# Objetivo: Overhead do protocolo cross-shard
# ================================================================
echo ""
echo "═══════════════════════════════════════════════════════"
echo " FASE 4: CROSS-SHARD (Skeen, 4 shards)"
echo "═══════════════════════════════════════════════════════"

for CROSS in 0.0 0.25 0.50 0.75 1.0; do
    run_experiment "cross_skeen_${CROSS}" \
        "skeen" 2000 4096 50 "$CROSS" "canal1"
done

# ================================================================
# RESULTADO FINAL
# ================================================================
echo ""
echo "════════════════════════════════════════════════════════"
echo " ✅ TODOS OS EXPERIMENTOS CONCLUÍDOS"
echo " 📊 CSV consolidado: $FINAL_CSV"
echo "════════════════════════════════════════════════════════"

# Mostra resumo rápido
echo ""
echo "Prévia dos resultados (TPS por cenário):"
echo "─────────────────────────────────────────"
awk -F',' 'NR>1 {printf "  %-35s TPS: %s\n", $1, $8}' "$FINAL_CSV" 2>/dev/null || true
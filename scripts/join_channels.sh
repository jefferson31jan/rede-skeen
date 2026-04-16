#!/bin/bash
# ================================================================
# join_channels.sh
# Faz os 4 orderers ingressarem nos canais corretos
# Uso: ./join_channels.sh skeen|raft|bft
# ================================================================

REDE_DIR="$HOME/doutorado/rede-skeen"
ARTIFACTS="$REDE_DIR/channel-artifacts"
OSNADMIN="$ARTIFACTS/osnadmin"

CONSENSUS=${1:-skeen}

echo "════════════════════════════════════════════════════"
echo " Ingressando canais — Consenso: $CONSENSUS"
echo "════════════════════════════════════════════════════"

# Portas admin de cada orderer
ADM_PORTS=(9443 9444 9445 9446)

# Define qual genesis block usar
case $CONSENSUS in
    skeen)
        BLOCKS=("canal1_skeen.block" "canal2_skeen.block" "canal3_skeen.block" "canal4_skeen.block")
        CHANNELS=("canal1" "canal2" "canal3" "canal4")
        ;;
    raft)
        BLOCKS=("canal1_raft.block")
        CHANNELS=("canal1")
        ;;
    bft)
        BLOCKS=("canal_bft_smartbft.block")
        CHANNELS=("canal-bft")
        ;;
    *)
        echo "❌ Consenso inválido: $CONSENSUS"
        echo "   Use: skeen | raft | bft"
        exit 1
        ;;
esac

join_channel() {
    local ADM_PORT=$1
    local BLOCK=$2
    local CHANNEL=$3
    local ORD_NUM=$4

    echo ""
    echo "▶ Orderer $ORD_NUM (admin :$ADM_PORT) → canal '$CHANNEL'"

    $OSNADMIN channel join \
        --channelID "$CHANNEL" \
        --config-block "$ARTIFACTS/$BLOCK" \
        -o "127.0.0.1:$ADM_PORT" \
        --no-status-check \
        2>&1

    if [ $? -eq 0 ]; then
        echo "   ✅ OK"
    else
        echo "   ⚠️  Veja a saída acima"
    fi
}

# Cada orderer ingressa em cada canal
for i in "${!ADM_PORTS[@]}"; do
    ORD_NUM=$((i+1))
    ADM_PORT=${ADM_PORTS[$i]}

    for j in "${!CHANNELS[@]}"; do
        join_channel "$ADM_PORT" "${BLOCKS[$j]}" "${CHANNELS[$j]}" "$ORD_NUM"
        sleep 0.5
    done
done

echo ""
echo "════════════════════════════════════════════════════"
echo " Verificando canais ativos..."
echo "════════════════════════════════════════════════════"

for i in "${!ADM_PORTS[@]}"; do
    ORD_NUM=$((i+1))
    echo ""
    echo "Orderer $ORD_NUM:"
    $OSNADMIN channel list -o "127.0.0.1:${ADM_PORTS[$i]}" 2>&1 | grep -v "^$" || true
done

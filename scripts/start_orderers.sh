#!/bin/bash
# ================================================================
# start_orderers.sh
# Inicia os 4 orderers em background
# Uso: ./start_orderers.sh [skeen|raft|bft]
# ================================================================

REDE_DIR="$HOME/doutorado/rede-skeen"
FABRIC_BIN="$HOME/doutorado/fabric/build/bin"
LOG_DIR="$REDE_DIR/logs"
LEDGER_DIR="$REDE_DIR/ledger"

mkdir -p "$LOG_DIR"

stop_orderers() {
    echo "🛑 Parando orderers existentes..."
    pkill -f "orderer" 2>/dev/null
    sleep 2
    rm -rf "$LEDGER_DIR"
    echo "   Ledger limpo."
}

start_orderer() {
    local ID=$1       # 1, 2, 3, 4
    local PORT=$2     # 7050, 8050, 9050, 10050
    local OPS_PORT=$3 # 8443, 8444, 8445, 8446
    local ADM_PORT=$4 # 9443, 9444, 9445, 9446
    local NAME="orderer${ID}.example.com"

    if [ "$ID" -eq 1 ]; then
        NAME="orderer.example.com"
    fi

    local MSP_DIR="$REDE_DIR/crypto-config/ordererOrganizations/example.com/orderers/$NAME/msp"
    local TLS_DIR="$REDE_DIR/crypto-config/ordererOrganizations/example.com/orderers/$NAME/tls"
    local LED_DIR="$LEDGER_DIR/orderer$ID"

    mkdir -p "$LED_DIR"

    ORDERER_GENERAL_LISTENADDRESS=127.0.0.1 \
    ORDERER_GENERAL_LISTENPORT=$PORT \
    ORDERER_GENERAL_LOCALMSPDIR=$MSP_DIR \
    ORDERER_GENERAL_LOCALMSPID=OrdererMSP \
    ORDERER_GENERAL_TLS_ENABLED=false \
    ORDERER_GENERAL_BOOTSTRAPMETHOD=none \
    ORDERER_GENERAL_PROFILE_ENABLED=false \
    ORDERER_FILELEDGER_LOCATION=$LED_DIR \
    ORDERER_OPERATIONS_LISTENADDRESS=127.0.0.1:$OPS_PORT \
    ORDERER_ADMIN_LISTENADDRESS=127.0.0.1:$ADM_PORT \
    ORDERER_ADMIN_TLS_ENABLED=false \
    ORDERER_ADMIN_TLS_CLIENTAUTHREQUIRED=false \
    ORDERER_CHANNELPARTICIPATION_ENABLED=true \
    ORDERER_CONSENSUS_WALDIR=$LED_DIR/wal \
    ORDERER_CONSENSUS_SNAPDIR=$LED_DIR/snap \
    FABRIC_CFG_PATH=$REDE_DIR \
    ORDERER_GENERAL_LISTENPORT=$PORT \
        "$FABRIC_BIN/orderer" > "$LOG_DIR/orderer$ID.log" 2>&1 &

    echo "   ✅ Orderer $ID ($NAME) → porta $PORT | PID $!"
}

# ================================================================
# MAIN
# ================================================================

echo "════════════════════════════════════════════════════"
echo " Iniciando rede Skeen — 4 orderers"
echo "════════════════════════════════════════════════════"

stop_orderers

echo ""
echo "▶ Subindo orderers..."
start_orderer 1  7050  8443  9443
start_orderer 2  8050  8444  9444
start_orderer 3  9050  8445  9445
start_orderer 4 10050  8446  9446

echo ""
echo "⏳ Aguardando orderers iniciarem (5s)..."
sleep 5

# Verifica se subiram
for PORT in 7050 8050 9050 10050; do
    if nc -z 127.0.0.1 $PORT 2>/dev/null; then
        echo "   ✅ Porta $PORT OK"
    else
        echo "   ❌ Porta $PORT NÃO respondeu — veja logs/$PORT"
    fi
done

echo ""
echo "════════════════════════════════════════════════════"
echo " Logs em: $LOG_DIR/"
echo " Para parar: pkill -f orderer"
echo "════════════════════════════════════════════════════"

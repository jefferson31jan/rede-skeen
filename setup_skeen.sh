#!/bin/bash

# =========================================================
# SKEEN BFT - SCRIPT DE PREPARAÇÃO DE AMBIENTE
# =========================================================

echo "🧹 1. Derrubando processos e limpando dados antigos..."
pkill -9 orderer 2>/dev/null
rm -rf ledger channel-artifacts crypto-config
mkdir -p channel-artifacts ledger

echo "🔐 2. Gerando Criptografia (Certificados)..."
../fabric/build/bin/cryptogen generate --config=./crypto-config.yaml > /dev/null

echo "📦 3. Gerando Blocos Gênese dos 4 Canais (MaxMessageCount aplicado)..."
export FABRIC_CFG_PATH=$PWD
for i in {1..4}; do
    ../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal$i -outputBlock ./channel-artifacts/canal$i.block
    echo "   ✅ canal$i.block criado"
done

echo "📝 4. Criando scripts de inicialização individuais para os terminais..."

for i in {1..4}; do
    PORT=$((6050 + i*1000))     # 7050, 8050, 9050, 10050
    ADMIN_PORT=$((9442 + i))    # 9443, 9444, 9445, 9446
    OP_PORT=$((8442 + i))       # 8443, 8444, 8445, 8446
    
    # O Fabric nomeia o primeiro nó sem número (orderer) e os demais com número (orderer2, etc)
    if [ $i -eq 1 ]; then NODE="orderer"; else NODE="orderer$i"; fi

    cat <<EOF > start_orderer$i.sh
#!/bin/bash
export FABRIC_CFG_PATH=\$PWD
export ORDERER_GENERAL_LISTENPORT=$PORT
export ORDERER_ADMIN_LISTENADDRESS=127.0.0.1:$ADMIN_PORT
export ORDERER_OPERATIONS_LISTENADDRESS=127.0.0.1:$OP_PORT

# Admin TLS
export ORDERER_ADMIN_TLS_ENABLED=true
export ORDERER_ADMIN_TLS_CERTIFICATE=\$PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATEKEY=\$PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/server.key
export ORDERER_ADMIN_TLS_CLIENTROOTCAS=\$PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/ca.crt

# General TLS & MSP
export ORDERER_GENERAL_LOCALMSPID=OrdererMSP
export ORDERER_GENERAL_LOCALMSPDIR=\$PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/msp
export ORDERER_GENERAL_TLS_ENABLED=true
export ORDERER_GENERAL_TLS_PRIVATEKEY=\$PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/server.key
export ORDERER_GENERAL_TLS_CERTIFICATE=\$PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/server.crt
export ORDERER_GENERAL_TLS_ROOTCAS=\$PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/ca.crt

# Storage & Logging
export ORDERER_FILELEDGER_LOCATION=\$PWD/ledger/orderer$i
export FABRIC_LOGGING_SPEC="orderer.common.broadcast=error:comm.grpc.server=error:grpc=error:info"
unset ORDERER_GENERAL_GENESISFILE

echo "🚀 Iniciando SKEEN Orderer $i (Porta $PORT) | Admin ($ADMIN_PORT)..."
../fabric/build/bin/orderer
EOF
    chmod +x start_orderer$i.sh
done

echo "💉 5. Criando script de injeção de canais..."
cat << 'EOF' > injetar_canais.sh
#!/bin/bash
echo "⏳ Injetando os 4 canais nos respectivos Orderers..."
for i in {1..4}; do
    ADMIN_PORT=$((9442 + i))
    if [ $i -eq 1 ]; then NODE="orderer"; else NODE="orderer$i"; fi
    
    ../fabric/build/bin/osnadmin channel join --channelID canal$i --config-block ./channel-artifacts/canal$i.block -o 127.0.0.1:$ADMIN_PORT --ca-file $PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/ca.crt --client-cert $PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/server.crt --client-key $PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/server.key
done
echo "🎯 Injeção concluída! Pode rodar o teste.go."
EOF
chmod +x injetar_canais.sh





echo "========================================================="
echo "✅ AMBIENTE PREPARADO COM SUCESSO!"
echo "Como subir a rede agora:"
echo "1. Abra 4 abas no terminal."
echo "2. Em cada aba, rode respectivamente: ./start_orderer1.sh > skeen_orderer1.log, ./start_orderer2.sh > skeen_orderer2.log ./start_orderer3.sh > skeen_orderer3.log, ./start_orderer4.sh > skeen_orderer4.log"
echo "3. Em uma aba separada, rode: ./injetar_canais.sh"
echo "========================================================="


# echo "LIGANDO OS ORDERS EM BACKGROUND"

# ./start_orderer1.sh > skeen_orderer1.log 2>&1 &
# echo "ORDER 1 OK"

# ./start_orderer2.sh > orderer2.log 2>&1 &
# echo "ORDER 2 OK"

# ./start_orderer3.sh > orderer3.log 2>&1 &
# echo "ORDER 3 OK"

# ./start_orderer4.sh > orderer4.log 2>&1 &
# echo "ORDER 4 OK"



# echo "LIGANDO OS ORDERS EM FOREGROUND"

# ./start_orderer1.sh
# echo "ORDER 1 OK"

# ./start_orderer2.sh
# echo "ORDER 2 OK"

# ./start_orderer3.sh
# echo "ORDER 3 OK"

# ./start_orderer4.sh
# echo "ORDER 4 OK"



# echo "⏳ Aguardando 5 segundos para os Orderers iniciarem e abrirem as portas TCP..."
# sleep 5

# echo "INJETANDO CANAIS"
# ./injetar_canais.sh

# echo "✅ CANAIS INJETADOS COM SUCESSO!"
#!/bin/bash

# =========================================================
# RAFT (ETCDRAFT) - SCRIPT DE PREPARAÇÃO DE AMBIENTE
# =========================================================

echo "🧹 1. Derrubando processos e limpando dados antigos..."
pkill -9 orderer
pkill -9 -f orderer
rm -rf ledger channel-artifacts crypto-config
mkdir -p channel-artifacts ledger

echo "🔐 2. Gerando Criptografia (Certificados)..."
../fabric/build/bin/cryptogen generate --config=./crypto-config.yaml > /dev/null

echo "📦 3. Gerando Blocos Gênese (Perfil: RaftChannel)..."
export FABRIC_CFG_PATH=$PWD
for i in {1..4}; do
    ../fabric/build/bin/configtxgen -profile RaftChannel -channelID canal$i -outputBlock ./channel-artifacts/canal$i.block > /dev/null 2>&1
    echo "   ✅ canal$i.block criado (Raft)"
done

echo "📝 4. Criando scripts de inicialização..."
for i in {1..4}; do
    PORT=$((6050 + i*1000))
    ADMIN_PORT=$((9442 + i))
    OP_PORT=$((8442 + i))
    
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

export ORDERER_FILELEDGER_LOCATION=\$PWD/ledger/orderer$i
export FABRIC_LOGGING_SPEC="orderer.common.broadcast=error:comm.grpc.server=error:grpc=error:info"
unset ORDERER_GENERAL_GENESISFILE

echo "🚀 Iniciando RAFT Orderer $i (Porta $PORT)..."
../fabric/build/bin/orderer
EOF
    chmod +x start_orderer$i.sh
done

echo "💉 5. Criando script de injeção de canais..."
cat << 'EOF' > injetar_canais.sh
#!/bin/bash
for i in {1..4}; do
    ADMIN_PORT=$((9442 + i))
    if [ $i -eq 1 ]; then NODE="orderer"; else NODE="orderer$i"; fi
    ../fabric/build/bin/osnadmin channel join --channelID canal$i --config-block ./channel-artifacts/canal$i.block -o 127.0.0.1:$ADMIN_PORT --ca-file $PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/ca.crt --client-cert $PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/server.crt --client-key $PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/server.key > /dev/null 2>&1
done
EOF
chmod +x injetar_canais.sh

echo "========================================================="
echo "⚙️  INICIANDO A REDE RAFT EM BACKGROUND"
for i in {1..4}; do
    ./start_orderer$i.sh > orderer$i.log 2>&1 &
    echo "   ▶ ORDERER $i OK"
done

echo "⏳ Aguardando 5 segundos para a abertura das portas TCP..."
sleep 5

echo "🎯 INJETANDO CANAIS RAFT..."
./injetar_canais.sh
echo "✅ REDE RAFT PRONTA PARA BENCHMARK!"
echo "========================================================="


pkill -9 -f orderer
echo "========================================================="
echo "✅ AMBIENTE PREPARADO COM SUCESSO!"
echo "Como subir a rede agora:"
echo "1. Abra 4 abas no terminal."
echo "./start_orderer1_raft.sh > raft_orderer1.log"
echo "./start_orderer2_raft.sh > raft_orderer2.log"
echo "./start_orderer3_raft.sh > raft_orderer3.log"
echo "./start_orderer4_raft.sh > raft_orderer4.log"

echo "3. Em uma aba separada, rode:"
echo "./injetar_canais_raft.sh"
echo "========================================================="


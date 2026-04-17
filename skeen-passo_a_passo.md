Passo a passo para mudar o order:


# limpar tudo

<!-- cd ~/doutorado/fabric

make clean
make orderer
make configtxgen
make osnadmin

make cryptogen configtxgen osnadmin -->


cd ~/doutorado/rede-skeen
rm -rf ledger/orderer*
rm -rf channel-artifacts/*.block


# 🧱 Fase 3: Gerar o Bloco do Raft

../fabric/build/bin/configtxgen -profile RaftChannel -channelID canal1 -outputBlock ./channel-artifacts/canal1.block


# 🚀 Fase 4: Subir os Orderers e Injetar o Canal
../fabric/build/bin/osnadmin channel join --channelID canal1 --config-block ./channel-artifacts/canal1.block -o 127.0.0.1:9443
../fabric/build/bin/osnadmin channel join --channelID canal1 --config-block ./channel-artifacts/canal1.block -o 127.0.0.1:9444
../fabric/build/bin/osnadmin channel join --channelID canal1 --config-block ./channel-artifacts/canal1.block -o 127.0.0.1:9445
../fabric/build/bin/osnadmin channel join --channelID canal1 --config-block ./channel-artifacts/canal1.block -o 127.0.0.1:9446

# conferir versoes do go
go mod vendor


cd ~/doutorado/rede-skeen
../fabric/build/bin/cryptogen generate --config=./crypto-config.yaml

# criar os canais

cd ~/doutorado/rede-skeen
../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal1 -outputBlock ./channel-artifacts/canal1.block
../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal2 -outputBlock ./channel-artifacts/canal2.block
../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal3 -outputBlock ./channel-artifacts/canal3.block
../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal4 -outputBlock ./channel-artifacts/canal4.block




# Limpar a sujeira
rm -rf ledger/orderer*


# Subir os 4 Orderers (Em 4 Abas Diferentes)

💻 Aba 1 (Orderer 1)

export FABRIC_CFG_PATH=$PWD
export ORDERER_GENERAL_LISTENPORT=7050
export ORDERER_GENERAL_LOCALMSPID=OrdererMSP
export ORDERER_GENERAL_LOCALMSPDIR=./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp
export ORDERER_GENERAL_TLS_ENABLED=true
export ORDERER_GENERAL_TLS_PRIVATEKEY=./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key
export ORDERER_GENERAL_TLS_CERTIFICATE=./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
export ORDERER_GENERAL_TLS_ROOTCAS=[./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt]
export ORDERER_FILELEDGER_LOCATION=./ledger/orderer1
export ORDERER_CONSENSUS_WALDIR=./ledger/orderer1/wal
export ORDERER_CONSENSUS_SNAPDIR=./ledger/orderer1/snapshot
unset ORDERER_GENERAL_GENESISFILE

../fabric/build/bin/orderer


💻 Aba 2 (Orderer 2)

export FABRIC_CFG_PATH=$PWD
export ORDERER_GENERAL_LISTENPORT=8050
export ORDERER_OPERATIONS_LISTENADDRESS=127.0.0.1:8444
export ORDERER_ADMIN_LISTENADDRESS=127.0.0.1:9444
export ORDERER_GENERAL_LOCALMSPID=OrdererMSP
export ORDERER_GENERAL_LOCALMSPDIR=./crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/msp
export ORDERER_GENERAL_TLS_ENABLED=true
export ORDERER_GENERAL_TLS_PRIVATEKEY=./crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/server.key
export ORDERER_GENERAL_TLS_CERTIFICATE=./crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/server.crt
export ORDERER_GENERAL_TLS_ROOTCAS=[./crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/ca.crt]
export ORDERER_FILELEDGER_LOCATION=./ledger/orderer2
export ORDERER_CONSENSUS_WALDIR=./ledger/orderer2/wal
export ORDERER_CONSENSUS_SNAPDIR=./ledger/orderer2/snapshot
unset ORDERER_GENERAL_GENESISFILE

../fabric/build/bin/orderer


💻 Aba 3 (Orderer 3)

export FABRIC_CFG_PATH=$PWD
export ORDERER_GENERAL_LISTENPORT=9050
export ORDERER_OPERATIONS_LISTENADDRESS=127.0.0.1:8445
export ORDERER_ADMIN_LISTENADDRESS=127.0.0.1:9445
export ORDERER_GENERAL_LOCALMSPID=OrdererMSP
export ORDERER_GENERAL_LOCALMSPDIR=./crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/msp
export ORDERER_GENERAL_TLS_ENABLED=true
export ORDERER_GENERAL_TLS_PRIVATEKEY=./crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/server.key
export ORDERER_GENERAL_TLS_CERTIFICATE=./crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/server.crt
export ORDERER_GENERAL_TLS_ROOTCAS=[./crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/ca.crt]
export ORDERER_FILELEDGER_LOCATION=./ledger/orderer3
export ORDERER_CONSENSUS_WALDIR=./ledger/orderer3/wal
export ORDERER_CONSENSUS_SNAPDIR=./ledger/orderer3/snapshot
unset ORDERER_GENERAL_GENESISFILE

../fabric/build/bin/orderer




💻 Aba 4 (Orderer 4)

export FABRIC_CFG_PATH=$PWD
export ORDERER_GENERAL_LISTENPORT=10050
export ORDERER_OPERATIONS_LISTENADDRESS=127.0.0.1:8446
export ORDERER_ADMIN_LISTENADDRESS=127.0.0.1:9446
export ORDERER_GENERAL_LOCALMSPID=OrdererMSP
export ORDERER_GENERAL_LOCALMSPDIR=./crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/msp
export ORDERER_GENERAL_TLS_ENABLED=true
export ORDERER_GENERAL_TLS_PRIVATEKEY=./crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/server.key
export ORDERER_GENERAL_TLS_CERTIFICATE=./crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/server.crt
export ORDERER_GENERAL_TLS_ROOTCAS=[./crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/ca.crt]
export ORDERER_FILELEDGER_LOCATION=./ledger/orderer4
export ORDERER_CONSENSUS_WALDIR=./ledger/orderer4/wal
export ORDERER_CONSENSUS_SNAPDIR=./ledger/orderer4/snapshot
unset ORDERER_GENERAL_GENESISFILE

../fabric/build/bin/orderer



Gerar os blocos genesis 

../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal1 -outputBlock ./channel-artifacts/canal1.block
../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal2 -outputBlock ./channel-artifacts/canal2.block
../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal3 -outputBlock ./channel-artifacts/canal3.block
../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal4 -outputBlock ./channel-artifacts/canal4.block


Injetar os 4 Canais:

for c in {1..4}; do
  for p in 9443 9444 9445 9446; do
    ../fabric/build/bin/osnadmin channel join --channelID canal$c --config-block ./channel-artifacts/canal$c.block -o 127.0.0.1:$p
  done
done










# quando mudar de SKEEN -> BFT-SMART tem que alterar a versao V2 para V3 em 
Capabilities:
    Channel: &ChannelCapabilities
        V3_0: true


RODAR O BENCHMARK


go run teste.go








# Arquitetura

orderer/common/server/main.go: Você registrou o seu protocolo aqui. Originalmente, o Fabric só conhece etcdraft e BFT. Você adicionou o skeen ao mapa de consenters.

orderer/consensus/skeen/: Esta é a pasta que você criou.

consenter.go: É o "construtor". Ele recebe as configurações do configtx.yaml e decide como iniciar o motor.

chain.go: É o "motor" em si. Ele contém o laço (loop) que fica ouvindo as transações chegando via gRPC e decide a ordem delas usando a lógica do Skeen.
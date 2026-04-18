Tutorial de Migração e Configuração: Skeen vs Baselines
1. Limpeza Total (Ambiente "Zero")
Antes de mudar o protocolo (Skeen ↔ Raft ↔ SmartBFT), é vital limpar os dados antigos para evitar corrupção de blocos.
  
cd ~/doutorado/rede-skeen
rm -rf ledger/orderer*
rm -rf build/bin/orderer 
rm -rf channel-artifacts/*.block


# Para todos os processos se estiverem rodando
# Limpa bancos de dados e blocos antigos

cd ~/doutorado/rede-skeen
pkill orderer 
pkill -9 orderer
rm -rf crypto-config channel-artifacts ledger
rm -rf ledger/orderer*
rm -rf channel-artifacts/*.block
rm -rf crypto-config/
../fabric/build/bin/cryptogen generate --config=./crypto-config.yaml




# Forçar a Recompilação

# 1. Apaga o binário antigo para forçar o compilador a trabalhar
rm -f build/bin/orderer

# 2. Manda compilar de novo
make orderer


























 pkill -9 orderer
cd ~/doutorado/rede-skeen
rm -rf ledger channel-artifacts crypto-config
mkdir channel-artifacts
 

# 2. Geração de Identidades (Certificados)
 
cd ~/doutorado/rede-skeen
../fabric/build/bin/cryptogen generate --config=./crypto-config.yaml

export FABRIC_CFG_PATH=$PWD
../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal1 -outputBlock ./channel-artifacts/canal1.block
../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal2 -outputBlock ./channel-artifacts/canal2.block
../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal3 -outputBlock ./channel-artifacts/canal3.block
../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal4 -outputBlock ./channel-artifacts/canal4.block



# 3. Criação dos Blocos de Configuração (Canais)
 
Importante: Se for testar SmartBFT ou Raft, você geralmente usa apenas o canal1 para todos os nós. Se for Skeen, você usa os 4 canais.

Bash
## Exemplo para SKEEN (4 Shards)

cd ~/doutorado/rede-skeen
for c in {1..4}; do
  ../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal$c -outputBlock ./channel-artifacts/canal$c.block
done





## aqui se for bft-smart devemos mudar a versao para V3 em configtx.yaml
# Exemplo para RAFT ou SmartBFT (Baseline Monolítico)
../fabric/build/bin/configtxgen -profile RaftChannel -channelID canal1 -outputBlock ./channel-artifacts/canal1.block



# 4. Subida dos Orderers


Como resolver isso no próximo teste definitivo:
Quando for subir a rede para o teste valendo, inicie os orderers redirecionando a saída para o arquivo de log, usando o & no final para que rodem em segundo plano (background):

Bash
./start_orderer1.sh > orderer1.log 2>&1 &
./start_orderer2.sh > orderer2.log 2>&1 &
./start_orderer3.sh > orderer3.log 2>&1 &
./start_orderer4.sh > orderer4.log 2>&1 &




💻 Aba 1 (Orderer 1 - Porta Admin 9443)
Bash
 

export FABRIC_CFG_PATH=$PWD
export ORDERER_GENERAL_LISTENPORT=7050
export ORDERER_ADMIN_LISTENADDRESS=127.0.0.1:9443
export ORDERER_OPERATIONS_LISTENADDRESS=127.0.0.1:8443
export ORDERER_ADMIN_TLS_ENABLED=true
export ORDERER_ADMIN_TLS_CERTIFICATE=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATEKEY=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key
export ORDERER_ADMIN_TLS_CLIENTROOTCAS=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt
export ORDERER_GENERAL_LOCALMSPID=OrdererMSP
export ORDERER_GENERAL_LOCALMSPDIR=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp
export ORDERER_GENERAL_TLS_ENABLED=true
export ORDERER_GENERAL_TLS_PRIVATEKEY=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key
export ORDERER_GENERAL_TLS_CERTIFICATE=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
export ORDERER_GENERAL_TLS_ROOTCAS=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt
export ORDERER_FILELEDGER_LOCATION=$PWD/ledger/orderer1
unset ORDERER_GENERAL_GENESISFILE
export FABRIC_LOGGING_SPEC="orderer.common.broadcast=error:comm.grpc.server=error:grpc=error:info"
../fabric/build/bin/orderer




💻 Aba 2 (Orderer 2)

export FABRIC_CFG_PATH=$PWD
export ORDERER_GENERAL_LISTENPORT=8050
export ORDERER_ADMIN_LISTENADDRESS=127.0.0.1:9444
export ORDERER_OPERATIONS_LISTENADDRESS=127.0.0.1:8444
export ORDERER_ADMIN_TLS_ENABLED=true
export ORDERER_ADMIN_TLS_CERTIFICATE=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATEKEY=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/server.key
export ORDERER_ADMIN_TLS_CLIENTROOTCAS=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/ca.crt
export ORDERER_GENERAL_LOCALMSPID=OrdererMSP
export ORDERER_GENERAL_LOCALMSPDIR=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/msp
export ORDERER_GENERAL_TLS_ENABLED=true
export ORDERER_GENERAL_TLS_PRIVATEKEY=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/server.key
export ORDERER_GENERAL_TLS_CERTIFICATE=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/server.crt
export ORDERER_GENERAL_TLS_ROOTCAS=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/ca.crt
export ORDERER_FILELEDGER_LOCATION=$PWD/ledger/orderer2
unset ORDERER_GENERAL_GENESISFILE
export FABRIC_LOGGING_SPEC="orderer.common.broadcast=error:comm.grpc.server=error:grpc=error:info"
../fabric/build/bin/orderer


💻 Aba 3 (Orderer 3)

export FABRIC_CFG_PATH=$PWD
export ORDERER_GENERAL_LISTENPORT=9050
export ORDERER_ADMIN_LISTENADDRESS=127.0.0.1:9445
export ORDERER_OPERATIONS_LISTENADDRESS=127.0.0.1:8445

# Admin TLS
export ORDERER_ADMIN_TLS_ENABLED=true
export ORDERER_ADMIN_TLS_CERTIFICATE=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATEKEY=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/server.key
export ORDERER_ADMIN_TLS_CLIENTROOTCAS=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/ca.crt

# General & Ledger
export ORDERER_GENERAL_LOCALMSPID=OrdererMSP
export ORDERER_GENERAL_LOCALMSPDIR=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/msp
export ORDERER_GENERAL_TLS_ENABLED=true
export ORDERER_GENERAL_TLS_PRIVATEKEY=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/server.key
export ORDERER_GENERAL_TLS_CERTIFICATE=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/server.crt
export ORDERER_GENERAL_TLS_ROOTCAS=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/ca.crt
export ORDERER_FILELEDGER_LOCATION=$PWD/ledger/orderer3
unset ORDERER_GENERAL_GENESISFILE
export FABRIC_LOGGING_SPEC="orderer.common.broadcast=error:comm.grpc.server=error:grpc=error:info"
../fabric/build/bin/orderer




💻 Aba 4 (Orderer 4)

export FABRIC_CFG_PATH=$PWD
export ORDERER_GENERAL_LISTENPORT=10050
export ORDERER_ADMIN_LISTENADDRESS=127.0.0.1:9446
export ORDERER_OPERATIONS_LISTENADDRESS=127.0.0.1:8446

# Admin TLS
export ORDERER_ADMIN_TLS_ENABLED=true
export ORDERER_ADMIN_TLS_CERTIFICATE=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATEKEY=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/server.key
export ORDERER_ADMIN_TLS_CLIENTROOTCAS=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/ca.crt

# General & Ledger
export ORDERER_GENERAL_LOCALMSPID=OrdererMSP
export ORDERER_GENERAL_LOCALMSPDIR=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/msp
export ORDERER_GENERAL_TLS_ENABLED=true
export ORDERER_GENERAL_TLS_PRIVATEKEY=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/server.key
export ORDERER_GENERAL_TLS_CERTIFICATE=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/server.crt
export ORDERER_GENERAL_TLS_ROOTCAS=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/ca.crt
export ORDERER_FILELEDGER_LOCATION=$PWD/ledger/orderer4
unset ORDERER_GENERAL_GENESISFILE
export FABRIC_LOGGING_SPEC="orderer.common.broadcast=error:comm.grpc.server=error:grpc=error:info"
../fabric/build/bin/orderer

  


# 5. Injeção dos Canais (Join)

## Para Skeen (Modo Sharding)
### Nó 1 entra no Shard 1, Nó 2 no Shard 2...


  cd ~/doutorado/rede-skeen

# Injetar Canal 1 no Orderer 1
../fabric/build/bin/osnadmin channel join --channelID canal1 --config-block ./channel-artifacts/canal1.block -o 127.0.0.1:9443 --ca-file $PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt --client-cert $PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt --client-key $PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key

# Injetar Canal 2 no Orderer 2
../fabric/build/bin/osnadmin channel join --channelID canal2 --config-block ./channel-artifacts/canal2.block -o 127.0.0.1:9444 --ca-file $PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/ca.crt --client-cert $PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/server.crt --client-key $PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/server.key

# Injetar Canal 3 no Orderer 3
../fabric/build/bin/osnadmin channel join --channelID canal3 --config-block ./channel-artifacts/canal3.block -o 127.0.0.1:9445 --ca-file $PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/ca.crt --client-cert $PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/server.crt --client-key $PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/server.key

# Injetar Canal 4 no Orderer 4
../fabric/build/bin/osnadmin channel join --channelID canal4 --config-block ./channel-artifacts/canal4.block -o 127.0.0.1:9446 --ca-file $PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/ca.crt --client-cert $PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/server.crt --client-key $PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/server.key

## outros
Para Baselines (Todos os nós em 1 único canal)
Bash
for p in 9443 9444 9445 9446; do
  ../fabric/build/bin/osnadmin channel join --channelID canal1 --config-block ./channel-artifacts/canal1.block -o 127.0.0.1:$p
done


6. Observações de Arquitetura (Doutorado)
Capabilities: Lembre-se que o SmartBFT exige Channel: V3_0 no configtx.yaml. Se for rodar Raft ou Skeen, pode manter em V2_0 ou V3_0, mas o SmartBFT é rigoroso com a versão 3.

Consensus Integration:

orderer/common/server/main.go: Onde o Skeen foi batizado no código.

orderer/consensus/skeen/consenter.go: Onde os parâmetros do configtx (como batch timeout) são injetados.

orderer/consensus/skeen/chain.go: Onde reside a lógica de Relógios Lógicos e o suporte a transações cross-shard.

🚀 Rodar o Benchmark
Bash
cd ~/doutorado/rede-skeen/cliente-simples
# Exemplo: 100k transações, 1024 bytes, 1 shards (se Skeen)
go run teste.go -tx 1 -payload 1024 -shards 1 -cross 0













































Passo a passo para mudar o order:


# limpar tudo

cd ~/doutorado/fabric
 
make clean orderer cryptogen configtxgen osnadmin


cd ~/doutorado/rede-skeen
rm -rf ledger/orderer*
rm -rf channel-artifacts/*.block


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

cd ~/doutorado/rede-skeen
../fabric/build/bin/configtxgen -profile RaftChannel -channelID canal1 -outputBlock ./channel-artifacts/canal1.block
../fabric/build/bin/configtxgen -profile RaftChannel -channelID canal2 -outputBlock ./channel-artifacts/canal2.block
../fabric/build/bin/configtxgen -profile RaftChannel -channelID canal3 -outputBlock ./channel-artifacts/canal3.block
../fabric/build/bin/configtxgen -profile RaftChannel -channelID canal4 -outputBlock ./channel-artifacts/canal4.block

cd ~/doutorado/rede-skeen
../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal1 -outputBlock ./channel-artifacts/canal1.block
../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal2 -outputBlock ./channel-artifacts/canal2.block
../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal3 -outputBlock ./channel-artifacts/canal3.block
../fabric/build/bin/configtxgen -profile SkeenChannel -channelID canal4 -outputBlock ./channel-artifacts/canal4.block





# Subir os 4 Orderers (Em 4 Abas Diferentes)

💻 Aba 1 (Orderer 1)

export FABRIC_CFG_PATH=$PWD
export ORDERER_GENERAL_LISTENPORT=7050
export ORDERER_GENERAL_LOCALMSPID=OrdererMSP
export ORDERER_GENERAL_LOCALMSPDIR=./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp
export ORDERER_GENERAL_TLS_ENABLED=true
export ORDERER_GENERAL_TLS_PRIVATEKEY=./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key
export ORDERER_GENERAL_TLS_CERTIFICATE=./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt
export ORDERER_GENERAL_TLS_ROOTCAS=./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt
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
export ORDERER_GENERAL_TLS_ROOTCAS=./crypto-config/ordererOrganizations/example.com/orderers/orderer2.example.com/tls/ca.crt
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
export ORDERER_GENERAL_TLS_ROOTCAS=./crypto-config/ordererOrganizations/example.com/orderers/orderer3.example.com/tls/ca.crt
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
export ORDERER_GENERAL_TLS_ROOTCAS=./crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/ca.crt
export ORDERER_FILELEDGER_LOCATION=./ledger/orderer4
export ORDERER_CONSENSUS_WALDIR=./ledger/orderer4/wal
export ORDERER_CONSENSUS_SNAPDIR=./ledger/orderer4/snapshot
unset ORDERER_GENERAL_GENESISFILE

../fabric/build/bin/orderer


# 🚀 Fase : Subir os Orderers e Injetar o Canal
../fabric/build/bin/osnadmin channel join --channelID canal1 --config-block ./channel-artifacts/canal1.block -o 127.0.0.1:9443
../fabric/build/bin/osnadmin channel join --channelID canal1 --config-block ./channel-artifacts/canal1.block -o 127.0.0.1:9444
../fabric/build/bin/osnadmin channel join --channelID canal1 --config-block ./channel-artifacts/canal1.block -o 127.0.0.1:9445
../fabric/build/bin/osnadmin channel join --channelID canal1 --config-block ./channel-artifacts/canal1.block -o 127.0.0.1:9446




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
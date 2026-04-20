#!/bin/bash
export FABRIC_CFG_PATH=$PWD
export ORDERER_GENERAL_LISTENPORT=10050
export ORDERER_CONSENSUS_WALDIR=$PWD/ledger/orderer1/wal
export ORDERER_CONSENSUS_SNAPDIR=$PWD/ledger/orderer1/snapshot
export ORDERER_ADMIN_LISTENADDRESS=127.0.0.1:9446
export ORDERER_OPERATIONS_LISTENADDRESS=127.0.0.1:8446

# Admin TLS
export ORDERER_ADMIN_TLS_ENABLED=true
export ORDERER_ADMIN_TLS_CERTIFICATE=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/server.crt
export ORDERER_ADMIN_TLS_PRIVATEKEY=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/server.key
export ORDERER_ADMIN_TLS_CLIENTROOTCAS=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/ca.crt

# General TLS & MSP
export ORDERER_GENERAL_LOCALMSPID=OrdererMSP
export ORDERER_GENERAL_LOCALMSPDIR=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/msp
export ORDERER_GENERAL_TLS_ENABLED=true
export ORDERER_GENERAL_TLS_PRIVATEKEY=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/server.key
export ORDERER_GENERAL_TLS_CERTIFICATE=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/server.crt
export ORDERER_GENERAL_TLS_ROOTCAS=$PWD/crypto-config/ordererOrganizations/example.com/orderers/orderer4.example.com/tls/ca.crt

export ORDERER_FILELEDGER_LOCATION=$PWD/ledger/orderer4
export FABRIC_LOGGING_SPEC="orderer.common.broadcast=error:comm.grpc.server=error:grpc=error:info"
unset ORDERER_GENERAL_GENESISFILE

echo "🚀 Iniciando RAFT Orderer 4 (Porta 10050)..."
../fabric/build/bin/orderer

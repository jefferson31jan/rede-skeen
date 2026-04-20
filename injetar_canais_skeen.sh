#!/bin/bash
echo "⏳ Injetando os 4 canais nos respectivos Orderers..."
for i in {1..4}; do
    ADMIN_PORT=$((9442 + i))
    if [ $i -eq 1 ]; then NODE="orderer"; else NODE="orderer$i"; fi
    
    ../fabric/build/bin/osnadmin channel join --channelID canal$i --config-block ./channel-artifacts/canal$i.block -o 127.0.0.1:$ADMIN_PORT --ca-file $PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/ca.crt --client-cert $PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/server.crt --client-key $PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/server.key
done
echo "🎯 Injeção concluída! Pode rodar o teste.go."

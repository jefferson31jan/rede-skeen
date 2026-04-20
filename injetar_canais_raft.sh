#!/bin/bash

echo "========================================================="
echo "⏳ Injetando MATRIZ (4 Canais x 4 Orderers - Raft/BFT)..."
echo "========================================================="

# Loop para cada um dos 4 Canais
for c in {1..4}; do
    echo "📦 Distribuindo o CANAL $c..."
    
    # Loop para cada um dos 4 Orderers
    for o in {1..4}; do
        ADMIN_PORT=$((9442 + o))
        if [ $o -eq 1 ]; then NODE="orderer"; else NODE="orderer$o"; fi
        
        echo -n "   ▶ Injetando no Orderer $o (Porta $ADMIN_PORT)... "
        
        OUTPUT=$(../fabric/build/bin/osnadmin channel join \
        --channelID canal$c \
        --config-block ./channel-artifacts/canal$c.block \
        -o 127.0.0.1:$ADMIN_PORT \
        --ca-file $PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/ca.crt \
        --client-cert $PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/server.crt \
        --client-key $PWD/crypto-config/ordererOrganizations/example.com/orderers/$NODE.example.com/tls/server.key 2>&1)
        
        if [[ "$OUTPUT" == *"Status: 201"* ]]; then
            echo "✅ Sucesso"
        else
            echo "❌ Erro: $OUTPUT"
        fi
    done
    echo "---------------------------------------------------------"
done

echo "🏆 Injeção Matriz concluída! O Quórum Raft vai se formar agora."
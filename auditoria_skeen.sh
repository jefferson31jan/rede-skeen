#!/bin/bash

echo "======================================================="
echo " 🔍 AUDITORIA DE CONSISTÊNCIA BFT (SAFETY) - SKEEN "
echo "======================================================="

# Função para pegar o tamanho exato APENAS da blockchain (ignora o banco LevelDB)
get_size() {
    stat -c%s ledger/orderer$1/chains/$2/blockfile_000000 2>/dev/null
}

# Função para gerar a prova criptográfica do arquivo
get_hash() {
    md5sum ledger/orderer$1/chains/$2/blockfile_000000 2>/dev/null | awk '{print $1}'
}

echo -e "\n🛡️  SHARD 1 (Canal 1)"
echo "-------------------------------------------------------"
S1=$(get_size 1 "canal1")
S2=$(get_size 2 "canal1")
H1=$(get_hash 1 "canal1")
H2=$(get_hash 2 "canal1")

echo "Orderer 1 -> Disco: $S1 bytes | Hash MD5: $H1"
echo "Orderer 2 -> Disco: $S2 bytes | Hash MD5: $H2"

if [ "$S1" == "$S2" ] && [ "$H1" == "$H2" ] && [ -n "$S1" ]; then
    echo "✅ STATUS: CONSISTÊNCIA PERFEITA (Ordem Total Garantida)"
else
    echo "❌ STATUS: DIVERGÊNCIA (Falha de Safety)"
fi

echo -e "\n🛡️  SHARD 2 (Canal 2)"
echo "-------------------------------------------------------"
S3=$(get_size 3 "canal2")
S4=$(get_size 4 "canal2")
H3=$(get_hash 3 "canal2")
H4=$(get_hash 4 "canal2")

echo "Orderer 3 -> Disco: $S3 bytes | Hash MD5: $H3"
echo "Orderer 4 -> Disco: $S4 bytes | Hash MD5: $H4"

if [ "$S3" == "$S4" ] && [ "$H3" == "$H4" ] && [ -n "$S3" ]; then
    echo "✅ STATUS: CONSISTÊNCIA PERFEITA (Ordem Total Garantida)"
else
    echo "❌ STATUS: DIVERGÊNCIA (Falha de Safety)"
fi
echo "======================================================="
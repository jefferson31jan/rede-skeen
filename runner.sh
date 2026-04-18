#!/bin/bash

# =========================================================
# AUTÔMATO DE BENCHMARK - SKEEN BFT
# =========================================================

ARQUIVO_SAIDA="dados.csv"
TOTAL_TX=4000 # Carga fixa para estabilidade estatística

# Cria o cabeçalho do CSV se não existir
if [ ! -f $ARQUIVO_SAIDA ]; then
    echo "Shards,Payload(Bytes),CrossRate,Transacoes,TPS,Latencia(ms)" > $ARQUIVO_SAIDA
fi

# Arrays com as variáveis de teste
SHARDS=(1 2 3 4)
PAYLOADS=(40 200 1024 4096)
CROSS_RATES=(0 0.1 0.2 0.3)

echo "🚀 Iniciando Baterias de Teste Automatizadas..."
echo "📊 Os resultados serão salvos em: $ARQUIVO_SAIDA"
echo "---------------------------------------------------------"

# Loop Triplo (Grid Search)
for s in "${SHARDS[@]}"; do
    for p in "${PAYLOADS[@]}"; do
        for c in "${CROSS_RATES[@]}"; do
            
            # Se for apenas 1 Shard, não faz sentido testar cross-shard > 0
            if [ "$s" -eq 1 ] && [ $(echo "$c > 0" | bc -l) -eq 1 ]; then
                continue
            fi

            echo "⏳ Rodando -> Shards: $s | Payload: ${p}B | Cross: $c ..."
            
            # Executa o Go e captura a saída
            OUTPUT=$(go run teste.go -tx $TOTAL_TX -payload $p -shards $s -cross $c)
            
            # Usa AWK para extrair apenas os números de TPS e Latência da saída do seu Go
            TPS=$(echo "$OUTPUT" | grep "THROUGHPUT" | awk '{print $4}')
            LAT=$(echo "$OUTPUT" | grep "LATÊNCIA MÉDIA" | awk '{print $4}')

            # Salva no CSV
            if [ -n "$TPS" ] && [ -n "$LAT" ]; then
                echo "$s,$p,$c,$TOTAL_TX,$TPS,$LAT" >> $ARQUIVO_SAIDA
                echo "   ✅ TPS: $TPS | Latência: ${LAT}ms"
            else
                echo "   ❌ Erro ao capturar dados. Verifique os Orderers."
            fi
            
            # Pausa de respiração para o SO limpar conexões TCP (TIME_WAIT)
            sleep 2
        done
    done
done

echo "---------------------------------------------------------"
echo "🏆 Baterias concluídas! Arquivo $ARQUIVO_SAIDA gerado."
#!/bin/bash

# =========================================================
# AUTÔMATO DE BENCHMARK UNIVERSAL (SKEEN / RAFT / BFTSMART)
# =========================================================

PROTOCOLO=$1

if [ "$PROTOCOLO" == "skeen" ]; then
    NOME_EXIBICAO="SKEEN BFT"
    ARQUIVO_SAIDA="dados_skeen.csv"
elif [ "$PROTOCOLO" == "raft" ]; then
    NOME_EXIBICAO="RAFT (CFT)"
    ARQUIVO_SAIDA="dados_raft.csv"
elif [ "$PROTOCOLO" == "bftsmart" ]; then
    NOME_EXIBICAO="BFT-SMaRt"
    ARQUIVO_SAIDA="dados_bftsmart.csv"
else
    echo "❌ Erro: Protocolo não especificado ou inválido."
    echo "💡 Uso correto: ./runner.sh [skeen | raft | bftsmart]"
    exit 1
fi

TOTAL_TX=1 # Sugestão: Aumente para 1000 ou 4000 nos testes reais
REPETICOES=1 # NOVO: Número de vezes que cada cenário será testado para tirar a média

if [ ! -f $ARQUIVO_SAIDA ]; then
    echo "Shards,Payload(Bytes),CrossRate,Transacoes,TPS,Latencia(ms)" > $ARQUIVO_SAIDA
fi

SHARDS=(4)
PAYLOADS=(200)
CROSS_RATES=(1)

echo "========================================================="
echo "🚀 Iniciando Baterias: $NOME_EXIBICAO"
echo "🔄 Repetições por cenário: $REPETICOES (Apenas a média será salva)"
echo "📊 Saída: $ARQUIVO_SAIDA"
echo "========================================================="

for s in "${SHARDS[@]}"; do
    for p in "${PAYLOADS[@]}"; do
        for c in "${CROSS_RATES[@]}"; do
            
            if [ "$s" -eq 1 ] && [ $(echo "$c > 0" | bc -l) -eq 1 ]; then
                continue
            fi

            echo -n "⏳ [$NOME_EXIBICAO] Shards: $s | Payload: ${p}B | Cross: $c -> Rodando $REPETICOES vezes: "
            
            # Variáveis para acumular os resultados das N repetições
            SOMA_TPS=0
            SOMA_LAT=0
            SUCESSOS=0

            for r in $(seq 1 $REPETICOES); do
                OUTPUT=$(go run teste.go -tx $TOTAL_TX -payload $p -shards $s -cross $c -consensus $PROTOCOLO)
                
                TPS=$(echo "$OUTPUT" | grep "THROUGHPUT" | awk '{print $4}')
                LAT=$(echo "$OUTPUT" | grep "LATÊNCIA MÉDIA" | awk '{print $4}')

                if [ -n "$TPS" ] && [ -n "$LAT" ]; then
                    # Soma os valores convertendo string para float usando o awk
                    SOMA_TPS=$(awk "BEGIN {print $SOMA_TPS + $TPS}")
                    SOMA_LAT=$(awk "BEGIN {print $SOMA_LAT + $LAT}")
                    SUCESSOS=$((SUCESSOS + 1))
                    echo -n "🟢 " # Indicador visual de sucesso
                else
                    echo -n "🔴 " # Indicador visual de falha
                fi
                
                sleep 1 # Pausa curta entre uma rodada e outra
            done

            echo "" # Quebra de linha após os indicadores visuais

            if [ "$SUCESSOS" -gt 0 ]; then
                # Calcula a média (Soma total / Número de sucessos) limitando a 2 casas decimais
                MEDIA_TPS=$(awk "BEGIN {printf \"%.2f\", $SOMA_TPS / $SUCESSOS}")
                MEDIA_LAT=$(awk "BEGIN {printf \"%.2f\", $SOMA_LAT / $SUCESSOS}")
                
                echo "$s,$p,$c,$TOTAL_TX,$MEDIA_TPS,$MEDIA_LAT" >> $ARQUIVO_SAIDA
                echo "   ✅ MÉDIA SALVA -> TPS: $MEDIA_TPS | Latência: ${MEDIA_LAT}ms"
            else
                echo "   ❌ Erro: Nenhuma das $REPETICOES repetições gerou dados válidos."
            fi
            
            echo "---------------------------------------------------------"
            sleep 3 # Pausa longa entre configurações diferentes
        done
    done
done

echo "🏆 Baterias concluídas! Arquivo $ARQUIVO_SAIDA atualizado com as médias."
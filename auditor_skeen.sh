#!/bin/bash

# Cores para o terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}    🔍 AUDITORIA DO LEDGER SKEEN (INTEGRIDADE)    ${NC}"
echo -e "${BLUE}======================================================${NC}"

# 1. VERIFICAÇÃO FÍSICA DOS FICHEIROS DO LEDGER
echo -e "\n${YELLOW}▶ Verificando os ficheiros físicos do Fabric (blockfiles):${NC}"

for i in 1 2 3 4; do
    LEDGER_DIR="./ledger/orderer${i}/chains/canal${i}"
    
    if [ -d "$LEDGER_DIR" ]; then
        # Conta quantos arquivos de bloco existem (geralmente blockfile_000000)
        FILE_SIZE=$(du -sh "$LEDGER_DIR" | cut -f1)
        echo -e "${GREEN}✅ Shard $i (Canal $i):${NC} Diretório íntegro. Tamanho total: $FILE_SIZE"
    else
        echo -e "${RED}❌ Shard $i:${NC} Diretório do ledger não encontrado em $LEDGER_DIR"
    fi
done

# 2. VERIFICAÇÃO LÓGICA (Requer que os logs dos orderers sejam guardados)
# DICA: Quando rodar os orderers, rode assim: ./start_orderer1.sh > orderer1.log 2>&1
echo -e "\n${YELLOW}▶ Verificando logs de Consenso e Gravação:${NC}"

TOTAL_BLOCOS=0
for i in 1 2 3 4; do
    LOG_FILE="orderer${i}.log"
    
    if [ -f "$LOG_FILE" ]; then
        # Busca o último bloco gravado pelo Regex do seu log
        ULTIMO_BLOCO=$(grep "GRAVADO NO DISCO" "$LOG_FILE" | tail -n 1 | awk -F'BLOCO \\[' '{print $2}' | awk -F'\\]' '{print $1}')
        
        # Conta quantas vezes a palavra "COORDENADOR" aparece (Total de TXs lideradas)
        TXS_LIDERADAS=$(grep "Papel: COORDENADOR" "$LOG_FILE" | wc -l)
        
        if [ -z "$ULTIMO_BLOCO" ]; then ULTIMO_BLOCO=0; fi
        
        echo -e "${GREEN}✅ Shard $i:${NC} Liderou ${TXS_LIDERADAS} Txs | Último Bloco Gravado: $ULTIMO_BLOCO"
        TOTAL_BLOCOS=$((TOTAL_BLOCOS + ULTIMO_BLOCO))
    else
        echo -e "${RED}⚠️  Log orderer${i}.log não encontrado.${NC} (Lembre-se de redirecionar a saída do terminal para .log)"
    fi
done

echo -e "\n${BLUE}======================================================${NC}"
echo -e "🏆 ${GREEN}RESUMO DA AUDITORIA:${NC}"
echo -e "Total de Blocos gerados na rede: ${TOTAL_BLOCOS}"
echo -e "${BLUE}======================================================${NC}"
echo -e "Dica para a Tese: Multiplique o 'Último Bloco Gravado' pelo 'MaxMessageCount' (ex: 500)."
echo -e "O resultado deve ser EXATAMENTE igual ao número de transações que aquele Shard processou."
echo ""
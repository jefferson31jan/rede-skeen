#!/bin/bash

# ==============================================================================
# SKEEN BFT - EXPERIMENTO COMPLETO COM GERAÇÃO DE GRÁFICO (GNUPLOT)
# ==============================================================================

TX_COUNT=4 # Reduzido para 1000 para a varredura completa não demorar horas
PAYLOAD=200
DATA_FILE="dados_experimento.dat"
PLOT_FILE="grafico_desempenho.png"

echo "🔨 Compilando o injetor..."
go build -o teste_bin teste.go

if [ $? -ne 0 ]; then
    echo "❌ Erro na compilação!"
    exit 1
fi

echo "🚀 Iniciando Matriz de Experimentos..."
echo "📊 Os dados brutos serão guardados em: $DATA_FILE"
echo "📈 O gráfico final será gerado em: $PLOT_FILE"
echo "-----------------------------------------------------------------------"

# Prepara o cabeçalho do arquivo de dados para o Gnuplot
# Formato: Shards | 0%_Cross | 50%_Cross | 100%_Cross
echo "Shards Cross_0.0 Cross_0.5 Cross_1.0" > $DATA_FILE

# Matriz de Testes
for SHARDS in 1 2 3 4; do
    # Inicializa a linha de dados para este número de shards
    LINHA_DADOS="$SHARDS"
    
    for CROSS in 0.0 0.5 1.0; do
        
        # O conceito de Cross-Shard só faz sentido para > 1 Shard.
        # Se for 1 Shard, o teste.go ignora o cross, mas para o gráfico não ficar zerado:
        if [ "$SHARDS" -eq 1 ] && [ "$CROSS" != "0.0" ]; then
            # Reusa o valor de 0.0 para manter a barra no gráfico
            LINHA_DADOS="$LINHA_DADOS $LAST_TPS"
            continue
        fi

        echo "▶️  Testando: $SHARDS Shards | Cross: $CROSS..."
        
        # Roda o teste, redireciona o output, busca a linha de TPS e extrai o último número
        SAIDA=$(./teste_bin -tx $TX_COUNT -shards $SHARDS -payload $PAYLOAD -cross $CROSS)
        TPS=$(echo "$SAIDA" | grep "TPS:" | awk '{print $NF}')
        
        # Salva o valor para eventual reuso (caso Shards=1)
        LAST_TPS=$TPS
        
        # Adiciona o TPS na linha de dados
        LINHA_DADOS="$LINHA_DADOS $TPS"
        
        # Pequena pausa para respiro do SO e liberação de portas TCP
        sleep 2
    done
    
    # Grava a linha completa no arquivo de dados
    echo "$LINHA_DADOS" >> $DATA_FILE
    echo "✅ Linha gravada: $LINHA_DADOS"
done

echo "-----------------------------------------------------------------------"
echo "🎨 Gerando Gráfico com Gnuplot..."

# Cria o script do Gnuplot dinamicamente
cat << EOF > plot_config.p
set terminal pngcairo size 900,600 enhanced font 'Arial,12'
set output '$PLOT_FILE'

# 🚨 AJUSTE AQUI: Variáveis TX_COUNT e PAYLOAD inseridas dinamicamente no subtítulo
set title "Análise de Desempenho do Skeen All-to-All (Fabric)\n{/*0.8 Carga: $TX_COUNT Txs | Tamanho do Payload: $PAYLOAD bytes}" font 'Arial-Bold,14'

set xlabel 'Número de Shards Ativos' font 'Arial-Bold,12'
set ylabel 'Vazão (TPS)' font 'Arial-Bold,12'

# Configurações do grid e legenda
set grid ytics
set key top right box
set yrange [0:*] # Começa o eixo Y do zero

# Configuração de gráfico de barras agrupadas
set style data histogram
set style histogram cluster gap 1
set style fill solid 0.8 border -1
set boxwidth 0.9

# Paleta de cores amigável para artigos acadêmicos
# Azul (Intra), Laranja (Misto), Vermelho (Cross Total)
color_intra = "#4C72B0"
color_misto = "#DD8452"
color_cross = "#C44E52"

plot '$DATA_FILE' using 2:xtic(1) title '0% Cross (Intra-Shard)' linecolor rgb color_intra, \
     '' using 3 title '50% Cross (Carga Mista)' linecolor rgb color_misto, \
     '' using 4 title '100% Cross (All-to-All)' linecolor rgb color_cross
EOF

# Executa o Gnuplot
gnuplot plot_config.p

# Limpa o arquivo de configuração do Gnuplot
rm plot_config.p

echo "✅ SUCESSO! O gráfico foi gerado: $PLOT_FILE"
echo "Abra a imagem usando o comando: eog $PLOT_FILE (ou visualize na sua pasta)"
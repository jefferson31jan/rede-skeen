#!/bin/bash

echo "🛠️ Compilando o código Go..."
go build -o teste_bin teste.go
if [ $? -ne 0 ]; then
    echo "❌ Erro na compilação!"
    exit 1
fi
echo "✅ teste_bin gerado com sucesso!"

echo "🚀 Iniciando Bateria de Custo de Coordenação (Cross-Shard)"
echo "CrossRate,TPS_Real,Latencia" > resultados_cross_oficial.csv

# Testando de 0% (Isolamento) até 100% (Coordenação Global)
for c in 0.0 0.25 0.50 0.75 1.0; do
    echo -n "Rodando CrossRate=$c... "
    
    # 1. REMOVIDO a flag -rate que estava causando o erro
    OUT=$(./teste_bin -tx 1000 -shards 4 -payload 1024 -cross $c)
    
    # 2. EXTRAÇÃO ajustada para ler perfeitamente o seu novo formato de log
    TPS=$(echo "$OUT" | grep "THROUGHPUT" | awk '{print $(NF-1)}')
    LAT=$(echo "$OUT" | grep "LATÊNCIA" | awk '{print $(NF-1)}')
    
    # Salva no CSV
    echo "$c,$TPS,$LAT" >> resultados_cross_oficial.csv
    echo "Concluído! (TPS: $TPS | Lat: $LAT ms)"
    
    # Pausa de 5 segundos para a rede "respirar" entre os testes
    sleep 5
done

echo "🏆 Teste finalizado! Dados salvos em resultados_cross_oficial.csv"
import matplotlib.pyplot as plt

# ==========================================
# DADOS DO LABORATÓRIO SKEEN BFT (Abril/2026)
# ==========================================
tamanhos_payload = ['40 bytes', '200 bytes', '1 KByte', '4 KBytes']

# Dados coletados (TPS)
tps_single_shard = [214.02, 995.00, 1050.08, 420.05]
tps_cross_shard = [401.11, 264.43, 542.04, 176.25]

# ==========================================
# CONFIGURAÇÃO DO GRÁFICO (Estilo Artigo Científico)
# ==========================================
plt.figure(figsize=(9, 6))

# Plotando as linhas com marcadores distintos (Estilo DSN'18)
plt.plot(tamanhos_payload, tps_single_shard, marker='s', linestyle='-', color='#1f77b4', 
         linewidth=2, markersize=8, label='Single-Shard (Intra-Fragmento)')

plt.plot(tamanhos_payload, tps_cross_shard, marker='^', linestyle='--', color='#d62728', 
         linewidth=2, markersize=8, label='Cross-Shard (Inter-Fragmentos - Skeen)')

# Adicionando os valores exatos em cima de cada ponto
for i, txt in enumerate(tps_single_shard):
    plt.annotate(f'{txt:.0f}', (tamanhos_payload[i], tps_single_shard[i]), 
                 textcoords="offset points", xytext=(0,10), ha='center', fontsize=9, fontweight='bold', color='#1f77b4')

for i, txt in enumerate(tps_cross_shard):
    plt.annotate(f'{txt:.0f}', (tamanhos_payload[i], tps_cross_shard[i]), 
                 textcoords="offset points", xytext=(0,-15), ha='center', fontsize=9, fontweight='bold', color='#d62728')

# Customização dos eixos e grid
plt.title('Impacto do Tamanho do Payload na Vazão (Throughput)\nComparativo: Single-Shard vs. Skeen Cross-Shard', 
          fontsize=14, fontweight='bold', pad=15)
plt.xlabel('Tamanho da Transação (Payload)', fontsize=12, fontweight='bold', labelpad=10)
plt.ylabel('Vazão (Transações por Segundo - TPS)', fontsize=12, fontweight='bold', labelpad=10)

plt.grid(True, linestyle=':', alpha=0.7)
plt.ylim(0, max(tps_single_shard) * 1.2) # Dá um espaço extra no topo

# Legenda
plt.legend(loc='upper right', fontsize=11, framealpha=0.9, shadow=True)

# Salvando em alta resolução para o PDF da tese
plt.tight_layout()
nome_arquivo = 'grafico_dsn18_skeen.png'
plt.savefig(nome_arquivo, dpi=300, bbox_inches='tight')

print(f"✅ Gráfico gerado com sucesso: {nome_arquivo}")
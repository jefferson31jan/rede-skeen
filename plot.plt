import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import io

data = """Shards,Payload(Bytes),CrossRate,Transacoes,TPS,Latencia(ms)
1,20,0,10000,122806.00,1.23
1,200,0,10000,154983.00,0.77
1,1024,0,10000,181427.00,0.59
1,2048,0,10000,172816.00,0.26
1,4096,0,10000,181172.00,0.49
1,8192,0,10000,134490.00,1.57
1,16384,0,10000,161968.00,1.21
2,20,0,10000,129156.00,1.02
2,200,0,10000,139761.00,0.64
2,1024,0,10000,122971.00,1.15
2,2048,0,10000,160518.00,0.82
2,4096,0,10000,147302.00,0.48
2,8192,0,10000,130088.00,0.60
2,16384,0,10000,179541.00,0.44
3,20,0,10000,189226.00,0.74
3,200,0,10000,197000.00,0.54
3,1024,0,10000,154876.00,0.85
3,2048,0,10000,147415.00,0.89
3,4096,0,10000,160422.00,1.23
3,8192,0,10000,186307.00,0.78
3,16384,0,10000,145694.00,0.42
4,20,0,10000,148988.00,0.69
4,200,0,10000,167094.00,0.54
4,1024,0,10000,170514.00,1.11
4,2048,0,10000,142242.00,0.55
4,4096,0,10000,156976.00,0.99
4,8192,0,10000,171456.00,1.02
4,16384,0,10000,164336.00,1.67"""

df = pd.read_csv(io.StringIO(data))

# Formatar as labels do Payload para ficar bonito no eixo X
df['Payload_Label'] = df['Payload(Bytes)'].apply(lambda x: f"{x}B" if x < 1024 else f"{x//1024}KB")
order = ["20B", "200B", "1KB", "2KB", "4KB", "8KB", "16KB"]
df['Payload_Label'] = pd.Categorical(df['Payload_Label'], categories=order, ordered=True)
df = df.sort_values('Payload_Label')

# Configurar o estilo
sns.set_theme(style="whitegrid", context="talk")

# --- GRÁFICO 1: TPS ---
plt.figure(figsize=(12, 7))
ax1 = sns.barplot(data=df, x='Payload_Label', y='TPS', hue='Shards', palette='viridis', edgecolor='black', linewidth=1)
plt.title('Vazão (TPS) vs Tamanho do Payload (10.000 Transações)', fontsize=16, fontweight='bold', pad=15)
plt.xlabel('Tamanho do Payload', fontsize=14)
plt.ylabel('Transações por Segundo (TPS)', fontsize=14)
plt.legend(title='Shards', bbox_to_anchor=(1.01, 1), loc='upper left')

for container in ax1.containers:
    ax1.bar_label(container, fmt='%.0f', padding=4, fontsize=10, rotation=45)

plt.tight_layout()
plt.savefig('skeen_10k_tps.png', dpi=300)
plt.close()

# --- GRÁFICO 2: LATÊNCIA ---
plt.figure(figsize=(12, 7))
ax2 = sns.barplot(data=df, x='Payload_Label', y='Latencia(ms)', hue='Shards', palette='magma', edgecolor='black', linewidth=1)
plt.title('Latência Média (ms) vs Tamanho do Payload (10.000 Transações)', fontsize=16, fontweight='bold', pad=15)
plt.xlabel('Tamanho do Payload', fontsize=14)
plt.ylabel('Latência (ms)', fontsize=14)
plt.legend(title='Shards', bbox_to_anchor=(1.01, 1), loc='upper left')

for container in ax2.containers:
    ax2.bar_label(container, fmt='%.2f', padding=4, fontsize=10)

plt.tight_layout()
plt.savefig('skeen_10k_latencia.png', dpi=300)
plt.close()

print("Imagens salvas como 'skeen_10k_tps.png' e 'skeen_10k_latencia.png'")
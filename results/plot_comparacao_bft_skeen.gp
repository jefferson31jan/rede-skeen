import matplotlib.pyplot as plt

payloads = ['40', '200', '1024', '2048', '4096']
tps = [1795.56, 1722.60, 1705.87, 1789.66, 1770.26]
lat_avg = [725.88, 778.30, 778.17, 723.03, 742.74]
lat_p95 = [5161, 5372, 5354, 5132, 5275]

plt.style.use('default')
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(15, 6))

# Subplot 1: Throughput (TPS)
ax1.plot(payloads, tps, marker='o', color='#1f77b4', linestyle='-', linewidth=2.5, markersize=8)
ax1.set_title('Throughput (TPS) vs Tamanho do Payload\nBaseline SmartBFT (1 Shard)', fontsize=14, fontweight='bold', pad=15)
ax1.set_xlabel('Tamanho do Payload (Bytes)', fontsize=12, fontweight='bold')
ax1.set_ylabel('Throughput (Transações por Segundo)', fontsize=12, fontweight='bold')
ax1.grid(True, linestyle='--', alpha=0.6)
ax1.set_ylim(0, 2200)

# Subplot 2: Latência (Média e P95)
ax2.plot(payloads, lat_avg, marker='s', color='#2ca02c', linestyle='-', linewidth=2.5, markersize=8, label='Latência Média')
ax2.plot(payloads, lat_p95, marker='^', color='#d62728', linestyle='--', linewidth=2.5, markersize=8, label='Latência P95 (Cauda)')
ax2.set_title('Latência vs Tamanho do Payload\nBaseline SmartBFT (1 Shard)', fontsize=14, fontweight='bold', pad=15)
ax2.set_xlabel('Tamanho do Payload (Bytes)', fontsize=12, fontweight='bold')
ax2.set_ylabel('Tempo de Latência (ms)', fontsize=12, fontweight='bold')
ax2.grid(True, linestyle='--', alpha=0.6)
ax2.legend(fontsize=11, loc='center right')
ax2.set_ylim(0, 6000)

plt.tight_layout()
plt.savefig('grafico_baseline_bft.png', dpi=300, bbox_inches='tight')
plt.show()
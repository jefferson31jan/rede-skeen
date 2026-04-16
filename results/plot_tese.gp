# Output configuration for professional PDF (vector)
set terminal pdf size 5,4 font "Helvetica,12"
set output "performance_comparison_results.pdf"

# Global graph settings
set title "Performance Comparison: CFT vs BFT vs Cross-Shard Sharding"
set ylabel "Throughput (TPS)"
set grid y
set style fill solid 0.7 border -1
set boxwidth 0.6

# Adjust X and Y axes
set yrange [0:1600]
set xtics nomirror
unset key # Remove the legend as we have labels on the X axis

# Defining Colors (using common colors for BFT/CFT)
# 1: Blue (CFT), 2: Green (BFT), 3: Red (Cross-Shard)
set style line 1 lc rgb "#4169E1" # Royal Blue
set style line 2 lc rgb "#32CD32" # Lime Green
set style line 3 lc rgb "#DC143C" # Crimson Red

# The plot command with explicit colors for each bar
# The '-' reads the data lines below
plot "-" using 0:2:3:xtic(1) with boxes lc variable notitle, \
     "-" using 0:2:2 with labels center offset 0,1 notitle

# DATA BLOCK 1 (Protocols, TPS values, and Color Index)
# Protocol_Name  TPS_Value  Color_Index
"CFT (Raft)"     963.80     1
"BFT (Skeen)"    1329.47    2
"Cross-Shard"    237.58     3
e

# DATA BLOCK 2 (For the value labels on top of the bars)
# Protocol_Name  TPS_Value
"CFT (Raft)"     963.80
"BFT (Skeen)"    1329.47
"Cross-Shard"    237.58
e
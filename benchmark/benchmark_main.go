package main

import (
	"context"
	"crypto/ecdsa"
	"crypto/rand"
	"crypto/sha256"
	"crypto/tls"
	"crypto/x509"
	"encoding/asn1"
	"encoding/csv"
	"encoding/pem"
	"flag"
	"fmt"
	"math/big"
	mrand "math/rand/v2"
	"os"
	"runtime"
	"sort"
	"strconv"
	"sync"
	"time"

	"github.com/hyperledger/fabric-protos-go-apiv2/common"
	"github.com/hyperledger/fabric-protos-go-apiv2/msp"
	"github.com/hyperledger/fabric-protos-go-apiv2/orderer"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/protobuf/proto"
)

// =============================================================
// CONFIGURAÇÃO VIA FLAGS
// =============================================================

var (
	flagConsensus    = flag.String("consensus", "skeen", "Algoritmo alvo: skeen | raft | bft")
	flagTotalTx      = flag.Int("txs", 1000, "Total de transações a enviar")
	flagPayload      = flag.Int("payload", 4096, "Tamanho do payload em bytes")
	flagConcurrency  = flag.Int("concurrency", 50, "Máximo de TXs em voo simultâneo (semáforo)")
	flagCrossPercent = flag.Float64("cross", 0.0, "Percentual cross-shard: 0.0 a 1.0")
	flagNumShards    = flag.Int("shards", 1, "Número de shards/canais")
	flagOutput       = flag.String("output", "results.csv", "Arquivo CSV de saída")
	flagCryptoPath   = flag.String("crypto", "../crypto-config", "Caminho para crypto-config")
	flagChannel      = flag.String("channel", "canal-bft", "Nome do canal padrão")
)

// Endereços por tipo de consenso
var consensusAddresses = map[string][]string{
	"skeen": {
		"127.0.0.1:7050", "127.0.0.1:8050",
		"127.0.0.1:9050", "127.0.0.1:10050",
	},
	"raft": {
		"127.0.0.1:7050", "127.0.0.1:8050",
		"127.0.0.1:9050", "127.0.0.1:10050",
	},
	"bft": {
		"127.0.0.1:7050", "127.0.0.1:8050",
		"127.0.0.1:9050", "127.0.0.1:10050",
	},
}

// =============================================================
// ESTRUTURAS DE RESULTADO
// =============================================================

type TxResult struct {
	TxID      string
	Latency   time.Duration
	Success   bool
	IsCross   bool
	PayloadSz int
}

type BenchmarkResult struct {
	Consensus     string
	TotalTx       int
	SuccessTx     int
	PayloadSize   int
	Concurrency   int
	CrossPercent  float64
	Duration      time.Duration
	TPS           float64
	AvgLatency    float64 // ms
	P50Latency    float64 // ms
	P95Latency    float64 // ms
	P99Latency    float64 // ms
	MaxLatency    float64 // ms
	MemAllocMB    float64
	MemSysMB      float64
	CPUGoroutines int
}

// =============================================================
// ASSINATURA ECDSA (reutilizável)
// =============================================================

type Signer struct {
	key     *ecdsa.PrivateKey
	creator []byte
}

func NewSigner(cryptoPath string) (*Signer, error) {
	certPath := cryptoPath + "/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts/Admin@example.com-cert.pem"
	certBytes, err := os.ReadFile(certPath)
	if err != nil {
		return nil, fmt.Errorf("erro ao ler certificado: %v", err)
	}

	sIdBytes, _ := proto.Marshal(&msp.SerializedIdentity{
		Mspid:   "OrdererMSP",
		IdBytes: certBytes,
	})

	keyDir := cryptoPath + "/ordererOrganizations/example.com/users/Admin@example.com/msp/keystore/"
	files, err := os.ReadDir(keyDir)
	if err != nil {
		return nil, fmt.Errorf("erro ao ler keystore: %v", err)
	}

	keyBytes, err := os.ReadFile(keyDir + files[0].Name())
	if err != nil {
		return nil, fmt.Errorf("erro ao ler chave: %v", err)
	}

	block, _ := pem.Decode(keyBytes)
	privKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		privKey, err = x509.ParseECPrivateKey(block.Bytes)
		if err != nil {
			return nil, fmt.Errorf("erro ao parsear chave privada: %v", err)
		}
	}

	return &Signer{
		key:     privKey.(*ecdsa.PrivateKey),
		creator: sIdBytes,
	}, nil
}

func (s *Signer) SignEnvelope(channelID, txID string, data []byte) (*common.Envelope, error) {
	nonce := make([]byte, 24)
	if _, err := rand.Read(nonce); err != nil {
		return nil, err
	}

	sigHeaderBytes, _ := proto.Marshal(&common.SignatureHeader{
		Creator: s.creator,
		Nonce:   nonce,
	})
	chdrBytes, _ := proto.Marshal(&common.ChannelHeader{
		ChannelId: channelID,
		Type:      int32(common.HeaderType_ENDORSER_TRANSACTION),
		TxId:      txID,
	})
	payloadBytes, _ := proto.Marshal(&common.Payload{
		Header: &common.Header{
			ChannelHeader:   chdrBytes,
			SignatureHeader: sigHeaderBytes,
		},
		Data: data,
	})

	hash := sha256.Sum256(payloadBytes)
	r, sig, err := ecdsa.Sign(rand.Reader, s.key, hash[:])
	if err != nil {
		return nil, err
	}

	// Normalização low-S (obrigatória para o Fabric)
	halfOrder := new(big.Int).Div(s.key.Curve.Params().N, big.NewInt(2))
	if sig.Cmp(halfOrder) == 1 {
		sig.Sub(s.key.Curve.Params().N, sig)
	}

	sigBytes, _ := asn1.Marshal(struct{ R, S *big.Int }{r, sig})

	return &common.Envelope{
		Payload:   payloadBytes,
		Signature: sigBytes,
	}, nil
}

// =============================================================
// CONEXÃO TLS
// =============================================================

func buildTLSCredentials(cryptoPath string) (credentials.TransportCredentials, error) {
	certFile := cryptoPath + "/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt"
	keyFile := cryptoPath + "/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key"
	caFile := cryptoPath + "/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt"

	tlsCert, err := tls.LoadX509KeyPair(certFile, keyFile)
	if err != nil {
		return nil, fmt.Errorf("erro ao carregar par TLS: %v", err)
	}

	caCert, err := os.ReadFile(caFile)
	if err != nil {
		return nil, fmt.Errorf("erro ao carregar CA: %v", err)
	}

	pool := x509.NewCertPool()
	pool.AppendCertsFromPEM(caCert)

	return credentials.NewTLS(&tls.Config{
		Certificates:       []tls.Certificate{tlsCert},
		RootCAs:            pool,
		InsecureSkipVerify: true, // PoC: desabilitar em produção
	}), nil
}

// =============================================================
// RUNNER DE UMA TRANSAÇÃO
// =============================================================

func runTx(
	id int,
	channels []string,
	clients []orderer.AtomicBroadcastClient,
	signer *Signer,
	data []byte,
	isCross bool,
) TxResult {
	txID := fmt.Sprintf("BENCH_%06d", id)
	start := time.Now()

	var txWg sync.WaitGroup
	successCh := make(chan bool, len(channels))

	for _, ch := range channels {
		txWg.Add(1)
		clientIdx := mrand.IntN(len(clients))

		go func(channelID string, c orderer.AtomicBroadcastClient) {
			defer txWg.Done()

			env, err := signer.SignEnvelope(channelID, txID, data)
			if err != nil {
				successCh <- false
				return
			}

			stream, err := c.Broadcast(context.Background())
			if err != nil {
				successCh <- false
				return
			}
			defer stream.CloseSend()

			if err := stream.Send(env); err != nil {
				successCh <- false
				return
			}

			resp, err := stream.Recv()
			if err != nil || resp.Status != 200 {
				successCh <- false
				return
			}

			successCh <- true
		}(ch, clients[clientIdx])
	}

	txWg.Wait()
	close(successCh)

	allSuccess := true
	for ok := range successCh {
		if !ok {
			allSuccess = false
		}
	}

	return TxResult{
		TxID:      txID,
		Latency:   time.Since(start),
		Success:   allSuccess,
		IsCross:   isCross,
		PayloadSz: len(data),
	}
}

// =============================================================
// BENCHMARK PRINCIPAL
// =============================================================

func runBenchmark(
	consensus string,
	totalTx int,
	payloadSize int,
	concurrency int,
	crossPercent float64,
	numShards int,
	channel string,
	clients []orderer.AtomicBroadcastClient,
	signer *Signer,
) BenchmarkResult {

	fmt.Printf("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
	fmt.Printf("  CONSENSO: %-8s | PAYLOAD: %5d B | TX: %5d | CONC: %3d\n",
		consensus, payloadSize, totalTx, concurrency)
	fmt.Printf("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")

	data := make([]byte, payloadSize)
	rand.Read(data)

	// Coleta memória ANTES
	var memBefore runtime.MemStats
	runtime.ReadMemStats(&memBefore)

	sem := make(chan struct{}, concurrency) // Semáforo para controlar concorrência
	results := make([]TxResult, 0, totalTx)
	var mu sync.Mutex
	var wg sync.WaitGroup

	start := time.Now()

	for i := 1; i <= totalTx; i++ {
		sem <- struct{}{} // Bloqueia se atingiu o limite de concorrência
		wg.Add(1)

		go func(id int) {
			defer wg.Done()
			defer func() { <-sem }() // Libera slot ao terminar

			// Decide se é cross-shard
			var channels []string
			isCross := false

			if numShards > 1 && mrand.Float64() < crossPercent {
				s1 := mrand.IntN(numShards) + 1
				s2 := ((s1 + mrand.IntN(numShards-1)) % numShards) + 1
				channels = []string{
					fmt.Sprintf("canal%d", s1),
					fmt.Sprintf("canal%d", s2),
				}
				isCross = true
			} else {
				if numShards > 1 {
					channels = []string{fmt.Sprintf("canal%d", mrand.IntN(numShards)+1)}
				} else {
					channels = []string{channel}
				}
			}

			result := runTx(id, channels, clients, signer, data, isCross)

			mu.Lock()
			results = append(results, result)
			mu.Unlock()

			// Progress a cada 10%
			if id%(totalTx/10) == 0 {
				fmt.Printf("  ⏳ %d%% concluído...\n", (id*100)/totalTx)
			}
		}(i)
	}

	wg.Wait()
	duration := time.Since(start)

	// Coleta memória DEPOIS
	var memAfter runtime.MemStats
	runtime.ReadMemStats(&memAfter)

	// Calcula métricas
	var latencies []time.Duration
	successCount := 0
	for _, r := range results {
		if r.Success {
			successCount++
			latencies = append(latencies, r.Latency)
		}
	}

	sort.Slice(latencies, func(i, j int) bool { return latencies[i] < latencies[j] })

	var totalLat int64
	for _, l := range latencies {
		totalLat += l.Milliseconds()
	}

	n := len(latencies)
	avgLat := float64(totalLat) / float64(n)
	p50 := latencies[int(float64(n)*0.50)].Seconds() * 1000
	p95 := latencies[int(float64(n)*0.95)].Seconds() * 1000
	p99 := latencies[int(float64(n)*0.99)].Seconds() * 1000
	maxLat := latencies[n-1].Seconds() * 1000

	allocDiff := float64(memAfter.TotalAlloc-memBefore.TotalAlloc) / 1024 / 1024
	sysMB := float64(memAfter.Sys) / 1024 / 1024

	result := BenchmarkResult{
		Consensus:     consensus,
		TotalTx:       totalTx,
		SuccessTx:     successCount,
		PayloadSize:   payloadSize,
		Concurrency:   concurrency,
		CrossPercent:  crossPercent,
		Duration:      duration,
		TPS:           float64(successCount) / duration.Seconds(),
		AvgLatency:    avgLat,
		P50Latency:    p50,
		P95Latency:    p95,
		P99Latency:    p99,
		MaxLatency:    maxLat,
		MemAllocMB:    allocDiff,
		MemSysMB:      sysMB,
		CPUGoroutines: runtime.NumGoroutine(),
	}

	fmt.Printf("  ✅ TPS:      %.2f\n", result.TPS)
	fmt.Printf("  ⏱️  Lat Avg:  %.2f ms\n", result.AvgLatency)
	fmt.Printf("  ⏱️  Lat P95:  %.2f ms\n", result.P95Latency)
	fmt.Printf("  ⏱️  Lat P99:  %.2f ms\n", result.P99Latency)
	fmt.Printf("  💾 Mem Alloc: %.2f MB\n", result.MemAllocMB)

	return result
}

// =============================================================
// EXPORTAR CSV
// =============================================================

func writeCSV(filename string, results []BenchmarkResult) error {
	f, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer f.Close()

	w := csv.NewWriter(f)
	defer w.Flush()

	// Cabeçalho
	w.Write([]string{
		"consensus", "total_tx", "success_tx", "payload_bytes",
		"concurrency", "cross_percent", "duration_s",
		"tps", "avg_lat_ms", "p50_lat_ms", "p95_lat_ms", "p99_lat_ms", "max_lat_ms",
		"mem_alloc_mb", "mem_sys_mb", "goroutines",
	})

	for _, r := range results {
		w.Write([]string{
			r.Consensus,
			strconv.Itoa(r.TotalTx),
			strconv.Itoa(r.SuccessTx),
			strconv.Itoa(r.PayloadSize),
			strconv.Itoa(r.Concurrency),
			fmt.Sprintf("%.2f", r.CrossPercent),
			fmt.Sprintf("%.3f", r.Duration.Seconds()),
			fmt.Sprintf("%.2f", r.TPS),
			fmt.Sprintf("%.2f", r.AvgLatency),
			fmt.Sprintf("%.2f", r.P50Latency),
			fmt.Sprintf("%.2f", r.P95Latency),
			fmt.Sprintf("%.2f", r.P99Latency),
			fmt.Sprintf("%.2f", r.MaxLatency),
			fmt.Sprintf("%.2f", r.MemAllocMB),
			fmt.Sprintf("%.2f", r.MemSysMB),
			strconv.Itoa(r.CPUGoroutines),
		})
	}
	return nil
}

// =============================================================
// MAIN: MATRIZ DE EXPERIMENTOS
// =============================================================

func main() {
	flag.Parse()

	fmt.Printf("🔬 Benchmark de Consenso Hyperledger Fabric\n")
	fmt.Printf("   Alvo: %s | Output: %s\n\n", *flagConsensus, *flagOutput)

	// --- TLS e conexões ---
	creds, err := buildTLSCredentials(*flagCryptoPath)
	if err != nil {
		fmt.Printf("❌ Erro TLS: %v\n", err)
		os.Exit(1)
	}

	addresses, ok := consensusAddresses[*flagConsensus]
	if !ok {
		fmt.Printf("❌ Consenso desconhecido: %s\n", *flagConsensus)
		os.Exit(1)
	}

	clients := make([]orderer.AtomicBroadcastClient, len(addresses))
	for i, addr := range addresses {
		conn, err := grpc.Dial(addr, grpc.WithTransportCredentials(creds))
		if err != nil {
			fmt.Printf("❌ Falha ao conectar em %s: %v\n", addr, err)
			os.Exit(1)
		}
		defer conn.Close()
		clients[i] = orderer.NewAtomicBroadcastClient(conn)
	}

	// --- Identidade ---
	signer, err := NewSigner(*flagCryptoPath)
	if err != nil {
		fmt.Printf("❌ Erro ao criar signer: %v\n", err)
		os.Exit(1)
	}

	var allResults []BenchmarkResult

	// ==========================================
	// CENÁRIO 1: Teste único com parâmetros CLI
	// ==========================================
	if *flagTotalTx > 0 {
		r := runBenchmark(
			*flagConsensus,
			*flagTotalTx,
			*flagPayload,
			*flagConcurrency,
			*flagCrossPercent,
			*flagNumShards,
			*flagChannel,
			clients,
			signer,
		)
		allResults = append(allResults, r)
	}

	// ==========================================
	// CENÁRIO 2: Varredura de payload sizes
	// Comente/descomente conforme necessário
	// ==========================================
	/*
		payloadSizes := []int{256, 1024, 4096, 16384}
		for _, sz := range payloadSizes {
			r := runBenchmark(
				*flagConsensus, 1000, sz, *flagConcurrency,
				0.0, 1, *flagChannel, clients, signer,
			)
			allResults = append(allResults, r)
			time.Sleep(2 * time.Second) // cooldown entre rodadas
		}
	*/

	// ==========================================
	// CENÁRIO 3: Varredura de concorrência
	// ==========================================
	/*
		concurrencyLevels := []int{10, 25, 50, 100, 200}
		for _, conc := range concurrencyLevels {
			r := runBenchmark(
				*flagConsensus, 2000, *flagPayload, conc,
				0.0, 1, *flagChannel, clients, signer,
			)
			allResults = append(allResults, r)
			time.Sleep(2 * time.Second)
		}
	*/

	// Salva CSV
	if err := writeCSV(*flagOutput, allResults); err != nil {
		fmt.Printf("❌ Erro ao salvar CSV: %v\n", err)
	} else {
		fmt.Printf("\n📊 Resultados salvos em: %s\n", *flagOutput)
	}

	// Resumo final
	fmt.Printf("\n════════════════════════════════════════════════════════\n")
	fmt.Printf("  RESUMO FINAL — %d cenário(s)\n", len(allResults))
	fmt.Printf("════════════════════════════════════════════════════════\n")
	for _, r := range allResults {
		fmt.Printf("  %-8s | %5dB | TPS: %7.2f | P95: %6.2fms | Mem: %5.1fMB\n",
			r.Consensus, r.PayloadSize, r.TPS, r.P95Latency, r.MemAllocMB)
	}
}

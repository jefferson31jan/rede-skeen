package main

import (
	"context"
	"crypto/ecdsa"
	"crypto/rand"
	"crypto/sha256"
	"crypto/tls"
	"crypto/x509"
	"encoding/asn1"
	"encoding/pem"
	"flag"
	"fmt"
	"math/big"
	mrand "math/rand/v2"
	"os"
	"sort"
	"sync"
	"time"

	"github.com/hyperledger/fabric-protos-go-apiv2/common"
	"github.com/hyperledger/fabric-protos-go-apiv2/msp"
	"github.com/hyperledger/fabric-protos-go-apiv2/orderer"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/protobuf/proto"
)

// ==========================================
// CONFIGURAÇÕES DO EXPERIMENTO (VARIÁVEIS)
// ==========================================
var (
	TOTAL_TX               int
	PAYLOAD_SIZE           int
	PERCENTUAL_CROSS_SHARD float64
	NUM_SHARDS             int
)

func main() {
	// --- CAPTURA DE ARGUMENTOS DO TERMINAL ---
	flag.IntVar(&TOTAL_TX, "tx", 100000, "Total de transações a enviar")
	flag.IntVar(&PAYLOAD_SIZE, "payload", 4096, "Tamanho do Payload")
	flag.Float64Var(&PERCENTUAL_CROSS_SHARD, "cross", 0.0, "Probabilidade Cross-Shard")
	flag.IntVar(&NUM_SHARDS, "shards", 4, "Número de Shards")
	flag.Parse()

	fmt.Printf("📊 Iniciando Benchmark Skeen BFT (Escalabilidade %d Shards)...\n", NUM_SHARDS)
	fmt.Printf("📦 Payload: %d bytes | 🚀 Total: %d | 🌐 Prob. Cross-Shard: %.0f%%\n", PAYLOAD_SIZE, TOTAL_TX, PERCENTUAL_CROSS_SHARD*100)

	// --- Configuração de TLS ---
	tlsCert, _ := tls.LoadX509KeyPair("../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt", "../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key")
	caCert, _ := os.ReadFile("../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt")
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	creds := credentials.NewTLS(&tls.Config{
		Certificates:       []tls.Certificate{tlsCert},
		RootCAs:            caCertPool,
		InsecureSkipVerify: true, // Fundamental para ignorar mismatch de Hostname no laboratório
	})

	// --- Pool de Conexões para os Orderers (Balanceamento do Cliente) ---
	addresses := []string{
		"127.0.0.1:7050", "127.0.0.1:8050", "127.0.0.1:9050", "127.0.0.1:10050",
	}

	clients := make([]orderer.AtomicBroadcastClient, len(addresses))
	for i, addr := range addresses {
		conn, err := grpc.Dial(addr, grpc.WithTransportCredentials(creds))
		if err != nil {
			fmt.Printf("❌ Erro ao conectar no Orderer %d (%s): %v\n", i+1, addr, err)
			os.Exit(1)
		}
		defer conn.Close()
		clients[i] = orderer.NewAtomicBroadcastClient(conn)
	}

	// --- Identidade e Chaves do Admin ---
	certBytes, _ := os.ReadFile("../crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts/Admin@example.com-cert.pem")
	sIdBytes, _ := proto.Marshal(&msp.SerializedIdentity{Mspid: "OrdererMSP", IdBytes: certBytes})
	keyDir := "../crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/keystore/"
	files, _ := os.ReadDir(keyDir)
	keyBytes, _ := os.ReadFile(keyDir + files[0].Name())
	block, _ := pem.Decode(keyBytes)
	privKey, _ := x509.ParsePKCS8PrivateKey(block.Bytes)
	if privKey == nil {
		privKey, _ = x509.ParseECPrivateKey(block.Bytes)
	}
	ecdsaKey := privKey.(*ecdsa.PrivateKey)

	// --- Geração do Payload ---
	dummyData := make([]byte, PAYLOAD_SIZE)
	_, _ = rand.Read(dummyData)

	var wg sync.WaitGroup
	var latencies []time.Duration
	var latMutex sync.Mutex

	intraCount := 0
	interCount := 0
	inicio := time.Now()

	// --- Início do Disparo de Transações ---
	for i := 1; i <= TOTAL_TX; i++ {
		wg.Add(1)

		go func(id int) {
			defer wg.Done()
			txID := fmt.Sprintf("BENCH_4S_%05d", id)
			var canaisAlvo []string

			// --- Lógica de Roteamento (Sharding & Cross-Shard) ---
			if mrand.Float64() < PERCENTUAL_CROSS_SHARD {
				// Sorteia dois canais distintos (Cross-Shard)
				s1 := mrand.IntN(NUM_SHARDS) + 1
				s2 := ((s1 + mrand.IntN(NUM_SHARDS-1)) % NUM_SHARDS) + 1
				canaisAlvo = []string{fmt.Sprintf("canal%d", s1), fmt.Sprintf("canal%d", s2)}

				latMutex.Lock()
				interCount++
				latMutex.Unlock()
			} else {
				// Sorteia um único canal (Intra-Shard)
				target := fmt.Sprintf("canal%d", mrand.IntN(NUM_SHARDS)+1)
				canaisAlvo = []string{target}

				latMutex.Lock()
				intraCount++
				latMutex.Unlock()
			}

			txStart := time.Now()
			var txWg sync.WaitGroup

			// Dispara a transação para o(s) canal(is) selecionado(s)
			for _, canal := range canaisAlvo {
				wg.Add(1)
				txWg.Add(1)

				// Seleciona um cliente aleatório do pool para balancear a carga gRPC
				clientIdx := mrand.IntN(len(clients))
				ordererClient := clients[clientIdx]

				go func(targetChannel string, c orderer.AtomicBroadcastClient) {
					defer wg.Done()
					defer txWg.Done()

					stream, err := c.Broadcast(context.Background())
					if err != nil {
						return
					}

					nonce := make([]byte, 24)
					_, _ = rand.Read(nonce)
					sigHeaderBytes, _ := proto.Marshal(&common.SignatureHeader{Creator: sIdBytes, Nonce: nonce})
					chdrBytes, _ := proto.Marshal(&common.ChannelHeader{ChannelId: targetChannel, Type: int32(common.HeaderType_ENDORSER_TRANSACTION), TxId: txID})

					payloadBytes, _ := proto.Marshal(&common.Payload{
						Header: &common.Header{ChannelHeader: chdrBytes, SignatureHeader: sigHeaderBytes},
						Data:   dummyData,
					})

					hash := sha256.Sum256(payloadBytes)
					r, s, _ := ecdsa.Sign(rand.Reader, ecdsaKey, hash[:])

					halfOrder := new(big.Int).Div(ecdsaKey.Curve.Params().N, big.NewInt(2))
					if s.Cmp(halfOrder) == 1 {
						s.Sub(ecdsaKey.Curve.Params().N, s)
					}
					sigBytes, _ := asn1.Marshal(struct{ R, S *big.Int }{r, s})

					_ = stream.Send(&common.Envelope{Payload: payloadBytes, Signature: sigBytes})
					_, _ = stream.Recv()
				}(canal, ordererClient)
			}

			txWg.Wait() // Aguarda todos os envios desta transação específica

			// Registra a latência total
			latMutex.Lock()
			latencies = append(latencies, time.Since(txStart))
			latMutex.Unlock()
		}(i)
	}

	wg.Wait() // Aguarda todas as transações finalizarem
	duracao := time.Since(inicio)
	tps := float64(TOTAL_TX) / duracao.Seconds()

	// --- Cálculo de Estatísticas ---
	sort.Slice(latencies, func(i, j int) bool { return latencies[i] < latencies[j] })
	var totalLat int64
	for _, l := range latencies {
		totalLat += l.Milliseconds()
	}
	avgLat := float64(totalLat) / float64(len(latencies))
	p95Index := int(float64(len(latencies)) * 0.95)

	fmt.Printf("\n======================================================\n")
	fmt.Printf("🏁 SKEEN BFT (%d-SHARDS) - CONFIGURAÇÃO TURBO\n", NUM_SHARDS)
	fmt.Printf("📝 Transactions: %d (Intra: %d | Inter: %d)\n", TOTAL_TX, intraCount, interCount)
	fmt.Printf("📈 THROUGHPUT (Vazão): %.2f TPS\n", tps)
	fmt.Printf("⏱️  LATÊNCIA MÉDIA: %.2f ms\n", avgLat)
	if len(latencies) > 0 {
		fmt.Printf("⏱️  LATÊNCIA P95: %d ms\n", latencies[p95Index].Milliseconds())
	}
	fmt.Printf("======================================================\n")
}

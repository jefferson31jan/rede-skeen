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
	"strings"
	"sync"
	"time"

	"github.com/hyperledger/fabric-protos-go-apiv2/common"
	"github.com/hyperledger/fabric-protos-go-apiv2/msp"
	"github.com/hyperledger/fabric-protos-go-apiv2/orderer"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/protobuf/proto"
)

var (
	TOTAL_TX               int
	PAYLOAD_SIZE           int
	PERCENTUAL_CROSS_SHARD float64
	NUM_SHARDS             int
)

func main() {
	// 1. DECLARAÇÃO DE TODAS AS FLAGS PRIMEIRO
	flag.IntVar(&TOTAL_TX, "tx", 1, "Total de transações a enviar")
	flag.IntVar(&PAYLOAD_SIZE, "payload", 1, "Tamanho do Payload")
	flag.Float64Var(&PERCENTUAL_CROSS_SHARD, "cross", 0, "Probabilidade Cross-Shard")
	flag.IntVar(&NUM_SHARDS, "shards", 1, "Número de Shards")
	consensusType := flag.String("consensus", "skeen", "Protocolo de consenso (skeen, raft, bftsmart)")

	// 2. PARSE DAS FLAGS (MUITO IMPORTANTE FICAR AQUI)
	flag.Parse()

	runID := time.Now().UnixMilli() // Cria um ID único baseado na hora atual

	// Atualizado para mostrar o protocolo logo no início também
	fmt.Printf("📊 Iniciando Benchmark %s (Roteamento Determinístico)...\n", strings.ToUpper(*consensusType))

	// AJUSTE DE CAMINHO: Lendo direto da raiz (./crypto-config)
	tlsCert, _ := tls.LoadX509KeyPair("./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt", "./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key")
	caCert, _ := os.ReadFile("./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt")
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	creds := credentials.NewTLS(&tls.Config{Certificates: []tls.Certificate{tlsCert}, RootCAs: caCertPool, InsecureSkipVerify: true})

	shardRouter := map[string]string{
		"canal1": "127.0.0.1:7050", "canal2": "127.0.0.1:8050",
		"canal3": "127.0.0.1:9050", "canal4": "127.0.0.1:10050",
	}

	smartClients := make(map[string]orderer.AtomicBroadcastClient)
	for i := 1; i <= NUM_SHARDS; i++ {
		canalID := fmt.Sprintf("canal%d", i)
		conn, err := grpc.NewClient(shardRouter[canalID], grpc.WithTransportCredentials(creds))

		if err != nil {
			os.Exit(1)
		}
		defer conn.Close()
		smartClients[canalID] = orderer.NewAtomicBroadcastClient(conn)
	}

	// AJUSTE DE CAMINHO: Lendo direto da raiz
	certBytes, _ := os.ReadFile("./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts/Admin@example.com-cert.pem")
	sIdBytes, _ := proto.Marshal(&msp.SerializedIdentity{Mspid: "OrdererMSP", IdBytes: certBytes})
	keyDir := "./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/keystore/"

	files, _ := os.ReadDir(keyDir)
	keyBytes, _ := os.ReadFile(keyDir + files[0].Name())
	block, _ := pem.Decode(keyBytes)
	privKey, _ := x509.ParsePKCS8PrivateKey(block.Bytes)
	if privKey == nil {
		privKey, _ = x509.ParseECPrivateKey(block.Bytes)
	}
	ecdsaKey := privKey.(*ecdsa.PrivateKey)

	dummyData := make([]byte, PAYLOAD_SIZE)
	_, _ = rand.Read(dummyData)

	var wg sync.WaitGroup
	var latencies []time.Duration
	var latMutex sync.Mutex
	intraCount, interCount := 0, 0
	inicio := time.Now()

	for i := 1; i <= TOTAL_TX; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			var txID string
			var canaisAlvo []string

			// --- MÁGICA DO ROTEAMENTO DETERMINÍSTICO (Global/Multi-Shard) ---
			if mrand.Float64() < PERCENTUAL_CROSS_SHARD && NUM_SHARDS > 1 {

				// NOVO: Transação Cross-Shard agora envolve TODOS os Shards configurados
				canaisAlvo = make([]string, NUM_SHARDS)
				for j := 1; j <= NUM_SHARDS; j++ {
					canaisAlvo[j-1] = fmt.Sprintf("canal%d", j)
				}
				sort.Strings(canaisAlvo) // Ex: [canal1, canal2, canal3, canal4]

				txID = fmt.Sprintf("CROSS_%s_RUN%d_BENCH_%05d", strings.Join(canaisAlvo, "-"), runID, id)

				latMutex.Lock()
				interCount++
				latMutex.Unlock()
			} else {
				// Transação Intra-Shard (Escolhe apenas 1 Shard aleatoriamente)
				target := fmt.Sprintf("canal%d", mrand.IntN(NUM_SHARDS)+1)
				canaisAlvo = []string{target}

				txID = fmt.Sprintf("INTRA_%s_RUN%d_BENCH_%05d", target, runID, id)

				latMutex.Lock()
				intraCount++
				latMutex.Unlock()
			}

			txStart := time.Now()
			var txWg sync.WaitGroup

			// Dispara a transação simultaneamente PARA TODOS OS ALVOS ESCOLHIDOS
			for _, canal := range canaisAlvo {
				txWg.Add(1)
				ordererClient := smartClients[canal]

				go func(targetChannel string, c orderer.AtomicBroadcastClient) {
					defer txWg.Done()
					stream, err := c.Broadcast(context.Background())
					if err != nil {
						return
					}

					nonce := make([]byte, 24)
					_, _ = rand.Read(nonce)
					sigHeaderBytes, _ := proto.Marshal(&common.SignatureHeader{Creator: sIdBytes, Nonce: nonce})
					chdrBytes, _ := proto.Marshal(&common.ChannelHeader{
						ChannelId: targetChannel, Type: int32(common.HeaderType_ENDORSER_TRANSACTION), TxId: txID,
					})

					payloadBytes, _ := proto.Marshal(&common.Payload{
						Header: &common.Header{ChannelHeader: chdrBytes, SignatureHeader: sigHeaderBytes}, Data: dummyData,
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
			txWg.Wait()
			latMutex.Lock()
			latencies = append(latencies, time.Since(txStart))
			latMutex.Unlock()
		}(i)
	}

	wg.Wait()
	duracao := time.Since(inicio)
	tps := float64(TOTAL_TX) / duracao.Seconds()
	sort.Slice(latencies, func(i, j int) bool { return latencies[i] < latencies[j] })
	var totalLat int64
	for _, l := range latencies {
		totalLat += l.Milliseconds()
	}
	avgLat := float64(totalLat) / float64(len(latencies))
	
	// 3. IMPRESSÃO CORRIGIDA (Usando as variáveis corretas)
	fmt.Printf("\n======================================================\n")
	fmt.Printf("🏁 %s (%d-SHARDS) - ROTEAMENTO DETERMINÍSTICO\n", strings.ToUpper(*consensusType), NUM_SHARDS)
	fmt.Printf("📝 Transactions: %d (Intra: %d | Inter: %d)\n", TOTAL_TX, intraCount, interCount)
	fmt.Printf("📈 THROUGHPUT (Vazão): %.2f TPS\n", tps)
	fmt.Printf("⏱️  LATÊNCIA MÉDIA: %.2f ms\n", avgLat)
	fmt.Printf("======================================================\n")
}
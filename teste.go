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
	mrand "math/rand/v2" // Go 1.22+ rand/v2
	"os"
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
	TOTAL_TX     int
	NUM_SHARDS   int
	CROSS_PROB   float64
	PAYLOAD_SIZE int
)

func main() {
	flag.IntVar(&TOTAL_TX, "tx", 1, "Total de transações")
	flag.IntVar(&NUM_SHARDS, "shards", 4, "Número de shards envolvidos na Tx (1 a 4)")
	flag.Float64Var(&CROSS_PROB, "cross", 1.0, "Probabilidade Cross-Shard")
	flag.IntVar(&PAYLOAD_SIZE, "payload", 1, "Tamanho do payload")
	flag.Parse()

	runID := time.Now().UnixMilli()

	// 1. CREDENCIAIS TLS
	tlsCert, _ := tls.LoadX509KeyPair("./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt", "./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key")
	caCert, _ := os.ReadFile("./crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt")
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)
	creds := credentials.NewTLS(&tls.Config{Certificates: []tls.Certificate{tlsCert}, RootCAs: caCertPool, InsecureSkipVerify: true})

	shardRouter := map[string]string{
		"canal1": "127.0.0.1:7050", "canal2": "127.0.0.1:8050",
		"canal3": "127.0.0.1:9050", "canal4": "127.0.0.1:10050",
	}

	// 2. CREDENCIAIS MSP (ADMIN)
	certBytes, _ := os.ReadFile("./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts/Admin@example.com-cert.pem")
	sIdBytes, _ := proto.Marshal(&msp.SerializedIdentity{Mspid: "OrdererMSP", IdBytes: certBytes})
	keyDir := "./crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/keystore/"
	files, _ := os.ReadDir(keyDir)
	keyBytes, _ := os.ReadFile(keyDir + files[0].Name())
	block, _ := pem.Decode(keyBytes)
	privKey, _ := x509.ParsePKCS8PrivateKey(block.Bytes)
	ecdsaKey := privKey.(*ecdsa.PrivateKey)

	fmt.Printf("🚀 SKEEN MULTICAST ALEATÓRIO: Injetando %d Txs (%d Shards/Tx, %.0f%% Cross)\n", TOTAL_TX, NUM_SHARDS, CROSS_PROB*100)

	var wg sync.WaitGroup
	start := time.Now()

	for i := 1; i <= TOTAL_TX; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()

			// --- LÓGICA DE ALEATORIEDADE TOTAL ---
			var targets []string
			// Lista de todos os canais possíveis fisicamente na sua rede
			allPossibleShards := []string{"canal1", "canal2", "canal3", "canal4"}

			if mrand.Float64() < CROSS_PROB && NUM_SHARDS > 1 {
				// 🎲 Sorteio Cross-Shard: Embaralha a lista global e pega a quantidade definida em NUM_SHARDS
				mrand.Shuffle(len(allPossibleShards), func(i, j int) {
					allPossibleShards[i], allPossibleShards[j] = allPossibleShards[j], allPossibleShards[i]
				})
				// Garante que pegamos apenas a quantidade solicitada via flag
				targets = allPossibleShards[:NUM_SHARDS]
			} else {
				// 🎲 Sorteio Intra-Shard: Escolhe 1 canal aleatório entre os 4
				targets = []string{allPossibleShards[mrand.IntN(4)]}
			}

			// Criar o ID da transação com os canais sorteados
			txID := fmt.Sprintf("CROSS_%s_RUN%d_%d", strings.Join(targets, "-"), runID, id)

			// 🚨 MULTICAST REAL: Envia o gRPC para todos os canais sorteados na lista targets
			var txWg sync.WaitGroup
			for _, canalId := range targets {
				txWg.Add(1)
				go func(c string) {
					defer txWg.Done()

					conn, err := grpc.Dial(shardRouter[c], grpc.WithTransportCredentials(creds))
					if err != nil {
						return
					}
					defer conn.Close()

					client := orderer.NewAtomicBroadcastClient(conn)
					nonce := make([]byte, 24)
					rand.Read(nonce)
					chdr, _ := proto.Marshal(&common.ChannelHeader{ChannelId: c, Type: 3, TxId: txID})
					shdr, _ := proto.Marshal(&common.SignatureHeader{Creator: sIdBytes, Nonce: nonce})
					payloadBytes, _ := proto.Marshal(&common.Payload{
						Header: &common.Header{ChannelHeader: chdr, SignatureHeader: shdr},
						Data:   make([]byte, PAYLOAD_SIZE),
					})

					hash := sha256.Sum256(payloadBytes)
					r, s, _ := ecdsa.Sign(rand.Reader, ecdsaKey, hash[:])
					halfOrder := new(big.Int).Div(ecdsaKey.Curve.Params().N, big.NewInt(2))
					if s.Cmp(halfOrder) == 1 {
						s.Sub(ecdsaKey.Curve.Params().N, s)
					}
					sigBytes, _ := asn1.Marshal(struct{ R, S *big.Int }{r, s})

					stream, err := client.Broadcast(context.Background())
					if err != nil {
						return
					}

					stream.Send(&common.Envelope{Payload: payloadBytes, Signature: sigBytes})
					stream.Recv() // Espera o OK do consenso
				}(canalId)
			}
			txWg.Wait()
		}(i)
	}

	wg.Wait()
	duration := time.Since(start).Seconds()
	fmt.Printf("\n🏁 BENCHMARK CONCLUÍDO\nTempo: %.2f s | TPS: %.2f\n", duration, float64(TOTAL_TX)/duration)
}

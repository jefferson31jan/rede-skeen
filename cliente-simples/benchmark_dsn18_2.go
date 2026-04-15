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
	"fmt"
	"math/big"
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
// CONFIGURAÇÕES DO EXPERIMENTO
// ==========================================
const TOTAL_TX = 5000
const PAYLOAD_SIZE = 1024 // Teste o Ponto Doce
const MODO_CROSS_SHARD = true

func main() {
	fmt.Printf("📊 Iniciando Benchmark DSN 2018 (Análise de Latência)...\n")
	fmt.Printf("📦 Payload: %d bytes | 🚀 Total: %d | 🌐 Cross-Shard: %v\n", PAYLOAD_SIZE, TOTAL_TX, MODO_CROSS_SHARD)

	tlsCert, _ := tls.LoadX509KeyPair("../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt", "../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key")
	caCert, _ := os.ReadFile("../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt")
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	creds := credentials.NewTLS(&tls.Config{Certificates: []tls.Certificate{tlsCert}, RootCAs: caCertPool, ServerName: "orderer.example.com"})
	conn, _ := grpc.Dial("127.0.0.1:7050", grpc.WithTransportCredentials(creds))
	defer conn.Close()
	client := orderer.NewAtomicBroadcastClient(conn)

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

	dummyData := make([]byte, PAYLOAD_SIZE)
	rand.Read(dummyData)

	var wg sync.WaitGroup
	var latencies []time.Duration
	var latMutex sync.Mutex
	inicio := time.Now()

	for i := 1; i <= TOTAL_TX; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			txID := fmt.Sprintf("BENCHMARK_%05d", id)
			canaisAlvo := []string{"canal1"}
			if MODO_CROSS_SHARD {
				canaisAlvo = []string{"canal1", "canal2"}
			}

			txStart := time.Now()
			var txWg sync.WaitGroup // <--- NOVA WaitGroup para sincronizar o relógio desta TX

			for _, canal := range canaisAlvo {
				wg.Add(1)
				txWg.Add(1) // Registra que estamos esperando uma resposta deste canal
				go func(targetChannel string) {
					defer wg.Done()
					defer txWg.Done() // Avisa que a resposta chegou

					stream, _ := client.Broadcast(context.Background())
					nonce := make([]byte, 24)
					rand.Read(nonce)
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

					stream.Send(&common.Envelope{Payload: payloadBytes, Signature: sigBytes})
					stream.Recv() // Aguarda o ACK de recebimento do Fabric
				}(canal)
			}

			// AGORA SIM: Espera as confirmações da rede antes de parar o relógio
			txWg.Wait()

			latMutex.Lock()
			latencies = append(latencies, time.Since(txStart))
			latMutex.Unlock()
		}(i)
	}

	wg.Wait()
	duracao := time.Since(inicio)
	tps := float64(TOTAL_TX) / duracao.Seconds()

	// Cálculos Estatísticos
	sort.Slice(latencies, func(i, j int) bool { return latencies[i] < latencies[j] })
	var totalLat int64
	for _, l := range latencies {
		totalLat += l.Milliseconds()
	}
	avgLat := float64(totalLat) / float64(len(latencies))
	p95Index := int(float64(len(latencies)) * 0.95)

	fmt.Printf("\n======================================================\n")
	fmt.Printf("🏁 BENCHMARK CONCLUÍDO!\n")
	fmt.Printf("📈 THROUGHPUT (Vazão): %.2f TPS\n", tps)
	fmt.Printf("⏱️  LATÊNCIA MÉDIA: %.2f ms\n", avgLat)
	fmt.Printf("⏱️  LATÊNCIA P95: %d ms\n", latencies[p95Index].Milliseconds())
	fmt.Printf("======================================================\n")
}

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
	"log"
	"math/big"
	"os"
	"sync"
	"time"

	"github.com/hyperledger/fabric-protos-go-apiv2/common"
	"github.com/hyperledger/fabric-protos-go-apiv2/msp"
	"github.com/hyperledger/fabric-protos-go-apiv2/orderer"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/protobuf/proto"
)

func main() {
	fmt.Println("🔧 Inicializando Canhão Skeen BFT (Teste de Stress)...")

	// ====================================================================
	// 1. PREPARAÇÃO (Lemos o disco apenas 1 vez para máxima performance)
	// ====================================================================

	tlsCert, _ := tls.LoadX509KeyPair(
		"../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.crt",
		"../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/server.key",
	)
	caCert, _ := os.ReadFile("../crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt")
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	creds := credentials.NewTLS(&tls.Config{
		Certificates: []tls.Certificate{tlsCert},
		RootCAs:      caCertPool,
		ServerName:   "orderer.example.com",
	})

	// Abrimos UMA ÚNICA conexão TCP robusta com o Orderer 1
	conn, err := grpc.Dial("127.0.0.1:7050", grpc.WithTransportCredentials(creds))
	if err != nil {
		log.Fatalf("Falha conexao: %v", err)
	}
	defer conn.Close()
	client := orderer.NewAtomicBroadcastClient(conn)

	// Carregamos a Identidade do Admin na RAM
	certBytes, _ := os.ReadFile("../crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts/Admin@example.com-cert.pem")
	sId := &msp.SerializedIdentity{
		Mspid:   "OrdererMSP",
		IdBytes: certBytes,
	}
	sIdBytes, _ := proto.Marshal(sId)

	// Carregamos a Chave Privada na RAM
	keyDir := "../crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/keystore/"
	files, _ := os.ReadDir(keyDir)
	keyBytes, _ := os.ReadFile(keyDir + files[0].Name())

	block, _ := pem.Decode(keyBytes)
	privKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		privKey, _ = x509.ParseECPrivateKey(block.Bytes)
	}
	ecdsaKey := privKey.(*ecdsa.PrivateKey)

	// ====================================================================
	// 2. A TEMPESTADE (Disparo Simultâneo via Goroutines)
	// ====================================================================

	var wg sync.WaitGroup
	numeroDeTransacoes := 10 // Começamos com 10. Você pode aumentar depois!

	inicio := time.Now()

	for i := 1; i <= numeroDeTransacoes; i++ {
		wg.Add(1) // Adiciona um soldado na missão

		go func(id int) {
			defer wg.Done() // Soldado avisa quando terminar

			// Cada thread abre a sua própria "via" de comunicação dentro da conexão TCP
			stream, err := client.Broadcast(context.Background())
			if err != nil {
				log.Printf("❌ [Thread %d] Falha ao criar stream: %v", id, err)
				return
			}

			// Gera um ID sequencial para facilitar o seu rastreio nos logs do Fabric
			txID := fmt.Sprintf("SKEEN_STRESS_%03d", id)

			// O Nonce precisa ser único para CADA transação
			nonce := make([]byte, 24)
			rand.Read(nonce)

			sigHeader := &common.SignatureHeader{
				Creator: sIdBytes,
				Nonce:   nonce,
			}
			sigHeaderBytes, _ := proto.Marshal(sigHeader)

			chdr := &common.ChannelHeader{
				ChannelId: "canal1",
				Type:      int32(common.HeaderType_ENDORSER_TRANSACTION),
				TxId:      txID,
			}
			chdrBytes, _ := proto.Marshal(chdr)

			payload := &common.Payload{
				Header: &common.Header{
					ChannelHeader:   chdrBytes,
					SignatureHeader: sigHeaderBytes,
				},
				Data: []byte(fmt.Sprintf("Conteudo atrelado a transacao %s", txID)),
			}
			payloadBytes, _ := proto.Marshal(payload)

			// === ASSINATURA INDIVIDUAL ===
			hash := sha256.Sum256(payloadBytes)
			r, s, _ := ecdsa.Sign(rand.Reader, ecdsaKey, hash[:])

			// Vacina do Fabric: Forçar curva Low-S
			halfOrder := new(big.Int).Div(ecdsaKey.Curve.Params().N, big.NewInt(2))
			if s.Cmp(halfOrder) == 1 {
				s.Sub(ecdsaKey.Curve.Params().N, s)
			}

			type ecdsaSignature struct{ R, S *big.Int }
			sigBytes, _ := asn1.Marshal(ecdsaSignature{r, s})

			env := &common.Envelope{
				Payload:   payloadBytes,
				Signature: sigBytes,
			}

			fmt.Printf("🚀 Disparando: [%s]...\n", txID)

			// Manda para o motor Skeen
			err = stream.Send(env)
			if err != nil {
				log.Printf("❌ [%s] Erro no envio: %v", txID, err)
				return
			}

			// Aguarda o ACK do Skeen confirmando a validação
			reply, err := stream.Recv()
			if err != nil {
				log.Printf("❌ [%s] Erro na resposta: %v", txID, err)
				return
			}

			fmt.Printf("✅ [%s] Consolidada! Status: %s\n", txID, reply.Status)
		}(i) // Passamos o ID atual para dentro da Thread
	}

	// O programa principal trava aqui e espera TODAS as 10 responderem
	wg.Wait()

	duracao := time.Since(inicio)
	fmt.Printf("\n======================================================\n")
	fmt.Printf("🏁 TESTE DE STRESS SKEEN BFT CONCLUÍDO!\n")
	fmt.Printf("📊 %d Transações ordenadas em %v\n", numeroDeTransacoes, duracao)
	fmt.Printf("======================================================\n")
}

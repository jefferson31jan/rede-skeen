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

	"github.com/hyperledger/fabric-protos-go-apiv2/common"
	"github.com/hyperledger/fabric-protos-go-apiv2/msp"
	"github.com/hyperledger/fabric-protos-go-apiv2/orderer"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"
	"google.golang.org/protobuf/proto"
)

func main() {
	fmt.Println("🔧 Inicializando Injetor Skeen BFT (4 Nós)...")

	// 1. Conexão TLS com o Servidor 1 (Porta 7050)
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

	conn, err := grpc.Dial("127.0.0.1:7050", grpc.WithTransportCredentials(creds))
	if err != nil { log.Fatalf("Falha conexao: %v", err) }
	defer conn.Close()

	client := orderer.NewAtomicBroadcastClient(conn)
	stream, err := client.Broadcast(context.Background())
	if err != nil { log.Fatalf("Falha stream: %v", err) }

	// === O CRACHÁ DO CLIENTE (Identidade do Admin do Orderer) ===
	certBytes, _ := os.ReadFile("../crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/signcerts/Admin@example.com-cert.pem")
	sId := &msp.SerializedIdentity{
		Mspid:   "OrdererMSP",
		IdBytes: certBytes,
	}
	sIdBytes, _ := proto.Marshal(sId)

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
		TxId:      "SKEEN_BFT_TEST_001",
	}
	chdrBytes, _ := proto.Marshal(chdr)

	payload := &common.Payload{
		Header: &common.Header{
			ChannelHeader:   chdrBytes,
			SignatureHeader: sigHeaderBytes,
		},
		Data: []byte("Disparo de teste na rede Skeen de 4 nos!"),
	}
	payloadBytes, _ := proto.Marshal(payload)



	

	// === A CANETA DIGITAL (Assinatura) ===
	keyDir := "../crypto-config/ordererOrganizations/example.com/users/Admin@example.com/msp/keystore/"
	files, _ := os.ReadDir(keyDir)
	keyBytes, _ := os.ReadFile(keyDir + files[0].Name())

	block, _ := pem.Decode(keyBytes)
	privKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		privKey, _ = x509.ParseECPrivateKey(block.Bytes)
	}
	ecdsaKey := privKey.(*ecdsa.PrivateKey)

	hash := sha256.Sum256(payloadBytes)
	r, s, _ := ecdsa.Sign(rand.Reader, ecdsaKey, hash[:])

	// --- VACINA FABRIC: FORÇAR O LOW-S ---
	// Pega a ordem da curva (N) e divide por 2
	halfOrder := new(big.Int).Div(ecdsaKey.Curve.Params().N, big.NewInt(2))
	
	// Se o S gerado for MAIOR que a metade da curva...
	if s.Cmp(halfOrder) == 1 {
		// S = N - S (Isso espelha o valor pro lado baixo da curva!)
		s.Sub(ecdsaKey.Curve.Params().N, s) 
	}
	// ---------------------------------------

	type ecdsaSignature struct { R, S *big.Int }
	sigBytes, _ := asn1.Marshal(ecdsaSignature{r, s})


	env := &common.Envelope{
		Payload:   payloadBytes,
		Signature: sigBytes,
	}

	fmt.Println("🚀 Disparando transação [SKEEN_BFT_TEST_001]...")
	err = stream.Send(env)
	if err != nil { log.Fatalf("Erro envio: %v", err) }

	reply, err := stream.Recv()
	if err != nil { log.Fatalf("Erro resposta: %v", err) }

	fmt.Printf("✅ Transação aceita! Status do Fabric: %s\n", reply.Status)
}
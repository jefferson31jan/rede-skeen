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
	fmt.Println("🔧 Inicializando Injetor Skeen (Modo Criptográfico Autêntico)...")

	// 1. Conexão TLS com o Servidor
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
	if err != nil {
		log.Fatalf("Falha conexao: %v", err)
	}
	defer conn.Close()

	client := orderer.NewAtomicBroadcastClient(conn)
	stream, err := client.Broadcast(context.Background())
	if err != nil {
		log.Fatalf("Falha stream: %v", err)
	}

	// === O CRACHÁ DO CLIENTE (Identidade do Admin da Org1) ===
	certBytes, _ := os.ReadFile("../crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem")
	sId := &msp.SerializedIdentity{
		Mspid:   "Org1MSP",
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

	// === O CABEÇALHO DO CANAL ===
	chdr := &common.ChannelHeader{
		ChannelId: "canal1",
		Type:      int32(common.HeaderType_ENDORSER_TRANSACTION),
		TxId:      "SKEEN_TX_001_TESE",
	}
	chdrBytes, _ := proto.Marshal(chdr)

	// === O PACOTE DE DADOS ===
	payload := &common.Payload{
		Header: &common.Header{
			ChannelHeader:   chdrBytes,
			SignatureHeader: sigHeaderBytes,
		},
		Data: []byte("Primeira transacao validada enviada ao algoritmo Skeen!"),
	}
	payloadBytes, _ := proto.Marshal(payload)

	// === A CANETA DIGITAL (Assinatura ECDSA) ===
	// Lendo a chave privada (que tem um nome em hash dinâmico gerado pelo cryptogen)
	keyDir := "../crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/"
	files, _ := os.ReadDir(keyDir)
	keyBytes, _ := os.ReadFile(keyDir + files[0].Name())

	block, _ := pem.Decode(keyBytes)
	privKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		// Se falhar, tenta o formato EC puro
		privKey, _ = x509.ParseECPrivateKey(block.Bytes)
	}
	ecdsaKey := privKey.(*ecdsa.PrivateKey)

	// Gera o Hash e Assina
	hash := sha256.Sum256(payloadBytes)
	r, s, _ := ecdsa.Sign(rand.Reader, ecdsaKey, hash[:])

	type ecdsaSignature struct{ R, S *big.Int }
	sigBytes, _ := asn1.Marshal(ecdsaSignature{r, s})

	// === O ENVELOPE FINAL BLINDADO ===
	env := &common.Envelope{
		Payload:   payloadBytes,
		Signature: sigBytes, // Agora sim, o pacote está assinado!
	}

	fmt.Println("🚀 Disparando transação [SKEEN_TX_001_TESE] validada...")
	err = stream.Send(env)
	if err != nil {
		log.Fatalf("Erro envio: %v", err)
	}

	reply, err := stream.Recv()
	if err != nil {
		log.Fatalf("Erro resposta: %v", err)
	}

	fmt.Printf("✅ Transação aceita! Status do Fabric: %s\n", reply.Status)
}

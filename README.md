# Kafka Advanced with mTLS

Lab going through the following:

- Setting up a Kafka cluster with mTLS
- Producing and consuming messages with SSL

## Prerequisites

- kind
- kubectl
- openssl
- keytool
- basic knowledge of kafka & ssl/tls

## Setup

```bash
kind create cluster --config kind-config.yaml ## optional
make cluster

# install strimzi operator
make kafka-operator
```

## TLS steps

```bash
kubectl get secret kafka-cluster-1-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 --decode > ca.crt


## Generate the truststore using the above CA certificate
keytool -import -trustcacerts -alias root -file ca.crt -keystore truststore.jks -storepass password -noprompt

```


## Client side TLS aka mTLS

```bash
kubectl get secret kafka-cluster-1-clients-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 --decode > client-ca.crt

kubectl get secret kafka-cluster-1-clients-ca -o jsonpath='{.data.ca\.key}' | base64 --decode > client-ca.key

# Generate the client keystore (in ssl directory)
keytool -keystore ssl/kafka.client.keystore.jks -alias client -validity 365 -genkey -keyalg RSA -storepass password


## generate the certificate signing request
keytool -keystore ssl/kafka.client.keystore.jks -alias client -storepass password -certreq -file ssl/client-cert-file

## Sign the certificate using the CA certificate
openssl x509 -req -CA client-ca.crt -CAkey client-ca.key -in ssl/client-cert-file -out ssl/client-cert-signed -days 365 -CAcreateserial ## -passin pass:password

## Import the CA certificate into the client keystore
keytool -keystore ssl/kafka.client.keystore.jks -alias CARoot -import -file client-ca.crt -storepass password -noprompt

## Import the signed certificate into the client keystore
keytool -keystore ssl/kafka.client.keystore.jks -alias client -import -file ssl/client-cert-signed -storepass password -noprompt
```

## Test

```bash
kafka-console-producer.sh --broker-list kafka-cluster-1-kafka-bootstrap.kafka.svc.cluster.local:9093 --topic test-topic --producer.config config/client.properties
```

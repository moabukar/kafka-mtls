# Kafka Advanced with mTLS

Lab going through the following:

- Setting up a Kafka cluster with mTLS
- Producing and consuming messages with SSL

## Prerequisites

- [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation)
- [kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- openssl
- [keytool + java](https://www.andrewhoog.com/post/3-ways-to-install-java-on-macos-2023/)
- basic knowledge of kafka & ssl/tls

## Setup

```bash
kind create cluster --config kind-config.yaml ## optional
make cluster

# install strimzi operator
make kafka-operator

make kafka-cluster
```

## TLS steps

```bash
kubectl -n kafka get secret kafka-cluster-1-cluster-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 --decode > ca.crt


## Generate the truststore using the above CA certificate
keytool -import -trustcacerts -alias root -file ca.crt -keystore truststore.jks -storepass password -noprompt

```


## Client side TLS aka mTLS

```bash
kubectl -n kafka get secret kafka-cluster-1-clients-ca-cert -o jsonpath='{.data.ca\.crt}' | base64 --decode > client-ca.crt

kubectl -n kafka get secret kafka-cluster-1-clients-ca -o jsonpath='{.data.ca\.key}' | base64 --decode > client-ca.key

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

## Testing the connection between the client and the kafka cluster (mTLS)

```bash
# To retrieve the bootstrap server details for the Kubernetes Kafka cluster, use the following command and copy the bootstrap server along with port for external listener:

kubectl -n kafka describe kafka kafka-cluster-1

brew install chipmk/tap/docker-mac-net-connect
sudo brew services start chipmk/tap/docker-mac-net-connect

sudo brew services list

## export KAFKA_HEAP_OPTS="-Xmx512M" ## optional for more heap size in case of large messages and high throughput etc


# 172.18.0.2:32622,172.18.0.4:32622
/opt/homebrew/bin/kafka-topics --bootstrap-server 172.18.0.2:32622 --list --command-config config/client.properties

/opt/homebrew/bin/kafka-topics --bootstrap-server 172.18.0.4:32622 --list --command-config config/client.properties

./bin/kafka-topic.sh --bootstrap-server <bootstrap server and port copied in step 1> —-list --command-config config/client.properties

./bin/kafka-topic.sh --bootstrap-server 172.18.0.2:32622 —-list --command-config config/client.properties

# producing to topic
/opt/homebrew/bin/kafka-console-producer --bootstrap-server 172.18.0.2:32622 --topic test --producer.config config/client.properties

# consuming from topic
/opt/homebrew/bin/kafka-console-consumer --bootstrap-server 172.18.0.2:32622 --from-beginning --topic test --consumer.config config/client.properties


```

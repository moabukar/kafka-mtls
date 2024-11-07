KIND_CLUSTER_NAME := kafka-cluster
KIND_CONFIG := kind-config.yaml
STRIMZI_INSTALL_URL := https://strimzi.io/install/latest?namespace=kafka
NAMESPACE := kafka
KUBECONFIG := $(HOME)/.kube/config

.PHONY: cluster kind-delete kafka-operator kafka-cluster topics producer-create consumer-create test setup clean

# Step 1: Create a kind cluster
# Step 1: Create a kind cluster if it doesn't already exist
cluster:
	@echo "Checking if kind cluster exists"
	@if kind get clusters | grep -q $(KIND_CLUSTER_NAME); then \
		echo "Kind cluster $(KIND_CLUSTER_NAME) already exists, skipping creation."; \
	else \
		echo "Creating a kind cluster"; \
		kind create cluster --name $(KIND_CLUSTER_NAME) --config $(KIND_CONFIG); \
	fi


# Step 2: Delete kind cluster
kind-delete:
	@echo "Deleting the kind cluster"
	kind delete cluster --name $(KIND_CLUSTER_NAME)

# Step 3: Install Strimzi Operator and wait for readiness
kafka-operator: cluster
	@echo "Installing Strimzi Operator"
	bash scripts/install_strimzi.sh $(STRIMZI_INSTALL_URL) $(NAMESPACE)

# Step 4: Create Kafka cluster and wait for readiness
# Updated line in Makefile for the kafka-cluster target
kafka-cluster: kafka-operator
	@echo "Creating Kafka cluster"
	kubectl apply -f kafka-cluster.yaml -n $(NAMESPACE)
	bash scripts/wait_for_resource.sh kafka kafka-cluster-1 $(NAMESPACE)


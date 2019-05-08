# KAFKA ON KUBERNETES

## Requirements:

- AKS Cluster with at least two nodes
- At least two brokers to ensure Kafka instance will stay available in case one broker or VM goes down
- Kafka broker accessible via public endpoint
- Schema Registry accessible via public endpoint

### Sign into the provided Azure subscription

- https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest

### Setting up an AKS Cluster

- https://docs.microsoft.com/en-us/azure/aks/

### Helm

- https://docs.microsoft.com/en-us/azure/aks/kubernetes-helm

### Set up Kafka on AKS

- https://medium.com/@tsuyoshiushio/configuring-kafka-on-kubernetes-makes-available-from-an-external-client-with-helm-96e9308ee9f4
- https://github.com/helm/charts/tree/master/incubator/kafka

### Testing out Kafka:

- https://github.com/edenhill/kafkacat

### Schema Registry:

- https://github.com/helm/charts/tree/master/incubator/schema-registry
- Hint: default external port will not work out of the box for PLAINTEXT authentication

### Testing out Schema Registry:

- https://github.com/confluentinc/schema-registry

### Cleaning up Resources

- You can clean up all resources by deleting the group that the AKS Cluster was deployed in.

```bash
    az group delete --name <group-name>
```
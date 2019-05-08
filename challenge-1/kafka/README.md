# KAFKA ON KUBERNETES

## Requirements:

#### For a minimally viable Kafka Cluster, you need the following:
- 2 Kafka brokers
- 1 Zookeeper instance
- Replication Factor of 1

#### Challenge Requirements:
- An AKS Cluster with at least two nodes
- At least two Kafka brokers to ensure high availability
- Kafka broker accessible via public endpoint
- Schema Registry accessible via public endpoint

### Sign into the provided Azure subscription

- https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest

### Setting up an AKS Cluster

Either create a new AKS Cluster, OR use the already deploy AKS Cluster found in the subscription, but create a new namespace.

- https://docs.microsoft.com/en-us/azure/aks/

### Helm

For the challenges, you will be using Helm, which is an open source package manager for Kubernetes used to simplify and manage your Kubernetes applications.

- https://docs.microsoft.com/en-us/azure/aks/kubernetes-helm
- https://helm.sh/

### Set up Kafka on AKS

For this challenge you will be using the public Kafka Helm Chart. You will need to set up a `values.yaml` file to allow external access.

You will be using the `LoadBalancer` external service as NodePort is not supported on AKS. The `LoadBalancers` will all need to use the same port and do not need to be distinct, so you will be using the `firstListenerPort` setting of the chart.

You will need to create static IPs ahead of time to supply to the Helm chart via `external.loadBalancerIP`, as the Kafka broker needs to know the IP Address or DNS name via the `advertised.listeners` setting.

- https://docs.microsoft.com/en-us/azure/aks/static-ip
- https://medium.com/@tsuyoshiushio/configuring-kafka-on-kubernetes-makes-available-from-an-external-client-with-helm-96e9308ee9f4
- https://github.com/helm/charts/tree/master/incubator/kafka

### Testing out Kafka:

- https://github.com/edenhill/kafkacat
- https://github.com/helm/charts/tree/master/incubator/kafka#connecting-to-kafka-from-inside-kubernetes

### Schema Registry:

For this challenge you will be using the public Schema Registry Helm Chart. You will need to set up a `values.yaml` file to allow external access.

You will need to set up Schema Registry to connect to your existing Kafka cluster. Since we are not using TLS authentication, make sure to set the `external.servicePort` setting to something other than 443.

**Note:** Make sure to use a name other than "schema-registry" for the chart.

- https://github.com/helm/charts/tree/master/incubator/schema-registry

### Testing out Schema Registry:

- https://github.com/confluentinc/schema-registry

### Cleaning up Resources

- If you created your own AKS Cluster, delete the resource group the cluster was created in.

```bash
    az group delete --name <group-name>
```

- If you used the already provisioned cluster, delete the namespace the resources are found in.
```
    kubectl delete namespace <namespace-name>
```

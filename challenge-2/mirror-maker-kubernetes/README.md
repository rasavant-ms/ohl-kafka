# MirrorMaker on Kubernetes

**Pre-requisites:**

1. Make sure that event hub namespace has the right event hubs pre-created for this to work.

1. Kubernetes config points to an existing Kubernetes cluster

## Running MirrorMaker

To run MirrorMaker, update the following values in the ```kafka-mm.yaml``` file:

- ```KAFKA_ENDPOINT``` - your Kafka endpoint eg. ```13.77.159.82```
- ```KAFKA_PORT``` - the Kafka port, eg. ```9092```
- ```EH_NAMESPACE``` - your Event Hub namespace, eg. ```eventhubnamespace```
- ```EH_CONNECTIONSTRING``` - your Event Hub Connection string, eg. ```Endpoint=sb://eventhubnamespace.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=s47ewhrf89NNwqRumZyeZS/CbrxuRF/osoWEH5we34yMo=```

Then, apply the deployment:

```bash
kubectl create -f kafka-mm.yaml
```

The yaml file is configured to replicate ALL topics from your Kafka cluster to Event Hub Namespace of your choice
without any additional needed input from the user.

Make relevant changes to the ```kafka-mm.yaml``` for filtering topics. You can refer to the [MirrorMaker documentation](https://docs.confluent.io/current/multi-dc-replicator/mirrormaker.html#ak-mirrormaker) for more information.

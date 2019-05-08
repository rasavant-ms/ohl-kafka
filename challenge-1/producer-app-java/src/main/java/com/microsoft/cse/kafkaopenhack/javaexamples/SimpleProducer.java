package com.microsoft.cse.kafkaopenhack.javaexamples;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerConfig;
import org.apache.kafka.clients.producer.ProducerRecord;
import org.apache.kafka.common.serialization.StringSerializer;
import org.apache.kafka.common.errors.SerializationException;
import java.util.ArrayList;
import java.util.Properties;
import com.google.gson.Gson;

public class SimpleProducer {

    private static final String TOPIC = "schematest";

    @SuppressWarnings("InfiniteLoopStatement")
    public static void main(final String[] args) {

        final Properties props = new Properties();
        props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, "localhost:9092");
        props.put(ProducerConfig.ACKS_CONFIG, "all");
        props.put(ProducerConfig.RETRIES_CONFIG, 0);
        props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
        props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, StringSerializer.class);

        try (KafkaProducer<String, String> producer = new KafkaProducer<>(props)) {
            BadgeService.OpenConnection();
            for (long i = 0; i < 10; i++) {
                ArrayList<EventBadge> badgeEvents = BadgeService.GetBadges();
                Gson gson = new Gson();
                badgeEvents.forEach(b -> {
                    String json = gson.toJson(b);
                    final ProducerRecord<String, String> record = new ProducerRecord<>(TOPIC, b.getId(), json);
                    producer.send(record);
                });
            }
            producer.flush();
            BadgeService.CloseConnection();
            System.out.printf("Successfully produced 10 messages to a topic called %s%n", TOPIC);
        } catch (final SerializationException e) {
            e.printStackTrace();
        }
    }
}
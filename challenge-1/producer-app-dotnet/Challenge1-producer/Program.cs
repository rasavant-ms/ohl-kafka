using System;
using System.Data.SqlClient;
using Dapper;
using System.Threading.Tasks;
using System.Collections.Generic;
using System.Data;
using NLog.Config;
using NLog.Targets;
using NLog;
using System.Configuration;
using Confluent.Kafka;
using System.Threading;
using Newtonsoft.Json.Linq;
using Newtonsoft.Json;

namespace Challenge1_producer
{
    public class BadgeEvent
    {
        public string Id { get; set; }
        public string Name { get; set; }
        public string UserId { get; set; }
        public string DisplayName { get; set; }
        public string Reputation { get; set; }
        public string UpVotes { get; set; }
        public string DownVotes { get; set; }
    }

    public class BadgeProducer
    {
        private readonly string _connectionString;
        private Logger _logger;
        private readonly string BrokerList;
        private readonly string TopicName;
        private CancellationTokenSource _cancellationTokenSource;
        private CancellationToken _cancellationToken;

        private volatile int _sleepTime = 1000; // msec

        public BadgeProducer(string _connectionString, string brokerList, string topic)
        {
            this._connectionString = _connectionString;
            BrokerList = brokerList;
            TopicName = topic;

            this._cancellationTokenSource = new CancellationTokenSource();
            this._cancellationToken = _cancellationTokenSource.Token;

            var config = new LoggingConfiguration();
            var target = new ConsoleTarget("console")
            {
                Layout = "${time} ${level:uppercase=true} ${message}"
            };
            config.AddTarget(target);
            var rule = new LoggingRule("*", LogLevel.Info, target);
            config.LoggingRules.Add(rule);
            LogManager.Configuration = config;

            _logger = LogManager.GetCurrentClassLogger();
        }

        public async Task Run()
        {
            _logger.Info("Testing connection to Azure SQL");
            try
            {
                var conn = new SqlConnection(_connectionString);
                conn.Open();
                conn.Close();
            }
            catch (Exception ex)
            {
                _logger.Error(ex.ToString(), $"Cannot connect to Azure SQL: {ex.Message}");
                return;
            }
            _logger.Info("Successfully connected to Azure SQL");

            var t = new Task(() => SendBadgeEvent(), TaskCreationOptions.LongRunning);
            t.Start();

            Console.ReadKey(true);
            _cancellationTokenSource.Cancel();

            await t;

        }

        private async Task<IEnumerable<BadgeEvent>> GetBadgeEvent()
        {
            _logger.Info($"Getting Badge events from database...");
            
            using (var connection = new SqlConnection(_connectionString))
            {
                var badgeEvent = await connection.QueryAsync<BadgeEvent>(
                    "Challenge1.GetBadge",
                    commandType: CommandType.StoredProcedure);

                _logger.Info($"Got 1 badge event from database.");

                return badgeEvent;
            };
        }

        private async void SendBadgeEvent()
        {
            var config = new ProducerConfig();

            config.BootstrapServers = BrokerList;
            config.MessageTimeoutMs = 1000;

            using (var producer = new ProducerBuilder<string, string>(config).Build())
            {
                while (!_cancellationToken.IsCancellationRequested)
                {
                    var badgeEvent = await GetBadgeEvent();

                    foreach (var b in badgeEvent)
                    {
                        var p = JsonConvert.SerializeObject(b);
                        try
                        {
                            var deliveryReport = await producer.ProduceAsync(TopicName, new Message<string, string> { Value = p.ToString() });

                            _logger.Info($"delivered to: {deliveryReport.TopicPartitionOffset}");
                        }
                        catch (ProduceException<string, string> exception)
                        {
                            _logger.Error(exception, $"failed to deliver message: {exception.Message} [{exception.Error.Code}]");
                            break;
                        }
                        catch (Exception exception)
                        {
                            _logger.Error(exception, $"failed to deliver message: {exception.Message}");
                            break;
                        }
                    }

                    await Task.Delay(_sleepTime);

                    if (_cancellationToken.IsCancellationRequested)
                    {
                        break;
                    }
                }
            }
        }
    }

    public class SendEvent
    {
        private readonly string _brokerList;
        private readonly string _topic;

        public SendEvent(string brokerList, string topic)
        {
            _brokerList = brokerList;
            _topic = topic;
        }
    }

    public class Program
    {
        static async Task Main(string[] args)
        {
            try 
            { 
                SqlConnectionStringBuilder builder = new SqlConnectionStringBuilder();
                builder.DataSource = ConfigurationManager.AppSettings["AZURE_SQL"];
                builder.UserID = ConfigurationManager.AppSettings["AZURE_SQL_USERNAME"];
                builder.Password = ConfigurationManager.AppSettings["AZURE_SQL_PASSWORD"];
                builder.InitialCatalog = ConfigurationManager.AppSettings["AZURE_SQL_DATABASE"];
                builder.MultipleActiveResultSets = false;
                builder.Encrypt = true;
                builder.TrustServerCertificate = false;
                builder.ConnectTimeout = 30;
                builder.PersistSecurityInfo = false;
                string connectionString = builder.ConnectionString;

                string brokerList = ConfigurationManager.AppSettings["KAFKA_BROKERS"];
                string topic = ConfigurationManager.AppSettings["KAFKA_TOPIC"];

                BadgeProducer b = new BadgeProducer(connectionString, brokerList, topic);
                await b.Run();

            }
            catch (SqlException e)
            {
                Console.WriteLine(e.ToString());
            } 
        }
    }
}

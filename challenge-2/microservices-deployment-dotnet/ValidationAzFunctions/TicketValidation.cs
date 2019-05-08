using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Azure.EventHubs;
using Microsoft.Azure.WebJobs;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace ValidationAzFunctions
{
    public static class TicketValidation
    {
        [FunctionName("TicketValidation")]
        public static void Run(
            [EventHubTrigger("ticket_request", Connection = "EventHubConnectionAppSetting", ConsumerGroup = "%TicketConsumerGroup%")] EventData[] events,
            ILogger log)
        {
            var exceptions = new List<Exception>();
            Random timeRandom = new Random();

            foreach (EventData eventData in events)
            {
                try
                {
                    string messageBody = Encoding.UTF8.GetString(eventData.Body.Array, eventData.Body.Offset, eventData.Body.Count);

                    // Replace these two lines with your processing logic.
                    log.LogInformation($"C# TicketValidation function processed a message: {messageBody}");

                    // Processing Ticket Validation Requirements

                    // Simulating call to 3rd party services by putting a random wait                    
                    Thread.Sleep(timeRandom.Next(10, 2000));

                    // This is currently returning the values 0 or 1 randomly
                    // and enriching message with added data fields
                    var msgObj = JObject.Parse(messageBody);
                    Random rand = new Random();
                    if (rand.Next(0, 2) == 0)
                        msgObj["ticketAvailable"] = 0;
                    else
                        msgObj["ticketAvailable"] = 1;

                    msgObj["timeProcessed"] = DateTime.UtcNow;

                    // Add code based on Architecure decision
                }
                catch (Exception e)
                {
                    // We need to keep processing the rest of the batch - capture this exception and continue.
                    // Also, consider capturing details of the message that failed processing so it can be processed again later.
                    exceptions.Add(e);
                }
            }

            // Once processing of the batch is complete, if any messages in the batch failed processing throw an exception so that there is a record of the failure.

            if (exceptions.Count > 1)
            {
                throw new AggregateException(exceptions);
            }


            if (exceptions.Count == 1)
                throw exceptions.Single();
        }
    }
}

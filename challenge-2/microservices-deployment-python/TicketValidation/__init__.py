import logging
from random import randint
from time import sleep
from datetime import datetime
import json

import azure.functions as func


def main(event: func.EventHubEvent):
    try:

        logging.info('TicketValidation function processed an event: %s',
                    event.get_body().decode('utf-8'))

        # Processing Ticket Validation Requirements

        # Simulating call to 3rd party services by putting a random wait
        sleep(randint(1, 10))

        msgObjList = json.loads(event.get_body().decode('utf-8'))
        msgObj=msgObjList[0]
        rand = randint(0, 2)

        # This is currently returning the values 0 or 1 randomly
        # and enriching message with added data fields
        if(rand == 0):
            msgObj["ticketAvailable"] = 0
        else:
            msgObj["ticketAvailable"] = 1

        msgObj["timeProcessed"] =  datetime.utcnow()

        # Add code based on Architecure decision

    except Exception as e:
        logging.error(e)

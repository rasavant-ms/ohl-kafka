#!/bin/bash
set -euo pipefail

# -e: immediately exit if any command has a non-zero exit status
# -o: prevents errors in a pipeline from being masked
# IFS new value is less likely to cause confusing bugs when looping arrays or arguments (e.g. $@)

# "Debug" mode
#set -x

usage() { echo "Usage: $0 -l <location> [-u <uniquifier>]" 1>&2; exit 1; }

# Initialize parameters specified from command line
declare resourceGroupLocation=""
declare uniquifier=""

while getopts ":l:u:" arg; do
	case "${arg}" in
		l)
			resourceGroupLocation=${OPTARG}
			;;
		u)
			uniquifier=${OPTARG}
			;;
	esac
done
shift $((OPTIND-1))

if [[ -z "$resourceGroupLocation" ]]; then
	echo "Must provide resource group location"
	usage
fi

echo "Checking Prerequisites"

if ! command az >/dev/null; then
    echo "Must install Azure CLI: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli" >&2
    exit 1
fi

export curVer=`printf "%03d%03d%03d" $(az --version | grep 'azure-cli ' | awk '{gsub(/[()]/, "", $2); print $2}' | tail -1 | tr '.' ' ')`
export reqVer=`printf "%03d%03d%03d" $(echo '2.0.50' | tr '.' ' ')`
if [ ${curVer} -lt ${reqVer} ] ; then
    echo "Version 2.0.50 at least required for eventhubs with kafka" >&2    
    echo 'You can add it by following instructions given here' >&2
    echo 'https://docs.microsoft.com/en-us/cli/azure/install-azure-cli' >&2
    exit 1
fi

IFS=$'\n\t'

# create uniquifier string
declare PREFIX=$uniquifier
if [ -z "$PREFIX" ]; then
  PREFIX=`openssl rand 128 -base64 | tr -cd '[:digit:]' | cut -c 1-7`
	PREFIX="eh"$PREFIX
fi

# Get full path to script 
CUR=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

rm -f azcli-execution.log

export LOCATION=$resourceGroupLocation
export RG="${PREFIX}rg"

echo "create: group ${RG}"
az group create --name "${RG}" --location "${LOCATION}" -o json >> azcli-execution.log

echo "create: storage account ${PREFIX}storage"
az storage account create --name "${PREFIX}storage" --kind "StorageV2" --location "${LOCATION}" --resource-group "${RG}" --sku "Standard_LRS" -o json >> azcli-execution.log

echo "show: storage account ${PREFIX}storage"
export SID=$(az storage account show --name "${PREFIX}storage" --query "id" --resource-group "${RG}" -o tsv)

echo "show: storage account ${PREFIX}storage connection string"
export STORAGE_CONNECTION_STRING=$(az storage account show-connection-string --resource-group "${RG}" --name "${PREFIX}storage" -o tsv)

echo "create: eventhubs namespace ${PREFIX}ehubns"
az eventhubs namespace create --name "${PREFIX}ehubns" --resource-group "${RG}" \
--sku Standard --location "${LOCATION}" --capacity 8 --enable-kafka True \
-o json >> azcli-execution.log

echo "create: eventhub payment instance"
az eventhubs eventhub create --name "payment" --resource-group "${RG}" \
--message-retention 1 --partition-count 4 --namespace-name "${PREFIX}ehubns" \
-o json >> azcli-execution.log

echo "show event hub name payment"
export EVENTHUB_NAME="payment"

echo "create: eventhub ticket_request instance"
az eventhubs eventhub create --name "ticket_request" --resource-group "${RG}" \
--message-retention 1 --partition-count 4 --namespace-name "${PREFIX}ehubns" \
-o json >> azcli-execution.log

echo "show event hub name ticket_request"
export EVENTHUB_NAME="ticket_request"

echo "show: event hub connection string"
export EVENTHUB_CS=$(az eventhubs namespace authorization-rule keys list --resource-group "${RG}" --namespace-name ${PREFIX}ehubns --name RootManageSharedAccessKey --query "primaryConnectionString" -o tsv)

echo "create: consumer group for payment event hub"
az eventhubs eventhub consumer-group create --name "${PREFIX}ehub2cg" --resource-group "${RG}" \
--eventhub-name "payment" --namespace-name "${PREFIX}ehubns" \
-o json >> azcli-execution.log

echo "create: consumer group for ticket_request event hub"
az eventhubs eventhub consumer-group create --name "${PREFIX}ehub1cg" --resource-group "${RG}" \
--eventhub-name "ticket_request" --namespace-name "${PREFIX}ehubns" \
-o json >> azcli-execution.log

echo "create: resource ${PREFIX}functionappinsights"
az resource create --name "${PREFIX}functionappinsights" --location "${LOCATION}" --properties '{"Application_Type": "other", "ApplicationId": "function", "Flow_Type": "Redfield"}' --resource-group "${RG}" --resource-type "Microsoft.Insights/components" -o json >> azcli-execution.log

echo "show: resource ${PREFIX}functionappinsights"
export APPINSIGHTS_KEY=$(az resource show --name "${PREFIX}functionappinsights" --query "properties.InstrumentationKey" --resource-group "${RG}" --resource-type "Microsoft.Insights/components" -o tsv)

echo "create: appservice plan ${PREFIX}plan"
az appservice plan create --name "${PREFIX}plan" --number-of-workers "1" --resource-group "${RG}" --sku "S1" -o json >> azcli-execution.log

echo "create: functionapp ${PREFIX}functionapp"
az functionapp create --name "${PREFIX}functionapp" --plan "${PREFIX}plan" --resource-group "${RG}" --storage-account "${PREFIX}storage" -o json >> azcli-execution.log

echo "config-zip: functionapp deployment source ${PREFIX}functionapp"
az functionapp deployment source config-zip --name "${PREFIX}functionapp" --resource-group "${RG}" --src "./ValidationAzFunctions.zip" -o json >> azcli-execution.log

echo "set: functionapp config appsettings for appinsights"
az functionapp config appsettings set --name "${PREFIX}functionapp" --resource-group "${RG}" --settings "APPINSIGHTS_INSTRUMENTATIONKEY=$APPINSIGHTS_KEY" -o json >> azcli-execution.log

echo "set: functionapp config appsettings for storage account connection string"
az functionapp config appsettings set --name "${PREFIX}functionapp" --resource-group "${RG}" --settings "STORAGE_CONNECTION_STRING=$STORAGE_CONNECTION_STRING" -o json >> azcli-execution.log

echo "set: functionapp config appsettings for event hub connection string"
az functionapp config appsettings set --name "${PREFIX}functionapp" --resource-group "${RG}" --settings "EventHubConnectionAppSetting=$EVENTHUB_CS" -o json >> azcli-execution.log

echo "set: functionapp config appsettings for event hub 1 consumer group"
az functionapp config appsettings set --name "${PREFIX}functionapp" --resource-group "${RG}" --settings "TicketConsumerGroup=${PREFIX}ehub1cg" -o json >> azcli-execution.log

echo "set: functionapp config appsettings for event hub 2 consumer group"
az functionapp config appsettings set --name "${PREFIX}functionapp" --resource-group "${RG}" --settings "PaymentConsumerGroup=${PREFIX}ehub2cg" -o json >> azcli-execution.log

echo "done"
#!/bin/bash
set -e -x

COSMOSDB_ACCOUNT_NAME="azfuncv2db"
RESOURCE_GROUP="RG-azfuncv2"
DATABASE_NAME="testdb"
CREATE_LEASE_COLLECTION=1         # yes,no=(1,0)
LEAVES_COLLECTION_NAME="leases"

az cosmosdb create \
    --name $COSMOSDB_ACCOUNT_NAME \
    --kind GlobalDocumentDB \
    --resource-group $RESOURCE_GROUP
# Get Key
COSMOSDB_KEY=$(az cosmosdb list-keys --name $COSMOSDB_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --output tsv |awk '{print $1}')

# Create Database
az cosmosdb database create \
    --name $COSMOSDB_ACCOUNT_NAME \
    --db-name $DATABASE_NAME \
    --key $COSMOSDB_KEY \
    --resource-group $RESOURCE_GROUP

# Create a container with a partition key and provision 400 RU/s throughput.
COLLECTION_NAME="testcol01"
az cosmosdb collection create \
    --resource-group $RESOURCE_GROUP \
    --collection-name $COLLECTION_NAME \
    --name $COSMOSDB_ACCOUNT_NAME \
    --db-name $DATABASE_NAME \
    --partition-key-path /name \
    --throughput 400

COLLECTION_NAME="testcol02"
az cosmosdb collection create \
    --resource-group $RESOURCE_GROUP \
    --collection-name $COLLECTION_NAME \
    --name $COSMOSDB_ACCOUNT_NAME \
    --db-name $DATABASE_NAME \
    --partition-key-path /name \
    --throughput 400

# Create a container for leaves
# 'leaves' need to be a single collection partition
# Please see also: https://github.com/Azure/azure-functions-core-tools/issues/930
if [ $CREATE_LEASE_COLLECTION -gt 0 ]
then
  az cosmosdb collection create \
    --resource-group $RESOURCE_GROUP \
    --collection-name $LEAVES_COLLECTION_NAME \
    --name $COSMOSDB_ACCOUNT_NAME \
    --db-name $DATABASE_NAME \
    --throughput 400
fi

#!/bin/bash

#variables
RESOURCE_GROUP="NetRG2"
LOCATION="eastus"
VNET_NAME="MyVnet2"
SUBNET_NAME="MySubnet2"
ADDRESS_PREFIX="192.168.0.0/16"
SUBNET_PREFIX="192.168.10.0/24"

#create resource group
az group create \
    --name $RESOURCE_GROUP \
    --location $LOCATION 

#create a virtual network
az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --name $VNET_NAME \
    --address-prefix $ADDRESS_PREFIX \
    --subnet-name $SUBNET_NAME \
    --subnet-prefix $SUBNET_PREFIX 

#optional
#create a network security group

NSG_NAME="MyNSG2"
az network nsg create \
    --resource-group $RESOURCE_GROUP \
    --name $NSG_NAME

#link NSG to subnet (optional)

az network vnet subnet update \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --name $SUBNET_NAME \
    --network-security-group $NSG_NAME
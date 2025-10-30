#!/bin/bash
#Version: 3.1 
#Name: CLI Deployment in "Cloud Shell"

#variables

#resourceGroup,location, Virtual Network, WebSubnet/AppSubnet, WebIP/AppIP, admin_user

RESOURCE_GROUP="NetRG3.1"
LOCATION="eastus"
VNET_NAME="MyVnet3.1"
WEB_SUBNET="WebSubnet3.1"
APP_SUBNET="AppSubnet3.1"
WEB_IP="10.0.1.4"
APP_IP="10.0.2.4"
ADMIN_USER="azureuser"

#Prompt for password securely

read -s -p "Enter admin password: " ADMIN_PASS
echo
#------------------------------------------------------------------

#CREATE RESORUCE GROUP
az group create --name $RESOURCE_GROUP --location $LOCATION
#resource group is created

#------------------------------------------------------------------
#Create Virtual Network and Subnets

az network vnet create \
    --resource-group $RESOURCE_GROUP
    
    --name $VNET_NAME \
    --address-prefix 10.0.0.0/16 \

    --subnet-name $WEB_SUBNET \
    --subnet-prefix 10.0.1.0/24

#Create subnets web and app subnet
az network vnet subnet create \
    --resource-group $RESOURCE_GROUP \

    --vnet-name $VNET_NAME \

    --name $APP_SUBNET \
    --address-prefix 10.0.2.0/24 
#App subnet is created now

#---------------------------------------------------------------

#Create WebNSG
az network nsg create \
    --resource-group $RESOURCE_GROUP \
    
    --name WebNSG

#--------------------------------------------------------------------

#Create rules for NSG
az network nsg rule create \
    --resource-group $RESOURCE_GROUP

    --nsg_name WebNSG \

    --name AllowSSH --priority 100 --access Allow \
    --protocol tcp --direction Inbound \
    --source-address-prefix '*' \
    --source-port-range '*' \ 
    --destination-address-prefix $WEB_IP \
    --destination-port-range 22 \

az network nsg rule create \
    --resource-group $RESOURCE_GROUP \

    --nsg_name WebNSG \

    --name AllowHTTP --priority 110 --access Allow \
    --protocol tcp --direction Inbound  \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix $WEB_IP \
    --destination-port-range 80

az network nsg rule create \
    --resource-group $RESOURCE_GROUP \

    --nsg_name WebNSG \

    --name AllowHTTPS --priority 120 --access Allow \
    --protocol tcp --direction Inbound \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix $WEB_IP \
    --destination-port-range 443



#====================================================================================


#Create AppNSG
az network nsg create \
    --resource-group $RG_NAME \
    --name AppNSG


#===================================================================================
#Create Rules for AppNSG
az network nsg rule create \
    --resource-group $RESOURCE_GROUP \

    --nsg_name AppNSG \
    --name AllowSSH --priority 100 --access Allow \
    --protocol tcp --direction Inbound \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix $APP_IP \
    --destination-port-range 22 

az network nsg rule create \
    --resource-group $RESOURCE_GROUP

    --nsg_name AppNSG \

    --name AllowWebSUbnet --priority 200 --access Allow \
    --protocol tcp --direction Inbound \
    --source-address-prefix '10.0.1.0/24' \
    --source-port-range '*'
    --destination-address-prefix $APP_IP 
    --destination-port-range '*'

az network nsg rule create \
    --resource-group $RESOURCE_GROUP

    --nsg_name AppNSG \
    --name DenyInternetIn --priority 300 --access Deny
    --protocol '*' --direction Inbound 
    --source-address-prefix '10.0.1.0/24'
    --source-port-range '*'
    --destination-address-prefix $APP_IP 
    --destination-port-range '*'

#-==================================================================

#Associate NSGs with subnets (Update)
az network vnet subnet update \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \


    --name $WEB_SUBNET \
    --network-security-group WebNSG

az network vnet subnet update \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \


    -name $APP_SUBNET \
    -network-security-group AppNSG 

#-==================================================================

#Create Public IP and NAT gateway
az network public-ip create \
    --resource-group $RESOURCE_GROUP\

    --name MyNatPublicIP3.1 \
    --sku Standard \
    --allocation-method Static

#-==================================================================

#Create NAT gateway
az network nat gateway create \
    --resource-group $RESOURCE_GROUP \

    --name MyNAT3.1 \
    --location $LOCATION \
    --public-ip-address MyNatPublicIP3.1 \
    --sku Standard

az network vnet subnet update \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    
    --name $WEB_SUBNET \
    --nat-gateway MyNAT3.1

az network vnet subnet update \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \

    --name $APP_SUBNET \
    --nat-gateway MyNAT3.1

#===============================================================

#Create VMs with Statis Private IPs
#Create Web VM
az network nic create \
    --resource-group $RESOURCE_GROUP \

    --name WebVMNic \
    --vnet-name $VNET_NAME \
    --subnet $WEB_SUBNET \
    --private-ip-address $WEB_IP 

az vm create \
    --resource-group $RESOURCE_GROUP \

    --name WebVM \
    --nics WebVMNic \
    --image UbuntuLTS \
    --size Standard_B1ms \
    --admin-username $ADMIN_USER \
    --admin-password $ADMIN_PASS

#===============================================================

#Create app VM
az network nic create \
    --resource-group $RESOURCE_GROUP \

    --name AppVMNic \
    --vnet-name $VNET_NAME \
    --subnet $APP_SUBNET \
    --private-ip-address $APP_IP

az vm create \
    -resource-group $RESOURCE_GROUP \

    --name AppVM \
    --nics AppVMNic \
    --image UbuntuLTS \
    --size Standard_B1ms \
    --admin-username $ADMIN_USER \
    --admin-password $ADMIN_PASS

#===============================================================

#Create Log Analytics Workspace
az monitor log-analytics workspace create \
    --resource-group $RESOURCE_GROUP \

    --workspace-name MyLogWorkspace3.1 \
    --location $LOCATION

#===============================================================

#Enable Monitoring on VMS

az monitor diagnostic-setting create \
    --name EnableInsights \
    --resource /suscriptions/<your-sub-id>/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Compute/virtualMachines/WebVM \
    --workspace MyLogWorkspace \
    --metrics '[{"category": "AllMetrics", " enabled": true}]' \
    --logs '[{"category": "PerformanceCounters", "enabled": true}, {"category":"GuestOS","enabled": true}, {"category":"Heartbeat", "enabled": true}]

az monitor diagnostic-settings create \
    --name EnableInsights \
    --resource /subscriptions/<your-sub-id>/resourceGroups/$RG_NAME/providers/Microsoft.Compute/virtualMachines/AppVM \
    --workspace MyLogWorkspace \
    --metrics '[{"category": "AllMetrics", "enabled": true}]' \
    --logs '[{"category": "PerformanceCounters", "enabled": true}, {"category":"GuestOS","enabled": true}, {"category":"Heartbeat", "enabled": true}]




    








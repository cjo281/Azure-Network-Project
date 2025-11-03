/* #Version: 3.2 
#Name: CLI Deployment in "Bicep File"*/
/*test*/
param location string = 'eastus'
param resourceName string = 'NetRG3.2'
param adminUsername string = 'azureuser3.2'
@secure()
param adminPassword string

var vnetName = 'MyVnet3.2'
var webSubnetName = 'WebSubnet3.2'
var appSubnetName = 'AppSubnet3.2'
var webNSGName = 'WebNSG3.2'
var appNSGName = 'AppNSG3.2'
var webVMName = 'WebVM3.2'
var appVMName = 'AppVM3.2'
var webIP = '10.0.1.4'
var appIP = '10.0.2.4'
var natPublicIPName = 'MyNATPublicIP3.2'
var natGatewayName = 'MyNAT3.2'
var workspaceName = 'MyLogWorkspace3.2'

/*======================================================================================*/

/*Create Virtual Network, and Subnets: WebSubnetName and AppSubnet Name */

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {      /*API latest version for Virtual Network*/
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: webSubnetName
        properties: {
          addressPrefix: '10.0.1.0/24'
          networkSecurityGroup: {
            id: webNSG.id
          }
          natGateway: {
            id: natGateway.id
          }
        }
      }
      {
        name: appSubnetName
        properties: {
          addressPrefix: '10.0.2.0/24'
          networkSecurityGroup: {
            id: appNSG.id
          }
          natGateway: {
            id: natGateway.id
          }
        }
      }
    ]
  }
}

/*======================================================================================*/

/*Create NSG for WebSubnet And AppSubnet --> webNSG and appNSG */
/*Create webNSG */

resource webNSG 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {    /*API latest version for Virtual Network*/
  name: webNSGName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: webIP
          destinationPortRange: '22'
        }
      }
      {
        name: 'AllowHTTP'
        properties: {
          priority: 110
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: webIP
          destinationPortRange: '80'
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 120
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: webIP
          destinationPortRange: '443'
        }
      }
    ]
  }
}

/*======================================================================================*/
/*Create NSG for WebSubnet And AppSubnet --> webNSG and appNSG */
/*Create appNSG */

resource appNSG 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: appNSGName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: appIP
          destinationPortRange: '22'
        }
      }
      {
        name: 'AllowWebSubnet'
        properties: {
          priority: 200
          access: 'Allow'
          direction: 'Inbound'
          protocol: '*'
          sourceAddressPrefix: '10.0.1.0/24'
          sourcePortRange: '*'
          destinationAddressPrefix: appIP
          destinationPortRange: '*'
        }
      }
      {
        name: 'DenyInternetIn'
        properties: {
          priority: 300
          access: 'Deny'
          direction: 'Inbound'
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: appIP
          destinationPortRange: '*'
        }
      }
    ]
  }
}

/*======================================================================================*/
/*Create "Public IP" for the NAT gateway*/
/*2023-04-01 is the most updated ip according to the official website*/
resource natPublicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: natPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

/*======================================================================================*/
/*Create NAT gateway so you can update it with the IP public you just created in the previous step*/

resource natGateway 'Microsoft.Network/natGateways@2023-04-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: natPublicIP.id
      }
    ]
  }
}

/*======================================================================================*/
/*Create NICs for the Virtual Machines*/
/*Create NIC for webVM */

resource webNic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${webVMName}Nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: webIP
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: vnet.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

/*======================================================================================*/

/*Create NIC for appVM */
resource appNic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: '${appVMName}Nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: appIP
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: vnet.properties.subnets[1].id
          }
        }
      }
    ]
  }
}

/*======================================================================================*/

/*Create Vortual Machines for appVM and webVM */
/*Create webVM */

resource webVM 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: webVMName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1ms'
    }
    osProfile: {
      computerName: webVMName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: webNic.id
        }
      ]
    }
  }
}

/*======================================================================================*/
/*Create appVM */

resource appVM 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: appVMName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1ms'
    }
    osProfile: {
      computerName: appVMName
      adminUsername: adminUsername
      adminPassword: adminPassword


    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: appNic.id
        }
      ]
    }
  }
}

/*======================================================================================*/
/*Enable Monitoring on VMs */
resource logWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

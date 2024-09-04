resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'sandbox-dev'
  location: 'East US'
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
        '192.168.0.0/24'
      ]
    }
    subnets: [
      {
        name: 'app-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
    enableDdosProtection: false // Optional, new property to enable DDoS protection
    enableVmProtection: false // Optional, can enable VM protection on the VNet
    // dhcpOptions section removed to use Azure default DNS
  }
}

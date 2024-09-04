@description('Name of the Key Vault')
param keyVaultName string = 'kv-sandbox-dev94794kab'

@description('Location for the Key Vault')
param location string = resourceGroup().location

@description('Tenant ID of the Azure Active Directory')
param tenantId string

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    accessPolicies: []
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
  }
}

output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri

@description('Name of the Managed Environment')
param managedEnvironmentName string = 'myManagedEnvironment'

@description('Name of the Container App')
param containerAppName string = 'myContainerApp'

@description('Location for the resources')
param location string = resourceGroup().location

// Create the Managed Environment for Azure Container Apps
resource managedEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: managedEnvironmentName
  location: location
}

// Create the Azure Container Registry (ACR)
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'mycontainerregistry${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

// Create the User-Assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'myContainerAppIdentity'
  location: location
}

// Assign AcrPull role to the Managed Identity
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acr.id, managedIdentity.id, 'AcrPull')
  scope: acr
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Create the Azure Container App
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}  // Use the Managed Identity for the Container App
    }
  }
  properties: {
    managedEnvironmentId: managedEnvironment.id  // Reference the Managed Environment
    configuration: {
      ingress: {
        external: true  // Publicly accessible
        targetPort: 80
      }
      registries: [
        {
          server: acr.properties.loginServer  // ACR login server
          identity: managedIdentity.id  // Use Managed Identity for ACR authentication
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'myContainer'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
    }
  }
  dependsOn: [
    acrPullRoleAssignment
  ]
}

// Outputs for debugging or further use
output managedEnvironmentName string = managedEnvironment.name
output containerAppUrl string = containerApp.properties.configuration.ingress.fqdn
output acrLoginServer string = acr.properties.loginServer
output managedIdentityName string = managedIdentity.name

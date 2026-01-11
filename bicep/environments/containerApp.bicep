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

// Create the User-Assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'myContainerAppIdentity'
  location: location
}

// Create the Azure Container App
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: managedEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
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
}

// Outputs for debugging or further use
output managedEnvironmentName string = managedEnvironment.name
output containerAppUrl string = containerApp.properties.configuration.ingress.fqdn
output acrLoginServer string = acr.properties.loginServer
output managedIdentityName string = managedIdentity.name

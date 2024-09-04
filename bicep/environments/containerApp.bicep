@description('Name of the Managed Environment')
param managedEnvironmentName string = 'myManagedEnvironment'

@description('Name of the Container App')
param containerAppName string = 'myContainerApp'

@description('Location for the resources')
param location string = resourceGroup().location

// Create the Managed Environment for Azure Container Apps
resource managedEnvironment 'Microsoft.App/managedEnvironments@2023-03-01' = {
  name: managedEnvironmentName
  location: location
}

// Create the Azure Container Registry (ACR)
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01' = {
  name: 'myContainerRegistry'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false  // Admin user disabled; using Managed Identity instead
  }
}

// Create the User-Assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31' = {
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
          image: '${acr.properties.loginServer}/myapp:latest'  // Reference the container image from ACR
          resources: {
            cpu: json('0.5')
            memory: '250Mb'
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

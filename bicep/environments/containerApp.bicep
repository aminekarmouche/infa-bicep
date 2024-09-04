// Parameters for the deployment
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
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: '<your-log-analytics-workspace-id>'  // You need to provide the Log Analytics workspace ID
        sharedKey: '<your-log-analytics-workspace-key>'  // You need to provide the shared key
      }
    }
  }
}

// Create the Azure Container Registry (ACR)
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01' = {
  name: 'myContainerRegistry'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

// Create the Azure Container App
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppName
  location: location
  properties: {
    managedEnvironmentId: managedEnvironment.id  // Use the symbolic reference to the managed environment
    configuration: {
      ingress: {
        external: true
        targetPort: 80
      }
      registries: [
        {
          server: acr.properties.loginServer
          username: acr.listCredentials().username
          password: acr.listCredentials().passwords[0].value
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'mySandboxContainer'
          image: '${acr.properties.loginServer}/mysandboxapp:latest'
        }
      ]
    }
  }
}

output managedEnvironmentName string = managedEnvironment.name
output containerAppUrl string = containerApp.properties.configuration.ingress.fqdn

// Define the Azure Container Registry
resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: 'myContainerRegistry'
  location: 'East US'
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true  // Move adminUserEnabled under properties
  }
}

// Define the Azure Container App
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: 'myContainerApp'
  location: 'East US'
  properties: {
    managedEnvironmentId: '/subscriptions/{subscription-id}/resourceGroups/{resource-group}/providers/Microsoft.App/managedEnvironments/{environment-name}'
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
          name: 'sandboxAppContainer'
          image: '${acr.properties.loginServer}/mysandboxapp:latest'
        }
      ]
    }
  }
}

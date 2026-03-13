// Azure Container Registry und Container Apps für Dependency-Track
targetScope = 'resourceGroup'

@description('Location für alle Ressourcen')
param location string = resourceGroup().location

@description('Name der Container Registry (optional)')
param containerRegistryName string

@description('Name der Container Apps Environment')
param environmentName string = 'dependencytrack-env'

@description('Name der API Server Container App')
param apiServerAppName string = 'dependencytrack-apiserver'

@description('Name der Frontend Container App')
param frontendAppName string = 'dependencytrack-frontend'

@description('API Server Container Image')
param apiServerImage string = 'dependencytrack/apiserver:latest'

@description('Frontend Container Image')
param frontendImage string = 'dependencytrack/frontend:latest'

@description('Storage Account Name für persistente Daten')
param storageAccountName string

@description('Tags für alle Ressourcen')
param tags object = {
  environment: 'production'
  project: 'dependency-track'
}

// Storage Account für persistente Daten
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// File Share für Dependency-Track Daten
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: '${storageAccount.name}/default/dependencytrackdata'
  properties: {
    shareQuota: 50
    enabledProtocols: 'SMB'
  }
}

// Container Registry (optional - für Mirror der Docker Hub Images)
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = if (!empty(containerRegistryName)) {
  name: containerRegistryName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
    publicNetworkAccess: 'Enabled'
  }
}

// Log Analytics Workspace für Container Apps
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${environmentName}-logs'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

// Container Apps Environment mit Storage Mount
resource environment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: environmentName
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// Storage für Environment
resource environmentStorage 'Microsoft.App/managedEnvironments/storages@2024-03-01' = {
  name: 'dependencytrackdata'
  parent: environment
  properties: {
    azureFile: {
      accountName: storageAccount.name
      accountKey: storageAccount.listKeys().keys[0].value
      shareName: 'dependencytrackdata'
      accessMode: 'ReadWrite'
    }
  }
  dependsOn: [
    fileShare
  ]
}

// API Server Container App
resource apiServerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: apiServerAppName
  location: location
  tags: tags
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
        allowInsecure: false
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
        }
      }
    }
    template: {
      containers: [
        {
          name: 'apiserver'
          image: apiServerImage
          resources: {
            cpu: json('2.0')
            memory: '4Gi'
          }
          env: [
            {
              name: 'SYSTEM_REQUIREMENT_CHECK_ENABLED'
              value: 'true'
            }
            {
              name: 'LOGGING_LEVEL'
              value: 'INFO'
            }
            {
              name: 'ALPINE_CORS_ENABLED'
              value: 'true'
            }
            {
              name: 'ALPINE_CORS_ALLOW_ORIGIN'
              value: '*'
            }
          ]
          volumeMounts: [
            {
              volumeName: 'data'
              mountPath: '/data'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 2
      }
      volumes: [
        {
          name: 'data'
          storageType: 'AzureFile'
          storageName: 'dependencytrackdata'
        }
      ]
    }
  }
  dependsOn: [
    environmentStorage
  ]
}

// Frontend Container App
resource frontendApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: frontendAppName
  location: location
  tags: tags
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
        transport: 'auto'
        allowInsecure: false
      }
    }
    template: {
      containers: [
        {
          name: 'frontend'
          image: frontendImage
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'API_BASE_URL'
              value: 'https://${apiServerApp.properties.configuration.ingress.fqdn}'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '20'
              }
            }
          }
        ]
      }
    }
  }
}

// Outputs
output storageAccountName string = storageAccount.name
output containerRegistryName string = !empty(containerRegistryName) ? containerRegistry.name : ''
output containerRegistryLoginServer string = !empty(containerRegistryName) ? containerRegistry.properties.loginServer : ''
output apiServerUrl string = 'https://${apiServerApp.properties.configuration.ingress.fqdn}'
output frontendUrl string = 'https://${frontendApp.properties.configuration.ingress.fqdn}'
output environmentId string = environment.id

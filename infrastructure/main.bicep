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

@description('Name des PostgreSQL Flexible Servers')
param postgresServerName string

@description('Name der PostgreSQL Datenbank')
param postgresDatabaseName string = 'dtrack'

@description('PostgreSQL Administrator Benutzername')
param postgresAdminUser string = 'dtrackadmin'

@description('PostgreSQL Administrator Passwort')
@secure()
param postgresAdminPassword string

@description('Location für PostgreSQL (muss PostgreSQL Flexible Server unterstützen)')
param postgresLocation string = 'northeurope'

@description('Entra ID Application (Client) ID für OIDC')
param oidcClientId string

@description('Entra ID Directory (Tenant) ID für OIDC')
param oidcTenantId string

@description('Tags für alle Ressourcen')
param tags object = {
  environment: 'production'
  project: 'dependency-track'
}

// PostgreSQL Flexible Server
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2023-06-01-preview' = {
  name: postgresServerName
  location: postgresLocation
  tags: tags
  sku: {
    name: 'Standard_B2s'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: postgresAdminUser
    administratorLoginPassword: postgresAdminPassword
    version: '16'
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Disabled'
      passwordAuth: 'Enabled'
    }
  }
}

// Firewall Rule: Azure Services erlauben
resource postgresFirewallAzure 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2023-06-01-preview' = {
  name: 'AllowAzureServices'
  parent: postgresServer
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// PostgreSQL Datenbank
resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2023-06-01-preview' = {
  name: postgresDatabaseName
  parent: postgresServer
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
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
      secrets: [
        {
          name: 'db-password'
          value: postgresAdminPassword
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'apiserver'
          image: apiServerImage
          resources: {
            cpu: json('2.5')
            memory: '5Gi'
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
            {
              name: 'ALPINE_DATABASE_MODE'
              value: 'external'
            }
            {
              name: 'ALPINE_DATABASE_URL'
              value: 'jdbc:postgresql://${postgresServer.properties.fullyQualifiedDomainName}:5432/${postgresDatabaseName}?sslmode=require'
            }
            {
              name: 'ALPINE_DATABASE_DRIVER'
              value: 'org.postgresql.Driver'
            }
            {
              name: 'ALPINE_DATABASE_USERNAME'
              value: postgresAdminUser
            }
            {
              name: 'ALPINE_DATABASE_PASSWORD'
              secretRef: 'db-password'
            }
            {
              name: 'ALPINE_DATABASE_POOL_ENABLED'
              value: 'true'
            }
            {
              name: 'ALPINE_DATABASE_POOL_MAX_SIZE'
              value: '20'
            }
            {
              name: 'ALPINE_DATABASE_POOL_MIN_IDLE'
              value: '10'
            }
            {
              name: 'ALPINE_OIDC_ENABLED'
              value: 'true'
            }
            {
              name: 'ALPINE_OIDC_CLIENT_ID'
              value: oidcClientId
            }
            {
              name: 'ALPINE_OIDC_ISSUER'
              value: 'https://login.microsoftonline.com/${oidcTenantId}/v2.0'
            }
            {
              name: 'ALPINE_OIDC_USERNAME_CLAIM'
              value: 'preferred_username'
            }
            {
              name: 'ALPINE_OIDC_USER_PROVISIONING'
              value: 'true'
            }
            {
              name: 'ALPINE_OIDC_TEAMS_CLAIM'
              value: 'groups'
            }
            {
              name: 'ALPINE_OIDC_TEAM_SYNCHRONIZATION'
              value: 'true'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
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
            {
              name: 'OIDC_ISSUER'
              value: 'https://login.microsoftonline.com/${oidcTenantId}/v2.0'
            }
            {
              name: 'OIDC_CLIENT_ID'
              value: oidcClientId
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
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
output containerRegistryName string = !empty(containerRegistryName) ? containerRegistryName : ''
output containerRegistryLoginServer string = !empty(containerRegistryName) ? '${containerRegistryName}.azurecr.io' : ''
output postgresServerFqdn string = postgresServer.properties.fullyQualifiedDomainName
output postgresDatabaseName string = postgresDatabaseName
output apiServerUrl string = 'https://${apiServerApp.properties.configuration.ingress.fqdn}'
output frontendUrl string = 'https://${frontendApp.properties.configuration.ingress.fqdn}'
output environmentId string = environment.id

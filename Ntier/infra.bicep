@description('Azure region for all regional resources')
param location string = resourceGroup().location

@description('Name of the Web App (must be globally unique).')
param webAppName string

@description('Name of the App Service Plan.')
param appServicePlanName string = '${webAppName}-plan'

@description('SQL Server name (must be globally unique).')
param sqlServerName string

@description('SQL Database name.')
param sqlDatabaseName string = '${sqlServerName}-db'

@description('SQL admin username.')
param sqlAdminLogin string

@secure()
@description('SQL admin password.')
param sqlAdminPassword string

@description('Key Vault name (must be globally unique).')
param keyVaultName string = '${webAppName}-kv'

@description('Key Vault secret name to store the SQL connection string.')
param sqlConnectionSecretName string = 'SqlConnectionString'

@description('Azure Front Door profile name.')
param afdProfileName string = '${webAppName}-afd'

@description('Azure Front Door endpoint name (must be globally unique within Azure Front Door).')
param afdEndpointName string = '${webAppName}-endpoint'

// -------------------------
// Cost-effective defaults
// -------------------------

// App Service Plan: Basic (B1) is usually the cheapest tier that still supports custom domains/SSL.
// (Free/Shared exist but are very limited; Basic is a common “cost-effective but usable” baseline.)
var appServiceSkuName = 'B1'
var appServiceSkuTier = 'Basic'

// Azure SQL Database: Basic is very low-cost but constrained.
// Consider S0 if you need more performance/connections.
var sqlSkuName = 'Basic'

// Key Vault: Standard is the cost-effective option.
var keyVaultSkuName = 'standard'

// Azure Front Door: Standard (not Premium) is the cheaper AFD SKU.
var afdSkuName = 'Standard_AzureFrontDoor'

// Built-in role: Key Vault Secrets User
var keyVaultSecretsUserRoleDefinitionId = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')

// SQL connection string (ADO.NET-style). Adjust to your app needs if required.
var sqlConnectionString = 'Server=tcp:${sqlServerName}.database.windows.net,1433;Initial Catalog=${sqlDatabaseName};Persist Security Info=False;User ID=${sqlAdminLogin};Password=${sqlAdminPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'

// -------------------------
// App Service Plan + Web App (Managed Identity)
// -------------------------
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: appServiceSkuName
    tier: appServiceSkuTier
    capacity: 1
  }
  properties: {
    reserved: false
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        // Key Vault reference (resolved at runtime by App Service)
        {
          name: 'SqlConnectionString'
          value: '@Microsoft.KeyVault(SecretUri=${sqlConnSecret.properties.secretUriWithVersion})'
        }
      ]
    }
  }
}

// -------------------------
// Azure SQL Server + Database
// -------------------------
resource sqlServer 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2023-08-01-preview' = {
  parent: sqlServer
  name: sqlDatabaseName
  location: location
  sku: {
    name: sqlSkuName
  }
  properties: {
    // Basic supports up to 2 GB max size. Keep it aligned to avoid unexpected validation issues.
    maxSizeBytes: 2147483648
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

// Allow Azure services to access the SQL Server (optional but often needed initially)
resource allowAzureServicesFirewall 'Microsoft.Sql/servers/firewallRules@2023-08-01-preview' = {
  parent: sqlServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

// -------------------------
// Key Vault + Secret (SQL connection string)
// -------------------------
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: keyVaultSkuName
      family: 'A'
    }

    // Use RBAC (cleaner than access policies)
    enableRbacAuthorization: true
  }
}

resource sqlConnSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: sqlConnectionSecretName
  properties: {
    value: sqlConnectionString
  }
}

// Grant Web App managed identity permission to read secrets
resource kvSecretsUserAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, webApp.id, keyVaultSecretsUserRoleDefinitionId)
  scope: keyVault
  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
    principalId: webApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// -------------------------
// Azure Front Door (Standard) - global, but in same RG
// -------------------------
resource afdProfile 'Microsoft.Cdn/profiles@2024-05-01' = {
  name: afdProfileName
  location: 'global'
  sku: {
    name: afdSkuName
  }
}

resource afdEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2024-05-01' = {
  parent: afdProfile
  name: afdEndpointName
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2024-05-01' = {
  parent: afdProfile
  name: '${webAppName}-og'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 0
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'GET'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 120
    }
    sessionAffinityState: 'Disabled'
  }
}

resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2024-05-01' = {
  parent: originGroup
  name: '${webAppName}-origin'
  properties: {
    hostName: webApp.properties.defaultHostName
    originHostHeader: webApp.properties.defaultHostName
    httpPort: 80
    httpsPort: 443
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
  }
}

resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2024-05-01' = {
  parent: afdEndpoint
  name: '${webAppName}-route'
  properties: {
    originGroup: {
      id: originGroup.id
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Enabled'
    enabledState: 'Enabled'
  }
}

// -------------------------
// Outputs
// -------------------------
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppManagedIdentityPrincipalId string = webApp.identity.principalId
output sqlServerFqdn string = '${sqlServerName}.database.windows.net'
output sqlDbResourceId string = sqlDb.id
output keyVaultUri string = keyVault.properties.vaultUri
output sqlConnSecretUriWithVersion string = sqlConnSecret.properties.secretUriWithVersion
output frontDoorEndpointHost string = afdEndpoint.properties.hostName
output frontDoorUrl string = 'https://${afdEndpoint.properties.hostName}'

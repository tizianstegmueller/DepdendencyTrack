using './main.bicep'

param containerRegistryName = 'okdependencytrackregistry'
param location = 'germanywestcentral'
param environmentName = 'ok-dependencytrack-env'
param apiServerAppName = 'ok-dependencytrack-apiserver'
param frontendAppName = 'ok-dependencytrack-frontend'
param apiServerImage = 'dependencytrack/apiserver:latest'
param frontendImage = 'dependencytrack/frontend:latest'
param postgresServerName = 'ok-dtrack-postgres'
param postgresDatabaseName = 'dtrack'
param postgresAdminUser = 'dtrackadmin'
param postgresLocation = 'westeurope'
param postgresAdminPassword = '<your-secret-password>' // Replace with your actual password or use a secure method
param oidcClientId = '4d863fde-9698-4202-afae-706811088049'
param oidcTenantId = 'a58ab8e5-0d27-43df-8cb8-d2c3196d6e98'
// postgresAdminPassword wird über GitHub Secret POSTGRES_PASSWORD übergeben (nicht hier speichern!)

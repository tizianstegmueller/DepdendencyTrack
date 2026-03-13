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
// postgresAdminPassword wird über GitHub Secret POSTGRES_PASSWORD übergeben (nicht hier speichern!)

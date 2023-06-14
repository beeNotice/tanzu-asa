#!/bin/bash

set -v

# Configuration
WORKSPACE_PATH=/mnt/c/Dev/workspaces/tanzu-asa
export RESOURCE_GROUP=rg-tanzu-asa
export SPRING_APPS_SERVICE=asa-tanzu-fmartin
export REGION=francecentral
export HELLO_SERVICE_APP="hello-service"
export LOG_ANALYTICS_WORKSPACE=lo-tanzu-asa

cd $WORKSPACE_PATH

# Resource Group
az group create --name ${RESOURCE_GROUP} \
--location ${REGION}

# Azure Spring Apps Enterprise
az spring create --name ${SPRING_APPS_SERVICE} \
--resource-group ${RESOURCE_GROUP} \
--location ${REGION} \
--sku Enterprise \
--enable-application-configuration-service \
--enable-service-registry \
--enable-application-accelerator \
--enable-application-live-view \
--enable-gateway \
--enable-api-portal \
--build-pool-size S2

# Common configuration
az configure --defaults \
group=${RESOURCE_GROUP} \
location=${REGION} \
spring=${SPRING_APPS_SERVICE}

# Logs configuration
az monitor log-analytics workspace create \
--workspace-name ${LOG_ANALYTICS_WORKSPACE} \
--location ${REGION} \
--resource-group ${RESOURCE_GROUP}

export LOG_ANALYTICS_RESOURCE_ID=$(az monitor log-analytics workspace show \
--resource-group ${RESOURCE_GROUP} \
--workspace-name ${LOG_ANALYTICS_WORKSPACE} | jq -r '.id')

export SPRING_APPS_RESOURCE_ID=$(az spring show \
--name ${SPRING_APPS_SERVICE} \
--resource-group ${RESOURCE_GROUP} | jq -r '.id')

az monitor diagnostic-settings create --name "send-logs-and-metrics-to-log-analytics" \
--resource ${SPRING_APPS_RESOURCE_ID} \
--workspace ${LOG_ANALYTICS_RESOURCE_ID} \
--logs '[
{
"category": "ApplicationConsole",
"enabled": true,
"retentionPolicy": {
"enabled": false,
"days": 0
}
},
{
"category": "SystemLogs",
"enabled": true,
"retentionPolicy": {
"enabled": false,
"days": 0
}
},
{
"category": "IngressLogs",
"enabled": true,
"retentionPolicy": {
"enabled": false,
"days": 0
}
}
]' \
--metrics '[
{
"category": "AllMetrics",
"enabled": true,
"retentionPolicy": {
"enabled": false,
"days": 0
}
}
]'

# Create an App
az spring app create --name ${HELLO_SERVICE_APP} \
--instance-count 1 \
--memory 1Gi

# Configure Application Configuration Service
az spring application-configuration-service git repo add --name tanzu-asa-config \
--label main \
--patterns "hello/asa" \
--uri "https://github.com/beeNotice/tanzu-asa" \
--search-paths "config"

# Bind Application to Configuration
az spring application-configuration-service bind --app ${HELLO_SERVICE_APP}

# Bind Application to Service
az spring service-registry bind --app ${HELLO_SERVICE_APP}

# Déploiement d'une application
az spring app deploy --name ${HELLO_SERVICE_APP} \
--config-file-pattern hello/asa \
--source-path hello-service \
--build-env 'BP_JVM_VERSION=17.*' \
--env 'SPRING_PROFILES_ACTIVE=asa'

# API Gateway
az spring gateway update --assign-endpoint true

export GATEWAY_URL=$(az spring gateway show | jq -r '.properties.url')
echo $GATEWAY_URL

az spring gateway update \
--api-description "Tanzu Azure Spring Apps demo API" \
--api-title "Tanzu Azure Spring Apps" \
--api-version "v1.0" \
--server-url "https://${GATEWAY_URL}" \
--allowed-origins "*" \
--no-wait

# https://learn.microsoft.com/fr-fr/azure/spring-apps/how-to-use-enterprise-spring-cloud-gateway
# Create route
az spring gateway route-config create \
--name ${HELLO_SERVICE_APP} \
--app-name ${HELLO_SERVICE_APP} \
--routes-file routes/hello-service.json

# API Portal
az spring api-portal update --assign-endpoint true
export PORTAL_URL=$(az spring api-portal show | jq -r '.properties.url')
echo $PORTAL_URL

# Developer Tools
az spring dev-tool update \
    --resource-group ${RESOURCE_GROUP} \
    --service ${SPRING_APPS_SERVICE} \
    --assign-endpoint


# Accelerators
# https://learn.microsoft.com/en-us/azure/spring-apps/how-to-use-accelerator?tabs=Azure-CLI
az spring application-accelerator customized-accelerator create \
    --name tanzu-asa-accelerator \
    --resource-group ${RESOURCE_GROUP} \
    --service ${SPRING_APPS_SERVICE} \
    --display-name tanzu-asa-accelerator \
    --description 'This is a sample Accelerator!' \
    --git-url https://github.com/beeNotice/tanzu-asa \
    --git-branch main \
    --accelerator-tags asae,demo \
    --icon-url 'data:image/png;base64,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'

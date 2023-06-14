## Introduction

This is a simple Spring boot application to demonstrate some Azure Spring Apps Enterprise capabilities.

## Installation

### Prerequisites

* https://learn.microsoft.com/en-us/azure/spring-apps/quickstart?tabs=Azure-CLI

### Deployment

```bash
sh scripts/deploy.sh
```

## Demo

### Endpoints

* /
* /service-instances/hello-service
* /invoke-hello
* /actuator

### Configuration

```bash
# Refresh
# https://learn.microsoft.com/en-us/azure/spring-apps/how-to-enterprise-application-configuration-service#refresh-strategies
# The refresh frequency is managed by Azure Spring Apps and fixed to 60 seconds.
# Update value at https://github.com/beeNotice/tanzu-asa/blob/main/config/hello-asa.yaml
export SPRING_APPS_TEST_ENDPOINT=$(az spring test-endpoint list \
--name ${SPRING_APPS_SERVICE} \
--resource-group ${RESOURCE_GROUP} | jq -r '.primaryTestEndpoint')
curl ${SPRING_APPS_TEST_ENDPOINT}/${HELLO_SERVICE_APP}/default/actuator/refresh -d {} -H "Content-Type: application/json"
```

## Operations

```bash
# Restart
az spring app restart -n ${HELLO_SERVICE_APP}

# Applications
az spring app list --output table

# Instances
az spring app show --name ${HELLO_SERVICE_APP} --query properties.activeDeployment.properties.instances --output table

# Logs
az spring app logs --name ${HELLO_SERVICE_APP}
```

## Resources

* https://learn.microsoft.com/en-us/azure/spring-apps/reference-architecture?tabs=azure-spring-enterprise
* https://techcommunity.microsoft.com/t5/apps-on-azure-blog/do-more-with-azure-spring-apps-scale-to-zero-and-enhance/ba-p/3691288
* https://learn.microsoft.com/en-us/azure/spring-apps/how-to-intellij-deploy-apps

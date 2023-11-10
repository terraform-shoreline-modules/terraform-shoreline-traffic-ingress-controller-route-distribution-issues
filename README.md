
### About Shoreline
The Shoreline platform provides real-time monitoring, alerting, and incident automation for cloud operations. Use Shoreline to detect, debug, and automate repairs across your entire fleet in seconds with just a few lines of code.

Shoreline Agents are efficient and non-intrusive processes running in the background of all your monitored hosts. Agents act as the secure link between Shoreline and your environment's Resources, providing real-time monitoring and metric collection across your fleet. Agents can execute actions on your behalf -- everything from simple Linux commands to full remediation playbooks -- running simultaneously across all the targeted Resources.

Since Agents are distributed throughout your fleet and monitor your Resources in real time, when an issue occurs Shoreline automatically alerts your team before your operators notice something is wrong. Plus, when you're ready for it, Shoreline can automatically resolve these issues using Alarms, Actions, Bots, and other Shoreline tools that you configure. These objects work in tandem to monitor your fleet and dispatch the appropriate response if something goes wrong -- you can even receive notifications via the fully-customizable Slack integration.

Shoreline Notebooks let you convert your static runbooks into interactive, annotated, sharable web-based documents. Through a combination of Markdown-based notes and Shoreline's expressive Op language, you have one-click access to real-time, per-second debug data and powerful, fleetwide repair commands.

### What are Shoreline Op Packs?
Shoreline Op Packs are open-source collections of Terraform configurations and supporting scripts that use the Shoreline Terraform Provider and the Shoreline Platform to create turnkey incident automations for common operational issues. Each Op Pack comes with smart defaults and works out of the box with minimal setup, while also providing you and your team with the flexibility to customize, automate, codify, and commit your own Op Pack configurations.

# Ingress Controller Route Distribution Issues

This incident type involves problems with the distribution of routes in an Ingress Controller, specifically in Traefik. An Ingress Controller is a component of Kubernetes that manages external access to the services in a cluster. It acts as a reverse proxy and routes incoming traffic to the appropriate service. Route distribution issues can lead to service disruptions, as the traffic may not be properly directed to the intended service. This can affect the availability and reliability of applications running in the cluster.

### Parameters

```shell
export INGRESS_CONTROLLER_POD_NAME="PLACEHOLDER"
export NAMESPACE="PLACEHOLDER"
export INGRESS_NAME="PLACEHOLDER"
export DESIRED_NUMBER_OF_REPLICAS="PLACEHOLDER"
export INGRESS_CONTROLLER_OR_TRAEFIK_DEPLOYMENT="PLACEHOLDER"
export SERVICE_URL="PLACEHOLDER"
export NODE_NAME="PLACEHOLDER"
export INGRESS_CONTROLLER_POD="PLACEHOLDER"
```

## Debug

### Check if the Ingress Controller is running

```shell
kubectl get pods -n ${NAMESPACE} | grep ${INGRESS_CONTROLLER_POD_NAME}
```

### Check the logs of the Ingress Controller

```shell
kubectl logs -n ${NAMESPACE} ${INGRESS_CONTROLLER_POD_NAME}
```

### Check the status of the Traefik pods

```shell
kubectl get pods -n ${NAMESPACE} -l "app=traefik"
```

### Check the logs of the Traefik pods

```shell
kubectl logs -n ${NAMESPACE} -l "app=traefik"
```

### Check the Ingress resources

```shell
kubectl get ing -n ${NAMESPACE}
```

### Check the status of the Ingress resources

```shell
kubectl describe ing -n ${NAMESPACE} ${INGRESS_NAME}
```

### Check the endpoints of the Ingress resources

```shell
kubectl get endpoints -n ${NAMESPACE} ${INGRESS_NAME}
```

### Check the events related to the Ingress resources

```shell
kubectl get events -n ${NAMESPACE} --sort-by='.metadata.creationTimestamp' | grep ${INGRESS_NAME}
```

## Repair

### Consider scaling up the Ingress Controller or Traefik to handle increased traffic and load.

```shell
#!/bin/bash

# Set variables
NAMESPACE=${NAMESPACE}
DEPLOYMENT=${INGRESS_CONTROLLER_OR_TRAEFIK_DEPLOYMENT}
REPLICAS=${DESIRED_NUMBER_OF_REPLICAS}

# Scale up the deployment
kubectl scale deployment $DEPLOYMENT -n $NAMESPACE --replicas=$REPLICAS

# Check the status of the deployment
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE
```

### Verify that the Ingress Controller is running properly and that there are no issues with connectivity or resource allocation.

```shell
#!/bin/bash

# Verify that the Ingress Controller is running properly
if kubectl get pods -n ${NAMESPACE} | grep ${INGRESS_CONTROLLER_POD} | grep Running >/dev/null; then
  echo "Ingress Controller is running"
else
  echo "Ingress Controller is not running. Restarting pod..."
  kubectl delete pod ${INGRESS_CONTROLLER_POD} -n ${NAMESPACE}
fi

# Check for issues with connectivity
if kubectl exec -it ${INGRESS_CONTROLLER_POD} -n ${NAMESPACE} -- curl -I ${SERVICE_URL} | grep HTTP >/dev/null; then
  echo "Connectivity to service is working"
else
  echo "Unable to connect to service. Checking network configuration..."
  kubectl describe pod ${INGRESS_CONTROLLER_POD} -n ${NAMESPACE} | grep "FailedScheduling\|FailedCreatePodSandBox" >/dev/null
  if [ $? -eq 0 ]; then
    echo "Failed to schedule pod. Checking resource allocation..."
    kubectl describe node ${NODE_NAME} | grep -A 5 "Allocated resources" | grep -v "Event" >/dev/null
    if [ $? -eq 0 ]; then
      echo "Resource allocation looks good. Restarting node..."
      kubectl drain ${NODE_NAME} --delete-local-data --force --ignore-daemonsets
      kubectl delete node ${NODE_NAME}
      kubectl uncordon ${NODE_NAME}
    else
      echo "Resource allocation issue. Please check node resource limits."
    fi
  else
    echo "Network configuration issue. Please check pod network configuration and try again."
  fi
fi
```
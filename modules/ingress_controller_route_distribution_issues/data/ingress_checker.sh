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
#!/bin/bash

# Set variables
NAMESPACE=${NAMESPACE}
DEPLOYMENT=${INGRESS_CONTROLLER_OR_TRAEFIK_DEPLOYMENT}
REPLICAS=${DESIRED_NUMBER_OF_REPLICAS}

# Scale up the deployment
kubectl scale deployment $DEPLOYMENT -n $NAMESPACE --replicas=$REPLICAS

# Check the status of the deployment
kubectl rollout status deployment/$DEPLOYMENT -n $NAMESPACE
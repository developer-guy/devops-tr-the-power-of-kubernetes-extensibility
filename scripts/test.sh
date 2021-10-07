#!/usr/bin/env bash

YELLOW='\033[0;33m'

# Create Namespace
echo "$YELLOW $ kubectl create ns myapp1 \n"
kubectl create ns myapp1

echo "\n"

# Create ServiceAccount
echo "$YELLOW $ kubectl apply -f serviceaccount.yaml \n"
kubectl apply -f serviceaccount.yaml

echo "\n"

# Create SecretProviderClass
echo "$YELLOW $ kubectl apply -f secretproviderclass.yaml \n"
kubectl apply -f secretproviderclass.yaml

echo "\n"

# Create Pod
echo "$YELLOW $ kubectl apply -f pod.yaml \n"
kubectl apply -f pod.yaml

echo "\n"

# Wait until Pod become ready
echo "$YELLOW $ kubectl wait --for=condition=Ready=true -n myapp1 pod/nginx-secrets-store-inline \n"
kubectl wait --for=condition=Ready=true -n myapp1 pod/nginx-secrets-store-inline

echo "\n"

# Verify whether secret exists or not
echo "$YELLOW $ kubectl exec -n=myapp1 nginx-secrets-store-inline -- cat /mnt/secrets-store/password \n"
kubectl exec -n=myapp1 nginx-secrets-store-inline -- cat /mnt/secrets-store/password

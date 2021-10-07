#!/usr/bin/env bash

YELLOW='\033[0;33m'

# Set up Secret Store CSI Driver
echo "$YELLOW $ helm install csi secrets-store-csi-driver/secrets-store-csi-driver --namespace=vault \n"

read -n 1 -s -r -p "Press any key to continue"

echo "\n"

helm install csi secrets-store-csi-driver/secrets-store-csi-driver --namespace=vault

echo "\n"

# Wait until Pods of Secret Store CSI Driver become ready
echo "$YELLOW $ kubectl wait --for=condition=Ready=true pod -n vault -l \"app in (secrets-store-csi-driver)\" \n"

read -n 1 -s -r -p "Press any key to continue"

echo "\n"

kubectl wait --for=condition=Ready=true pod -n vault -l "app in (secrets-store-csi-driver)"


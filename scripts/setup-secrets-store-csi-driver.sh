#!/usr/bin/env bash

YELLOW='\033[0;33m'

# Set up Secret Store CSI Driver
echo "$YELLOW $helm install csi secrets-store-csi-driver/secrets-store-csi-driver --namespace=vault \n"

helm install csi secrets-store-csi-driver/secrets-store-csi-driver --namespace=vault

echo "$YELLOW $ kubectl wait --for=condition=Ready=true pod -n vault -l \"app in (secrets-store-csi-driver)\" \n"

kubectl wait --for=condition=Ready=true pod -n vault -l "app in (secrets-store-csi-driver)"


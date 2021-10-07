#!/usr/bin/env bash

YELLOW='\033[0;33m'

# Set up Vault in server mode with Vault CSI Provider enabled
echo "$YELLOW $ helm install vault hashicorp/vault --create-namespace --namespace=vault \\
 --set \"server.dev.enabled=true\" \\
 --set \"injector.enabled=false\" \\
 --set \"csi.enabled=true\" \n"

helm install vault hashicorp/vault --create-namespace --namespace=vault \
  --set "server.dev.enabled=true" \
  --set "injector.enabled=false" \
  --set "csi.enabled=true"

echo "\n"

# Wait for Vault and Vault CSI Provider to become running
echo "$YELLOW $ kubectl wait --for=condition=Ready=true pod -n vault -l \"app.kubernetes.io/name in (vault-csi-provider)\" \n"
kubectl wait --for=condition=Ready=true pod -n vault -l "app.kubernetes.io/name in (vault, vault-csi-provider)"

echo "\n"

# Put Application Secret
echo "$YELLOW $ kubectl exec -it vault-0 --namespace=vault -- vault kv put secret/db-pass password=\"db-secret-password\" \n"
kubectl exec -it vault-0 --namespace=vault -- vault kv put secret/db-pass password="db-secret-password"

echo "\n"

# Verify whether Application Secret is ready or not
echo "$YELLOW $ kubectl exec -it vault-0 --namespace=vault -- vault kv get secret/db-pass \n"
kubectl exec -it vault-0 --namespace=vault -- vault kv get secret/db-pass

echo "\n"

# Enable Kubernetes Authentication Method
echo "$YELLOW $ kubectl exec -it vault-0 --namespace=vault -- vault auth enable kubernetes \n"
kubectl exec -it vault-0 --namespace=vault -- vault auth enable kubernetes

echo "\n"

# Start proxy to the Kubernetes API server
echo "$YELLOW $ kubectl proxy > /dev/null 2>&1 & \n"
kubectl proxy >/dev/null 2>&1 &

# Get ISSUER
echo "$YELLOW $ ISSUER=$(curl --silent http://127.0.0.1:8001/.well-known/openid-configuration | jq -r .issuer) \n"
ISSUER=$(curl --silent http://127.0.0.1:8001/.well-known/openid-configuration | jq -r .issuer)

SERVICE_ACCOUNT_JWT=$(kubectl exec -it vault-0 --namespace=vault -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
ZONE=$(gcloud config get-value compute/zone)
PROJECT=$(gcloud config get-value project)
GKE_NAME=vault-csi-provider-demo

FULL_GKE_NAME="gke_${PROJECT}_${ZONE}_${GKE_NAME}"

# Get the host for the cluster (IP address)
K8S_HOST="$(kubectl config view --raw \
  -o go-template="{{ range .clusters }}{{ if eq .name \"${FULL_GKE_NAME}\" }}{{ index .cluster \"server\" }}{{ end }}{{ end }}")"

# Get the CA for the cluster
K8S_CACERT="$(kubectl config view --raw \
  -o go-template="{{ range .clusters }}{{ if eq .name \"${FULL_GKE_NAME}\" }}{{ index .cluster \"certificate-authority-data\" }}{{ end }}{{ end }}" | base64 --decode)"

echo "$YELLOW $ kubectl exec -it vault-0 --namespace=vault -- /bin/sh -c 'vault write auth/kubernetes/config \\
        issuer=\"$ISSUER\" \\
        token_reviewer_jwt=\"$SERVICE_ACCOUNT_JWT\" \\
        kubernetes_host=\"$K8S_HOST\" \\
        kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt' \n"

kubectl exec -it vault-0 --namespace=vault -- /bin/sh -c "vault write auth/kubernetes/config \
                                                    issuer=\"${ISSUER}\" \
                                                    token_reviewer_jwt=\"${SERVICE_ACCOUNT_JWT}\" \
                                                    kubernetes_host=\"${K8S_HOST}\" \
                                                    kubernetes_ca_cert=\"${K8S_CACERT}\""

echo "\n"

echo " $YELLOW $ kubectl exec -it vault-0 --namespace=vault -- /bin/sh -c 'vault policy write csi - <<EOF
                                                                             path \"secret/data/db-pass\" {
                                                                                capabilities = [\"read\"]
                                                                             }
EOF' \n"

kubectl exec -it vault-0 --namespace=vault -- /bin/sh -c 'vault policy write csi - <<EOF
                                                            path "secret/data/db-pass" {
                                                              capabilities = ["read"]
                                                            }
EOF'

echo "\n"

echo "$YELLOW $ kubectl exec -it vault-0 --namespace=vault -- /bin/sh -c 'vault write auth/kubernetes/role/csi \\
    bound_service_account_names=myapp1-sa \\
    bound_service_account_namespaces=myapp1 \\
    policies=csi \\
    ttl=20m' \n"

kubectl exec -it vault-0 --namespace=vault -- /bin/sh -c 'vault write auth/kubernetes/role/csi \
                                                           bound_service_account_names=myapp1-sa \
                                                           bound_service_account_namespaces=myapp1 \
                                                           policies=csi \
                                                           ttl=20m'

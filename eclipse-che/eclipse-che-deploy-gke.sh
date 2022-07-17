#!/bin/bash

gcloud config set project grb-che-1
gcloud config set compute/zone europe-west2-a
gcloud config set compute/region europe-west2

# Create a GKE cluster with the Identity and Workload Identity services enabled
gcloud container clusters create eclipse-che --zone europe-west2-a --enable-identity-service \
  --workload-pool=grb-che-1.svc.id.goog --project "grb-che-1" --release-channel "rapid" \
  --machine-type "n1-standard-8" --image-type "COS_CONTAINERD" --disk-type "pd-standard" \
  --disk-size "30" --spot --num-nodes "1"

kubectl config current-context

# Create a Namespace for Cert manager
kubectl create ns cert-manager

# Create a k8s secret from the Service Account key
kubectl create secret generic clouddns-dns01-solver-svc-acct --from-file=key.json --namespace=cert-manager

# Install Cert manager
kubectl label namespace cert-manager certmanager.k8s.io/disable-validation=true

kubectl apply \
  -f https://github.com/jetstack/cert-manager/releases/download/v1.8.2/cert-manager.yaml \
  --validate=false

# Create a Namespace for Eclipse Che
kubectl create namespace eclipse-che

# Create the Certificate Issuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: che-certificate-issuer
  namespace: cert-manager
spec:
  acme:
    solvers:
    - dns01:
        clouddns:
          project: grb-che-1
          serviceAccountSecretRef:
            key: key.json
            name: clouddns-dns01-solver-svc-acct
    email: gusb79@gmail.com
    privateKeySecretRef:
      name: letsencrypt
    server: https://acme-staging-v02.api.letsencrypt.org/directory
EOF

# Create the Certificate
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
 name: che-tls
 namespace: eclipse-che
spec:
 secretName: che-tls
 issuerRef:
   name: che-certificate-issuer
   kind: ClusterIssuer
 dnsNames:
   - '*.grbgcp.co.uk'
EOF

# Install Ingress Controller NGINX
kubectl apply \
  -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.1/deploy/static/provider/cloud/deploy.yaml

# TODO Wait for the container to run
kubectl get pods --namespace ingress-nginx

# TODO Wait for the external IP
kubectl get services  --namespace ingress-nginx

# Get the external IP
kubectl get services --namespace ingress-nginx \
  -o jsonpath='{.items[].status.loadBalancer.ingress[0].ip}'

# Install chectl
bash <(curl -sL  https://www.eclipse.org/che/chectl/)

# TODO Wait for the certificate to be ready
kubectl describe certificate/che-tls -n eclipse-che

# Configure GKE external OIDC
kubectl apply -f gke_oidc_client-config.yaml

# Install Che using chectl
chectl server:deploy --platform=k8s --domain=grbgcp.co.uk --skip-oidc-provider-check

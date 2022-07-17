# Eclipse Che

# Setup on Minikube

* Install the latest Minikube on Ubuntu:

```
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

* chectl requires minikube to run using the [Docker Driver in Rootless Mode](https://minikube.sigs.k8s.io/docs/drivers/docker/)
   
* Once minikube is running, to access the applications, the entry:
   `127.0.0.1 192.168.x.x.nip.io dex.192.168.x.x.nip.io` 
   is required in /etc/hosts.
   
* It is also necessary to run `minikube tunnel` and provide sudo password interactively
  in order for minikube to be able to route requests from ports lower than 1024 (uses 80 and 443)
  
* To deploy eclipse-che (stable) on Minikube in Ubuntu, run the following script:
   [eclipse-che-minikube.sh](./eclipse-che-minikube.sh)
   
* **IMPORTANT** Currently there are OIDC issues in Minikube **1.26** that prevent Eclipse from working with an OIDC provider. 
   * I tried setting up the Google provider and got an error saying that the provider wass behaving oddly...

# Setup on GCP

These are instructions dated 2022-07 on how to set up Eclipse Che (stable) on GCP.

## Create a GCP project

```
gcloud init
gcloud projects create grb-che-1 --projectid grb-che-1
```

## Enable APIs

```
gcloud services enable dns.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
```

## Domain Registrar Setup

* Create a domain to use with Che, i.e.: Google Domains, Names.co.uk
* Alternatively, you may use the automatic names provided by nip.io based on the external IP.

## Google Cloud DNS Setup

* Create an external DNS zone

```
gcloud dns --project=grb-che-1 managed-zones create eclipse-che --description="" \
   --dns-name="grbgcp.co.uk." --visibility="public" --dnssec-state="off"
```

## Cert Manager Setup

* Create service account for Cert Manager to manage the DNS challenge

`gcloud iam service-accounts create dns01-solver --display-name "dns01-solver"`

* Add the dns.admin role binding

```
gcloud projects add-iam-policy-binding grb-che-1 \
  --member serviceAccount:dns01-solver@grb-che-1.iam.gserviceaccount.com \
  --role roles/dns.admin
```

* Create a Service Account secret

```
gcloud iam service-accounts keys create key.json \
    --iam-account dns01-solver@grb-che-1.iam.gserviceaccount.com
``` 

* **Save the JSON Key file in a safe place**. 
  * It is required to run the the Eclipse Che deployment script.

## Configure OIDC Client Config

    [OIDC with GKE - Documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/oidc)

  * You will need the CLient ID and Secret from your OIDC provider
  
    [Configure OIDC Client Config](https://cloud.google.com/kubernetes-engine/docs/how-to/oidc#configuring_on_a_cluster)


## OIDC Fix

[OIDC Issue](https://github.com/eclipse/che/issues/21049#issuecomment-1067776895)

* Add the following Custom Property to Che Server:

```
customCheProperties:
     CHE_OIDC_USERNAME__CLAIM: "email"
     CHE_INFRA_KUBERNETES_MASTER__URL=https://gke-oidc-envoy.anthos-identity-service
```

* Fork and modify the `che-dashboard` repository:

  * On the file `build/dockerfiles/entrypoint.sh` add:

```
### This is a hack. 
### We have to get the dashboard to connect to the GKE Identity Service endpoint.
### Otherwise the user's OIDC token will not be recognized.
#
# The IP is the GKE OIDC Envoy Load Balancer IP
#
set -a 
KUBERNETES_PORT=tcp://10.225.7.11:443
KUBERNETES_PORT_443_TCP_ADDR=10.225.7.11
KUBERNETES_PORT_443_TCP=tcp://10.225.7.11:443
KUBERNETES_SERVICE_HOST=10.225.7.11
set +a
###
```

# Deploy Che on GKE

* To deploy Eclipse Che on a **new** cluster, run the following script.
  * **NOTE:** It requires the OIDC Client Config file to be present in the same folder.

    [eclipse-che-deploy-gke.sh](./eclipse-che-deploy-gke.sh)

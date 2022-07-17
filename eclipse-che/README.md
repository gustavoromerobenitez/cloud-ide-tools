# Eclipse Che Setup on GCP

These are instructions dated 2022-07 on how to set up Eclipse Che (stable) on GCP.

## Create a GCP project

`
gcloud init
gcloud projects create grb-che-1 --projectid grb-che-1
`

## Enable APIs

`
gcloud services enable dns.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable container.googleapis.com
`

## Install chectl

`bash <(curl -sL  https://www.eclipse.org/che/chectl/)`
  
## Domain Registrar Setup

* Create a domain to use with Che, i.e.: Google Domains, Names.co.uk
* Alternatively, you may use the automatic names provided by nip.io based on the external IP.

## Google Cloud DNS Setup

* Create an external DNS zone

`gcloud dns --project=grb-che-1 managed-zones create eclipse-che --description="" --dns-name="grbgcp.co.uk." --visibility="public" --dnssec-state="off"`

## Cert Manager Setup

* Create service account for Cert Manager to manage the DNS challenge

`gcloud iam service-accounts create dns01-solver --display-name "dns01-solver"`

* Add the dns.admin role binding

`
gcloud projects add-iam-policy-binding grb-che-1 \
  --member serviceAccount:dns01-solver@grb-che-1.iam.gserviceaccount.com \
  --role roles/dns.admin
`

* Create a Service Account secret

`gcloud iam service-accounts keys create key.json \
    --iam-account dns01-solver@grb-che-1.iam.gserviceaccount.com
`   

* **Save the JSON Key file in a safe place**. We will use it in the Eclipse Che deployment script.

* To deploy Eclipse Che on a new cluster, run the following script:

[eclipse-che-deploy-gke.sh](./eclipse-che-deploy-gke.sh)

# Setting up

export REGION="us-east1"
export ZONE="us-east1-d"

export CUSTOM_SECURITY_ROLE="orca_storage_editor_168"
export SERVICE_ACCOUNT="orca-private-cluster-916-sa"


export CLUSTER_NAME="orca-cluster-107"

export SUBNET_NAME="orca-build-subnet"

export ORCA_IP="192.168.10.2/32"

export PROJECT_NAME="qwiklabs-gcp-02-614f934b906a"

export DEVSHELL_PROJECT_ID=$PROJECT_NAME

gcloud config set project $PROJECT_NAME

gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE



# Cleaning
gcloud iam roles delete sec_role --project $DEVSHELL_PROJECT_ID


# Task 1. Create a custom security role

## File: role-definition.yaml
title: "Custom Securiy Role"
description: "Edit access for App Versions"
stage: "ALPHA"
includedPermissions:
- storage.buckets.get
- storage.objects.get
- storage.objects.list
- storage.objects.update
- storage.objects.create
## EOF

gcloud iam roles create $CUSTOM_SECURITY_ROLE --project $DEVSHELL_PROJECT_ID --file role-definition.yaml



# Task 2. Create a service account

gcloud iam service-accounts create $SERVICE_ACCOUNT --display-name "Service Account"



# Task 3. Bind a custom security role to a service account

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member serviceAccount:$SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
    --role projects/$DEVSHELL_PROJECT_ID/roles/$CUSTOM_SECURITY_ROLE 

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member serviceAccount:$SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
    --role roles/monitoring.viewer

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member serviceAccount:$SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
    --role roles/monitoring.metricWriter

gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
    --member serviceAccount:$SERVICE_ACCOUNT@$DEVSHELL_PROJECT_ID.iam.gserviceaccount.com \
    --role roles/logging.logWriter



# Task 4. Create and configure a new Kubernetes Engine private cluster

gcloud services enable container.googleapis.com

gcloud beta container clusters create $CLUSTER_NAME \
    --service-account orca-private-cluster-916-sa@qwiklabs-gcp-02-614f934b906a.iam.gserviceaccount.com \
    --network orca-build-vpc \
    --subnetwork $SUBNET_NAME \
    --enable-master-authorized-networks \
    --master-authorized-networks 192.168.10.2/32 \
    --enable-ip-alias \
    --enable-private-nodes \
    --enable-private-endpoint \
    --disk-type pd-standard \
    --master-ipv4-cidr 172.16.0.16/28 \
    --zone $ZONE

# Task 5. Deploy an application to a private Kubernetes Engine cluster

## On a orca-jumphost via SSH
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin
echo "export USE_GKE_GCLOUD_AUTH_PLUGIN=True" >> ~/.bashrc
source ~/.bashrc

gcloud container clusters get-credentials orca-cluster-107 --internal-ip --project=qwiklabs-gcp-02-614f934b906a --zone us-east1-d

kubectl create deployment hello-server --image=gcr.io/google-samples/hello-app:1.0

# Setting up
export PROJECT_NAME="qwiklabs-gcp-03-69227808d8d5"
export REGION="us-east1"
export ZONE="us-east1-d"

gcloud config set project $PROJECT_NAME
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
export DEVSHELL_PROJECT_ID=$PROJECT_NAME

# Task 1. Create development VPC manually

gcloud compute networks create griffin-dev-vpc \
    --subnet-mode=custom 

gcloud compute networks subnets create griffin-dev-wp \
    --network=griffin-dev-vpc \
    --range=192.168.16.0/20 \
    --region $REGION

gcloud compute networks subnets create griffin-dev-mgmt \
    --network=griffin-dev-vpc \
    --range=192.168.32.0/20 \
    --region $REGION

# Task 2. Create production VPC manually

gcloud compute networks create griffin-prod-vpc \
    --subnet-mode=custom 

gcloud compute networks subnets create griffin-prod-wp \
    --network=griffin-prod-vpc\
    --range=192.168.48.0/20 \
    --region $REGION

gcloud compute networks subnets create griffin-prod-mgmt \
    --network=griffin-prod-vpc \
    --range=192.168.64.0/20 \
    --region $REGION

# Task 3. Create bastion host

gcloud compute instances create bastion-host \
    --zone=$ZONE \
    --network-interface network=griffin-dev-vpc,subnet=griffin-dev-mgmt,no-address \
    --network-interface network=griffin-prod-vpc,subnet=griffin-prod-mgmt,no-address \
    --machine-type=e2-micro 
    
gcloud compute --project=$PROJECT_NAME firewall-rules create managementnet-allow-ssh-dev --direction=INGRESS --priority=1000 --network=griffin-dev-vpc --action=ALLOW --rules=tcp:22 --source-ranges=0.0.0.0/0
gcloud compute --project=$PROJECT_NAME firewall-rules create managementnet-allow-ssh-prod --direction=INGRESS --priority=1000 --network=griffin-prod-vpc --action=ALLOW --rules=tcp:22 --source-ranges=0.0.0.0/0


# Task 4. Create and configure Cloud SQL Instance

gcloud services enable sqladmin.googleapis.com

gcloud sql instances create griffin-dev-db \
    --region=$REGION \
    --database-version=MYSQL_8_0

gcloud auth login --no-launch-browser

gcloud sql connect griffin-dev-db --user=root --quiet

## z poziomy SQL Shell
CREATE DATABASE wordpress;
CREATE USER "wp_user"@"%" IDENTIFIED BY "stormwind_rules";
GRANT ALL PRIVILEGES ON wordpress.* TO "wp_user"@"%";
FLUSH PRIVILEGES;


# Task 5. Create Kubernetes cluster

gcloud services enable container.googleapis.com

gcloud container clusters create griffin-dev \
  --machine-type e2-standard-4 \
  --num-nodes 2 \
  --network griffin-dev-vpc \
  --subnetwork griffin-dev-wp \
  --zone $ZONE


# Task 6. Prepare the Kubernetes cluster

gsutil -m cp -r gs://cloud-training/gsp321/wp-k8s .
cd wp-k8s
vim ./wp-env.yaml
# wp_user stormwind_rules
kubectl apply -f ./wp-env.yaml


gcloud iam service-accounts keys create key.json \
    --iam-account=cloud-sql-proxy@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com

kubectl create secret generic cloudsql-instance-credentials \
    --from-file key.json


# Task 7. Create a WordPress deployment

vim ./wp-deployment.yaml
# Instance connection name format qwiklabs-gcp-03-69227808d8d5:us-east1:griffin-dev-db

kubectl apply -f ./wp-deployment.yaml
kubectl apply -f ./wp-service.yaml

# griffin-dev-db

gcloud compute --project=$PROJECT_NAME firewall-rules create managementnet-allow-http-dev --direction=INGRESS --priority=1000 --network=griffin-dev-vpc --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0
gcloud compute --project=$PROJECT_NAME firewall-rules create managementnet-allow-http-prod --direction=INGRESS --priority=1000 --network=griffin-prod-vpc --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0

# Task 8. Enable monitoring
griffin-uptime-check

gcloud compute --project=$PROJECT_NAME firewall-rules create managementnet-allow-monitoring-dev --direction=INGRESS --priority=1000 --network=griffin-dev-vpc --action=ALLOW --rules=tcp --source-ranges=130.211.0.0/22,35.191.0.0/16
gcloud compute --project=$PROJECT_NAME firewall-rules create managementnet-allow-monitoring-prod --direction=INGRESS --priority=1000 --network=griffin-prod-vpc --action=ALLOW --rules=tcp --source-ranges=130.211.0.0/22,35.191.0.0/16



# Task 9. Provide access for an additional engineer




##8

gcloud compute --project=$PROJECT_NAME firewall-rules delete managementnet-allow-http-dev

gcloud iam service-accounts keys delete key.json \
    --iam-account=cloud-sql-proxy@$GOOGLE_CLOUD_PROJECT.iam.gserviceaccount.com


cd ~

rm -rf ./wp-k8s

gcloud container clusters delete griffin-dev




# Cleaning
# ....


# Notes 

gcloud compute firewall-rules create <FIREWALL_NAME> --network griffin-prod-vpc --allow tcp,udp,icmp --source-ranges <IP_RANGE>
gcloud compute firewall-rules create <FIREWALL_NAME> --network griffin-prod-vpc --allow tcp:22,tcp:3389,icmp



gcloud iam service-accounts create cloud-sql-proxy --display-name="LAB Service Account"


gcloud container clusters create bootcamp \
  --machine-type e2-small \
  --num-nodes 3 \
  --scopes "https://www.googleapis.com/auth/projecthosting,storage-rw"


  gcloud sql instances describe griffin-dev-db --project=$PROJECT_NAME
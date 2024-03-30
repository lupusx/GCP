
############# START #############

# Data from Lab Details panel
export ZONE="us-west3-c"
export REGION="us-west3"
export INSTANCE="nucleus-jumphost-759"
export APP_PORT="8080"
export RULE_NAME="grant-tcp-rule-220"



gcloud config set compute/zone $ZONE
gcloud config set compute/region $REGION


############# Task 1 ##############
gcloud compute instances create nucleus-jumphost-905 --machine-type e2-micro --zone $ZONE


############# Task 2 ##############

# Startup script
cat << EOF > startup.sh
#! /bin/bash
apt-get update
apt-get install -y nginx
service nginx start
sed -i -- 's/nginx/Google Cloud Platform - '"\$HOSTNAME"'/' /var/www/html/index.nginx-debian.html
EOF

# Create an instance template. Don't use the default machine type. Make sure you specify e2-medium as the machine type.
gcloud compute instance-templates create nucleus-webserver \
   --region=$REGION \
   --tags=allow-health-check \
   --machine-type=e2-medium \
   --image-family=debian-11 \
   --image-project=debian-cloud \
   --metadata-from-file=startup-script=./startup.sh
   

# Create a health check.
gcloud compute health-checks create http http-basic-check --port 80

# Create a managed instance group based on the template.
gcloud compute instance-groups managed create nucleus-group --template=nucleus-webserver --size=2 --zone=$ZONE --health-check=http-basic-check

# Create the firewall rule.
gcloud compute firewall-rules create $RULE_NAME \
  --network=default \
  --action=allow \
  --direction=ingress \
  --target-tags=allow-health-check \
  --rules=tcp:80

# Create a backend service and add your instance group as the backend to the backend service group with named port (http:80)
gcloud compute backend-services create nucleus-web-backend-service \
  --protocol=HTTP \
  --port-name=http \
  --health-checks=http-basic-check \
  --global

# Add your instance group as the backend to the backend service
gcloud compute backend-services add-backend nucleus-web-backend-service --instance-group=nucleus-group --global

# Create a URL map, and target the HTTP proxy to route the incoming requests to the default backend service.
gcloud compute url-maps create nucleus-web-map-http --default-service nucleus-web-backend-service

# Create a target HTTP proxy to route requests to your URL map
gcloud compute target-http-proxies create nucleus-http-lb-proxy --url-map nucleus-web-map-http

# Public Address setting 
gcloud compute addresses create nucleus-lb-ipv4-1 --ip-version=IPV4 --global

# Create a forwarding rule.
gcloud compute forwarding-rules create nucleus-http-content-rule --address=nucleus-lb-ipv4-1 --global --target-http-proxy=nucleus-http-lb-proxy --ports=80

# Get public IP address
gcloud compute addresses describe nucleus-lb-ipv4-1 --format="get(address)" --global

#####################################################
##################### STOP ##########################
#####################################################

##### CLEANING #####

printf 'yes' | gcloud compute forwarding-rules delete nucleus-http-content-rule --global
printf 'yes' | gcloud compute addresses delete nucleus-lb-ipv4-1 --global
printf 'yes' | gcloud compute target-http-proxies delete nucleus-http-lb-proxy
printf 'yes' | gcloud compute url-maps delete nucleus-web-map-http
printf 'yes' | gcloud compute backend-services delete nucleus-web-backend-service --global
printf 'yes' | gcloud compute firewall-rules delete $RULE_NAME
printf 'yes' | compute instance-groups managed delete nucleus-group
printf 'yes' | gcloud compute health-checks delete http-basic-check
printf 'yes' | gcloud compute instance-templates delete nucleus-webserver

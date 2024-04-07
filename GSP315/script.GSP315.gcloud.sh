export Username1=student-04-6492872a0ae0@qwiklabs.net
export Username2=student-03-e63afe4f3a2f@qwiklabs.net

############# START #############
# Data from Lab Details panel

export REGION="europe-west4"
export ZONE="europe-west4-a"

export BUCKET_NAME="qwiklabs-gcp-01-039488adcc19-bucket"
export TOPIC_NAME="topic-memories-952"
export FUNCTION_NAME="memories-thumbnail-maker"

export USERNAME2="student-04-2aaa96fb3081@qwiklabs.net"
export PROJECT_NAME="qwiklabs-gcp-01-039488adcc19"

##################################

gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE

##################################

## Task 1. Create a bucket
gcloud storage buckets create gs://$BUCKET_NAME --location=$REGION

## Task 2. Create a Pub/Sub topic
gcloud pubsub topics create $TOPIC_NAME
gcloud pubsub subscriptions create --topic $TOPIC_NAME mySubscription

## Task 3. Create the thumbnail Cloud Function

gcloud services enable cloudfunctions.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable eventarc.googleapis.com


cd 
mkdir -p gsp315
cd gsp315

curl https://storage.googleapis.com/big-liberty-418715-public/gsp315/index.js --output index.js
curl https://storage.googleapis.com/big-liberty-418715-public/gsp315/package.json --output package.json

cd

gcloud functions deploy $FUNCTION_NAME \
  --region=$REGION \
  --entry-point=$FUNCTION_NAME \
  --gen2 \
  --runtime nodejs20 \
  --source=./gsp315 \
  --stage-bucket=$BUCKET_NAME \
  --max-instances=5 \
  --trigger-bucket=$BUCKET_NAME \
  --service-account=big-liberty-418715@appspot.gserviceaccount.com
#  --trigger-event=google.cloud.storage.object.v1.finalized






gcloud functions deploy $FUNCTION_NAME \
  --entry-point=ENTRY_POINT
  --trigger-bucket  \
  --trigger-bucket hello_world \


## Task 4. Test the Infrastructure

curl https://storage.googleapis.com/cloud-training/gsp315/map.jpg --output map.jpg
gcloud storage cp ./map.jpg gs://$BUCKET_NAME/map.jpg

## Task 5. Remove the previous cloud engineer

gcloud projects remove-iam-policy-binding $PROJECT_NAME --member=user:$USERNAME2 --role=roles/viewer
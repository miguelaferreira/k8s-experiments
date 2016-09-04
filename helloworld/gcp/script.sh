#! /bin/bash

set -x

export PROJECT_ID="k8s-helloworld-142317"
export APP_NAME="helloworld_gcp"
export ZONE="europe-west1-b"
export CLUSTER_NAME="hello-node"

docker build -f ../app_v1/Dockerfile -t gcr.io/$PROJECT_ID/$APP_NAME:v1 ../app_v1

# docker run -d -p 8080:8080 --name $APP_NAME gcr.io/$PROJECT_ID/hello-node:v1
# docker stop $APP_NAME

gcloud config set project $PROJECT_ID
gcloud docker push gcr.io/$PROJECT_ID/$APP_NAME:v1

gcloud config set compute/zone $ZONE
if [ -z "$(gcloud container clusters list | grep $CLUSTER_NAME)" ]; then
  gcloud container clusters create $CLUSTER_NAME
fi
gcloud container clusters get-credentials $CLUSTER_NAME

if [ -z "$(kubectl get deployments | grep $CLUSTER_NAME)" ]; then
  kubectl run $CLUSTER_NAME --image=gcr.io/$PROJECT_ID/$CLUSTER_NAME:v1 --port=8080
fi

# kubectl get pods
# kubectl logs $(kubectl get pods | grep $CLUSTER_NAME | awk '{print $1}')
# kubectl cluster-info
# kubectl get events
# kubectl config view

export EXTERNAL_IP="$(kubectl get services hello-node | grep "hello-node" | awk '{print $3}')"
if [ -z "$EXTERNAL_IP" ]; then
  kubectl expose deployment $CLUSTER_NAME --type="LoadBalancer"
fi

# kubectl get services hello-node
# CLUSTER_IP="$(kubectl get services hello-node | grep "hello-node" | awk '{print $2}')"

kubectl scale deployment hello-node --replicas=2
# kubectl get deployment
# kubectl get pods

docker build -f ../app_v2/Dockerfile -t gcr.io/$PROJECT_ID/$APP_NAME:v2 ../app_v2
gcloud docker push gcr.io/$PROJECT_ID/$APP_NAME:v2

kubectl set image deployment/$CLUSTER_NAME $CLUSTER_NAME=gcr.io/$PROJECT_ID/$APP_NAME:v2

# kubectl delete service,deployment $CLUSTER_NAME
# gcloud container clusters delete $CLUSTER_NAME
# gsutil ls
# gsutil rm -r gs://artifacts.$PROJECT_ID.appspot.com/

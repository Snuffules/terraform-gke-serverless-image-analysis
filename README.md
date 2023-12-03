# Serverless solution for Analysing images and posting safe/processed images on cloud storage.
# MongoDB on GKE with Cloud Functions and VPC Access Connector

## Overview
This repository contains Terraform configuration for deploying a MongoDB instance on Google Kubernetes Engine (GKE) with a Google Cloud Function for image analysis. The setup includes a VPC Access Connector for secure communication.

## StatefulSet is used instead of Deployment or ReplicaSet. 
### Reasons:
- When you use a StatefulSet, you don’t need a ReplicaSet.

- StatefulSet and ReplicaSet serve different purposes in Kubernetes. A ReplicaSet ensures that a specified number of pod replicas are running at any given time. However, they do not provide any guarantees about the ordering or uniqueness of these pods. It’s a good choice when you want to have multiple identical pods and don’t need to distinguish between them.

- On the other hand, a StatefulSet is a better choice when you need to maintain the state and identity of each pod. StatefulSets manage the deployment and scaling of a set of Pods and provide guarantees about the ordering and uniqueness of these Pods. Unlike a Deployment or ReplicaSet, a StatefulSet maintains a sticky, stable identity for each of their Pods. These pods are created from the same spec, but they are not interchangeable: each one has a persistent identifier that it maintains across any reschedulings.

- So, if you’re managing stateful applications like databases that require stable network identifiers, stable persistent storage, and ordered, graceful deployment and scaling,   you’d use a StatefulSet.

- In this case, since we are using MongoDB which is a stateful application, using a StatefulSet is the appropriate choice.

## Pvc and persistand disk usage.
### Reasons:
- In a StatefulSet, each pod gets its own Persistent Volume Claim (PVC), which means each pod will have its own storage. This is different from Deployments or ReplicaSets, where the pods share storage.

### One active entrypoint, multiple copies of the database:
- When you have 2 replicas in a StatefulSet, you will have 2 pods, each with its own PVC. This means that each pod will have its own separate copy of the database.

### No duplication, but replication of data:
- In a MongoDB replica set, one node is the primary node that receives all write operations, while the other nodes are secondary nodes that replicate the primary node’s data set. This means that the database records will not duplicate across the PVCs, but rather, the secondary nodes will have a copy of the data from the primary node.

### Data peristancy:
- The data will persist on the PVCs, and the PVCs will exist independently of the pod lifecycle. This means that even if a pod dies, the PVC will still exist and can be mounted to another pod. This is particularly useful for stateful applications like databases, where data persistence is important.

## Timings
- GKE Creation Time: 6:50m - 7:10m
- MongoDB StatefulSet: 1 minute
- VPC Access Connector: 2 minutes
- Image Analysis Function: 1:30 minutes

## Configuration Details

### Authenticate Terraform with google cloud:
#### Authenticate with google cloud:
- gcloud auth application-default login
#### Connect to google kubernetes engine:
- gcloud container clusters get-credentials mongo-cluster --region europe-west1 --project serverless-violence-score
#### Connect to mongodb server via mongodb-0 (first replica):
- kubectl exec -ti mongodb-0 -n mongodb -- mongosh 

### MongoDB URI
#### Working URI format:

#### `<mongodb://mongouser:mongopassword@<mongodb.svc.cluster.local>:27017/<test>?authSource=admin&authMechanism=SCRAM-SHA-256>`

- Replace `<mongodb.svc.cluster.local>` with the Load Balancer IP or directly with the Pod IP endpoint for `mongodb-0`.
- Database name `<test>` can be replaced with `<default>` or `<config>`.

### Network Configurations
- Services Private Network IP Addresses, CIDR Valid Ranges: `10.68.0.0/28`
- Endpoints Private Network IP Addresses, CIDR Valid Ranges: `10.64.0.0/20`
- VPC Access Connector `ip_cidr_range`: `10.8.0.0/28`

### VPC Access and Firewall
- VPC Access allows Cloud Functions to access MongoDB.
- Firewall applied to all private networks and includes Load Balancer. 
- Automatically create a new database and collection upon inserting a new document. 

### Mongodb-key:
- openssl rand -base64 756 > mongodb-keyfile
- Already created, could consider generate your own if there is an issue.

### Mongodb-authentication:
#### mongodb-keyfile used from mongodb replicas and encoded with filebase64:
  data = {
    keyfile = filebase64("${path.module}/mongodb-keyfile")
  }

#### user and password stored with sensitive = true and encoded with base64encode option:
  data = {
    username = base64encode(var.mongo_user)
    password = base64encode(var.mongo_password)
  }

### Buildx
- This is suggested to use when to use, instead of docker build(deprecated): `<https://github.com/docker/buildx#manual-download>`

### Remote State Configuration
#### Uncomment `backend.tf` and apply the Terraform configuration again.  `remote_state.tf` is creating remote cloud storage for tfstate with versioning and encryption.

### Required APIs
#### Enable the following APIs for the project:
- Compute API
- Kubernetes Engine API
- Storage API
- Cloud Build API
- Cloud Run Admin API
- Artifact Registry API
- Cloud Functions API
- Cloud Storage API
- Eventarc API
- Serverless VPC Access API
- Connectors API

### Authentication and Access
Use `gcloud auth application-default login` for authentication. Adjust service accounts for compute and app as needed.

### MongoDB Secret Configuration
Change MongoDB credentials in `modules/mongodb/mongodb_secret.tf`. The Kubernetes Secret is encoded by default.

### CIDR Range Configuration
#### Ensure the firewall protects all ranges and that the Google Function can access the Kubernetes endpoint to reach MongoDB via the MongoDB URI.

### MongoDB Keyfile for ReplicaSet Authentication
Consider generating your own keyfile if there are issues with the existing one. This could be used for higher security and additional authentication.

### MongoDB Connection
Official MongoDB connection string examples: [MongoDB Connection String Examples](https://www.mongodb.com/docs/manual/reference/connection-string/#connection-string-examples)

### Connecting to a VPC Network
For details on connecting Cloud Functions to a VPC, visit [Connecting Cloud Functions to a VPC](https://cloud.google.com/functions/docs/networking/connecting-vpc).

### Serverless VPC Access API
Configure the VPC connector in Cloud Functions for internal access.

### Additional Configuration Notes
- Consider using Cloud Run as an API Gateway to GKE.
- If `enable_private_endpoint` is set to `true`, ensure proper configuration for accessing the GKE API. Bastion machine or VPN is needed. Not applicable for this solution.
- Update the JSON data for source and destination buckets in Cloud Functions as needed.

## To Do
- Assign service account permissions.
- Verify the usage of some variables.

## Done
- Test `enable_private_endpoint = true` and `private_ip_google_access = true`. 

## Successful MongoDB Insertion
Example of a successful record insertion into MongoDB.

Inserted record into MongoDB: {'file_name': 'extra-violent-image.jpg', 'violent_score': <Likelihood.VERY_LIKELY: 5>, '_id': ObjectId('6568081f9948c7742828696f')} 

## Final Remarks
This configuration is currently working and has been tested with various setups. Ensure all the components are correctly configured for seamless integration.

---
For any additional information or queries, please refer to the respective configuration files or raise an issue in the repository.

# Serverless solution for Analysing images and posting safe/processed images on cloud storage.
# MongoDB on GKE with Cloud Functions and Google Vision AI

## Overview
This repository contains Terraform configuration for deploying a MongoDB instance on Google Kubernetes Engine (GKE) with a Google Cloud Function for image analysis. The setup includes a VPC Access Connector for secure communication. Google Vision is the prefered choise for image analysis because of its cloud native nature and it is a simple, yet powerful tool to use.

### Authentication and Access
Use `gcloud auth application-default login` for authentication. Adjust service accounts for compute and app as needed.

### MongoDB Secret Configuration
Change MongoDB credentials in `modules/mongodb/mongodb_secret.tf`. The Kubernetes Secret is encoded by default.

## StatefulSet as the deployment option was chosen. Why not just Deployment or ReplicaSet?
### Reasons:
- When you use a StatefulSet, you don’t need a ReplicaSet.

- StatefulSet and ReplicaSet serve different purposes in Kubernetes. A ReplicaSet ensures that a specified number of pod replicas are running at any given time. However, they do not provide any guarantees about the ordering or uniqueness of these pods. It’s a good choice when you want to have multiple identical pods and don’t need to distinguish between them.

- On the other hand, a StatefulSet is a better choice when you need to maintain the state and identity of each pod. StatefulSets manage the deployment and scaling of a set of Pods and provide guarantees about the ordering and uniqueness of these Pods. Unlike a Deployment or ReplicaSet, a StatefulSet maintains a sticky, stable identity for each of their Pods. These pods are created from the same spec, but they are not interchangeable: each one has a persistent identifier that it maintains across any reschedulings.

- So, if you’re managing stateful applications like databases that require stable network identifiers, stable persistent storage, and ordered, graceful deployment and scaling,   you’d use a StatefulSet.

- In this case, since we are using MongoDB which is a stateful application, using a StatefulSet is the appropriate choice.

  ```hcl
            env {
            name  = "MONGO_INITDB_REPLICA_SET_NAME"
            value = "rs0"  # sets the name of the MongoDB replica set. 
            #This is a part of MongoDB's replication mechanism,
            #where multiple MongoDB instances form a replica set to ensure data redundancy and high availability.
          }
  ```

## Pvc and persistand disk usage.
- Daily regional backups enabled at 04:00AM.
- Metrics for persistent volume utilization created.
- Metric Alert to report above 80%: Done `</modules/metrics/metrics_alert>`
### If you need more size for pvc storage, simply change the size and Expansion future of kubernetes will do the rest.
`<allowVolumeExpansion = true>` this option in storage class `<modules/storage_pvc/storage_class.tf>` will allow you to resize your pvc storage without any downtime or data loss.
This feature provide you with the option to simply to edit your PersistentVolumeClaim (PVC) objects and specify a new size in the PVC spec. Kubernetes will then automatically expand the volume using the storage backend and also expand the underlying file system in-use by the Pod without requiring any downtime.

### Why we use persistent volume claim:
- In a StatefulSet, each pod gets its own Persistent Volume Claim (PVC), which means each pod will have its own storage(That will probably cause issue with single storage source for mongodb cluster). This is different from Deployments or ReplicaSets, where the pods share storage.

### One active entrypoint, multiple copies of the database:
- When you have 2 replicas in a StatefulSet, you will have 2 pods, each with its own PVC. This means that each pod will have its own separate copy of the database.

### No duplication, but replication of data:
- In a MongoDB Stateful set, one node is the primary node that receives all write operations, while the other nodes are secondary nodes that replicate the primary node’s data set. This means that the database records will not duplicate across the PVCs, but rather, the secondary nodes will have a copy of the data from the primary node.

### In a MongoDB Stateful set, the architecture is designed to ensure data integrity and high availability. Here's how it works:

#### Primary Node:
- This is the main node that handles all write operations. When data is written to the primary node, it is responsible for processing and storing this information.

#### Secondary Nodes:
- These nodes are essentially replicas of the primary node. They do not directly handle write operations. Instead, their main role is to replicate the data set of the primary node.

#### Data Replication Process:
- Whenever a change is made in the primary node (like a new record being added or an existing record being updated), this change is automatically replicated across the secondary nodes. This replication process ensures that each secondary node has an exact copy of the data set present in the primary node.

#### Purpose of Replication:
- The replication is crucial for a few reasons:

#### High Availability:
- In case the primary node fails, one of the secondary nodes can be promoted to become the new primary node, ensuring that the database remains operational.
- Data Redundancy: It provides a safeguard against data loss. If the primary node's data is corrupted or lost, the data can be recovered from the secondary nodes.
- No Data Duplication Across PVCs: It's important to note that this replication process does not lead to duplication of records across the Persistent Volume Claims (PVCs). Each node (primary or secondary) has its own PVC, but the data across these PVCs is synchronized, not duplicated. The same record will not be stored multiple times across different nodes; instead, it's just mirrored from the primary to the secondary nodes.

#### Read Operations:
- While the primary node handles all writes, read operations can be distributed across the primary and secondary nodes. This can help in load balancing and improving read performance.

#### Consistency Model:
- MongoDB typically uses a strong consistency model, meaning that the read operations on secondary nodes will reflect the most recent write operations once the replication is complete.

In summary, in a MongoDB Stateful set, there's a primary node for write operations and secondary nodes for replication. This setup ensures high availability, data redundancy, and consistency, without leading to duplication of data across the nodes.

### Data peristancy:
- The data will persist on the PVCs, and the PVCs will exist independently of the pod lifecycle. This means that even if a pod dies, the PVC will still exist and can be mounted to another pod. This is particularly useful for stateful applications like databases, where data persistence is important.

## Timings
- GKE Creation Time: 6:50m - 7:10m
- MongoDB StatefulSet: 1 minute
- VPC Access Connector: 2 minutes
- Image Analysis Function: 1:30 minutes
- Google Filestore 3:45 minutes # 1024Gb is minimum requirement
- Persistent Volume Claim # Should match the size of filestore
- +~2 minutes for all other components

## Configuration Details

### Authenticate Terraform with google cloud:
#### Authenticate with google cloud:
- gcloud auth application-default login
#### Connect to google kubernetes engine:
- gcloud container clusters get-credentials mongo-cluster --region europe-west1 --project serverless-violence-score
#### Connect to mongodb server via mongodb-0 (first replica):
- kubectl exec -ti mongodb-0 -n mongodb -- mongosh 

### MongoDB URI
#### Working URI format used in this solution:
Current code represents automaticaly fetching LoadBalancer IP address and use it in mongo uri as seen here:
`<modules/zip_function/img_analysis.tf>` line 108:
MONGODB_URI           = "mongodb://mongouser:mongopassword@${var.load_balancer_ip}:27017/test?authSource=admin&authMechanism=SCRAM-SHA-256"

#### Official guidance: 
- This will not work as the cluster is private and Cloud function is calling exposed IP adress from LoadBalancer.
For the intend to document official example:
`<mongodb://<user>:<password>@<mongodb.svc.cluster.local>:27017/<test>?authSource=admin&authMechanism=SCRAM-SHA-256>`
- Replace `<user:password>` with yours, but you have to change it in the code as well: `<modules/mongodb
/mongo_secret.tf>`
- Replace `<mongodb.svc.cluster.local>` with the Load Balancer IP or directly with the Pod IP endpoint for `mongodb-0`.
- Database name `<test>` can be replaced with `<default>` or `<config>`. Should work without selecting a database as well (it will use default, which is test).

### Gke reason to use enable_private_nodes and why we do not use private_endpoint for this solution:

#### enable_private_nodes: 

- When set to true, this option ensures that the nodes of the cluster do not have public IP addresses. 
This means that the nodes are only accessible from within the Google Cloud network.
This setting is often used to enhance the security of the cluster by ensuring that the nodes are not accessible from the public internet.

#### enable_private_endpoint: 

- This option, when set to true, makes the Kubernetes API server accessible only from within the Google Cloud network.
When set to false, the API server is accessible from the public internet, although it can still be secured and limited using authorized networks or other security mechanisms.

- In this case, with enable_private_nodes set to true and enable_private_endpoint set to false,
you have a configuration where the nodes of your GKE cluster are only accessible within the Google Cloud network, 
but the Kubernetes API server is accessible from the public internet. 
This setup provides a balance between protecting the nodes from direct public access while still allowing easy management
of the cluster through the API server from outside the Google Cloud network.

This configuration is common and recommended when you need external access to the Kubernetes API server 
(like managing the cluster from a CI/CD pipeline outside Google Cloud) but still want to keep the workloads running on the nodes protected from direct public access.

### Service account permissions are used only once in second function

### Cloud function v1 and v2
#### img_analysis cloudfunction (v1) - implemented a delay, to ensure pubsub topic is ready to accept messages
#### Why using Cloud function v1 isn`t that the old version?
- To implement VPC serverless access connect, so cloud function can authenticate and insert records into MongoDB `<db>` and `<collection>` (`<mongodb>` and `<violence_score>` respectively, change to your preference, if needed).
- This option is available only for v1 Cloud functions.

#### img_processing cloudfunction (v2) 
#### Why Cloud function v2? Didn`t you just said, that there is a problem with v2 in previous statement?
- Initially, both functions was designed as v2. img_analysis refactoring to v1 allows use of VPC Serverless Access Connector, therefore was the right call. Cloudfunction2 options are more complicated and go beyond serveless concept.
- Decision to leave img_processing cloud function as v2 seems as a good idea (for now at least) to test the concept of v1 and v2 functions. They work independent from each other, so there is no funtionality issues with this workflow.
- So, why not? To test functionality and usage/issues with v2 as well.
- Cloud function v2 bring new features better performance(?), but doesn`t have backward compatibily with such feature as VPC Serverless Access connector.
- New versions have to be tested before actual usage. Not always new versions are the better choice.

### Network Configurations
- Services Private Network IP Addresses, `ip_cidr_range`: `10.68.0.0/28`
- Endpoints Private Network IP Addresses, `ip_cidr_range`: `10.64.0.0/20`
- VPC Access Connector `ip_cidr_range`: `10.8.0.0/28`

### Web application firewall to prevent external attempts to disrupt the service like DOS or DDOS attacks.
`<modules/vpc/waf.tf>`
```hcl
resource "google_compute_security_policy" "waf_policy" {
  name        = "waf-policy"
  description = "Web Application Firewall Policy"

  rule {
    action   = "allow"
    priority = "1000"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["10.8.0.0/28", "10.0.0.0/24", "10.0.1.0/28", var.load_balancer_ip] # # vpc, subnet, load balancer and gke master ipv4 cidr range 
      }
    }
    description = "Allow traffic from specific IP range"
  }

  rule {
    action   = "deny(403)"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Deny all other traffic"
  }
}
```
### VPC Access and Firewall
- VPC Access allows Cloud Functions to access MongoDB.
- Firewall applied to all private networks and includes Load Balancer. 
- Automatically create a new database and collection upon inserting a new document. 
- K8s epansion is enabled on storage class, so it could be expanded if needed without downtime or dataloss.

### Mongodb-key: 
#### Use of mongodb-keyfile compliments user and password authentication.
`<modules/docker/mongodb-keyfile>`; `<modules/mongodb/mongodb-keyfile>`
- Command used to create keytfile: `<openssl rand -base64 756 > mongodb-keyfile>`
- You should most definately generate your own, to ensure uniqueness and security of your keyfile.
- Keyfile Owner: The keyfile should be owned by the mongodb. If you’re running MongoDB as a service, this user is typically mongodb or mongod.
- CMD command: we start mongo deamon service with mongod and keyfile as method of authentication.

#### Reasons behind using a keyfile to secure your gke cluster:
The mongodb-keyfile is used for intra-cluster authentication in a MongoDB Replica Set or Sharded Cluster. It serves as a shared secret between the members of the cluster, ensuring that only authorized nodes can join and participate in the cluster. This keyfile is crucial for maintaining the security and integrity of the cluster.

- Authentication Mechanism: 
  - The keyfile is used as a mechanism for internal authentication among the nodes of a MongoDB deployment. When you set up a Replica Set or Sharded Cluster, each node in the cluster needs to authenticate with the others to be trusted and allowed to participate. The keyfile provides a shared secret that all nodes use to authenticate each other.

- Security:
  - The keyfile contains a randomly generated string, which acts as a shared password. All members of the Replica Set or Sharded Cluster must have access to the same keyfile. This ensures that an unauthorized node cannot join the cluster without having the correct keyfile.

- Consistency:
  - The keyfile should be consistent across all members. Any change to the keyfile requires a corresponding update on all nodes in the cluster.

- Permissions:
  - For security reasons, the keyfile should have strict file permissions. Typically, it should be readable only by the user that runs the MongoDB process (often mongodb user in Unix systems). This is why you often see chmod 600 used to set the permissions, allowing only the owner read and write access to the file.

- Format:
  - The keyfile can be a plain text file containing any string of characters, but it is recommended to use a strong, randomly-generated string for security purposes.

When deploying MongoDB in Kubernetes using StatefulSets, the keyfile is typically stored as a Kubernetes Secret and mounted into the containers as a volume. This approach secures the keyfile and makes it easily accessible to the MongoDB instances in your cluster.

### Mongodb-authentication. You can use one of the following or both(this solution make use of both for higher level of security as explain above):
#### mongodb-keyfile used from mongodb replicas and encoded during creation (openssl rand -base64 756 > mongodb-keyfile):
  data = {
    keyfile = "${path.module}/mongodb-keyfile"
  }
##### Use of mongodb-keyfile considerations:
- Keyfile Owner: The keyfile should be owned by the mongodb. If you’re running MongoDB as a service, this user is typically mongodb or mongod.
- When using a keyfile for authentication in a MongoDB replica set, the keyfile itself `<mongodb_keyfile.tf>`is the shared secret used for authentication, not the username and password.
- Our choice for this solution:
- If you want to use both a keyfile and a username/password for authentication, you would need to configure MongoDB to support this. This typically involves creating a MongoDB user that has the necessary roles and privileges, and then using this user’s credentials along with the keyfile when connecting to the MongoDB StatefulSet.

- user and password stored with sensitive = true option:
`<modules/mongodb/mongo_secret.tf>`
```hcl
  data = {
    username = var.mongo_user
    password = var.mongo_password
  }
```
 `<modules/mongodb/variables.tf>`
 ```hcl
variable "mongo_user" {
    default = "mongouser"
    sensitive = true
}

variable "mongo_password" {
    default = "mongopassword"
    sensitive = true    
}
```
#### Use of user and password consideration:
- In Kubernetes secret resource `<modules/mongodb/mongo_secret.tf>`, you’re storing the MongoDB username and password. This is good for scenarios where you want to authenticate with a username and password.
- If you’re using both a keyfile and a username/password for authentication, you would still include the username and password in the connection string. The keyfile does not replace the username and password in the connection string.

### Buildx
- You will need to install this instead of docker build(deprecated): `<https://github.com/docker/buildx#manual-download>`
####  From official docs:
- Docker v23.0 now uses BuildKit by default to build Linux images, and uses the Buildx open_in_new CLI component for docker build.

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
- Cloud Filestore API

### CIDR Range Configuration
#### Ensure the firewall protects all ranges; Confirm that Google Function can access the Kubernetes endpoint to reach MongoDB via the MongoDB URI.

### MongoDB Keyfile for StatefulSet replicas intra-cluster authentication
This is used for higher security and additional authentication.

### MongoDB Connection
Official MongoDB connection string examples: [MongoDB Connection String Examples](https://www.mongodb.com/docs/manual/reference/connection-string/#connection-string-examples)

### Connecting to a VPC Network
For details on connecting Cloud Functions to a VPC, visit [Connecting Cloud Functions to a VPC](https://cloud.google.com/functions/docs/networking/connecting-vpc).

### Serverless VPC Access API
Already configured for this solution.
If you want to configure your own VPC connector in Cloud Functions for internal access, change should follow this valid cidr ranges: 
- VPC Access Connector `ip_cidr_range`: `10.8.0.0/28`

### Backup and recovery
- Daily regional backups enabled at 04:00AM. `<modules/storage_pvc/regional_backup.tf>`

### Additional Configuration Notes
- Using Cloud Run as an API Gateway to GKE. This is more complex and involve additional resources, therefore for this solution VPC Serverless Access connector and cloud function v1 was chosen.
- If `enable_private_endpoint` is set to `true`, ensure proper configuration for accessing the GKE API. Bastion machine or VPN is needed. Not applicable for this solution.
- Update the JSON data for source and destination buckets in Cloud Functions if needed.

## To Do
- Add backup for pvc for disaster recovery -Done with snapshot
- Add alarms for storage - Done `</modules/metrics/metrics_alert>`
- Implement autoscale policy triggered by alarm - this is not possible on Google cloud. expansion is enabled on storage class, so it could be expanded if needed without downtime.
- Add addiitonal monitoring - Done added pvc alert for 80% full and email notification channel
- Add visual Dashboards to represent MongoDB record numbers
- Add indexing based on violence_score record 1-10
- Global vars? Set only once in root:

module "example_module" {
  source = "./modules/example_module"
  module_variable = var.example_variable
}
  
## Successful MongoDB Insertion
Example of a successful record insertion into MongoDB.

Inserted record into MongoDB: {'file_name': 'extra-violent-image.jpg', 'violent_score': <Likelihood.VERY_LIKELY: 5>, '_id': ObjectId('6568081f9948c7742828696f')} 

## Final Remarks
This configuration is currently working and has been tested with various setups. Ensure all the components are correctly configured for seamless integration.

---
For any additional information or queries, please refer to the respective configuration files or raise an issue in the repository.

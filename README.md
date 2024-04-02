# Simetrik GRPC Challenge

## Context

This repository contains the Terraform configuration to generate a HA cluster in AWS. The service consists of a Client-Server application communicating using the Remote Procedure Call protocol. Both applications are implemented in Python using the gRPC framework. Click **[here](https://github.com/ccjaimes/grpc-py-test)** to visit the application repository.

## Architecture

![alt text][architecturepic]

  

[architecturepic]:architecturePic.PNG  "Architecture Diagram"

  

The point of this challenge is to deploy the presented infrastructure as easy & reliable as possible, which Terraform allows. For this instance, it has been decided to deploy our infrastructure in AWS. The idea is that our server is hosted in a Elastic Kubernetes Service cluster with a High Availability configuration, and thats why the worker nodes are defined as a node group in two private subnets in separate Availability Zones, and using Service objects from K8s to expose our Server modules but just internally (for now).

  

Now, to expose our Server to the world, an Application Load Balancer was implemented, which complied greatly with our NAT gateway to allow access for our apps to external services while keeping safe in their private subnets. This option helps us to prevent exposing our nodes hosting the Server pods. In Kubernetes terms, an Ingress service with annotations from AWS ALB allowed us to expose traffic hosted on public subnets in our infrastructure, with these also being hosted in separate Availability Zones.

  

But how do we keep our Server updated continously? With a CodeBuild pipeline! We configured a CI/CD service connected with our Python App repository containing the pipeline steps. This pipeline will take care of testing the codebase, building & pushing the latest docker image to our private ECR registry, and updating our K8s Deployment with the new image.

## Steps to reproduce
 1. Install AWS CLI in your PC. [See how to do it here](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)
 2. Create a new IAM user. Terraform will execute its tasks on behalf of this user. For this step, follow [the guide here](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html#id_users_create_console), and in the ***Set permissions*** section, select the ***Attach policies directly*** option, search in the search bar and check the following policies:
     - AmazonDynamoDBFullAccess
     - AmazonS3FullAccess
     - AmazonVPCFullAccess
 3. Before completing the permissions step, click on ***create policy***, a new tab will open. Open the file ***policies.json*** in the template folder of this repo, and copy its content. This file contains all the necessary permissions the IAM User requires to deploy all resources. Back on the browser, on the new Create Policy tab, click on the JSON option and paste the content of the file from earlier. Then, give a relevant name for the policy and create it. Now back to the IAM user creation tab, search for the policy name you just created and check it as well. Review the user info and create it.
 4. Generate access keys for this new user, and use them to execute ***aws configure*** in your computer. [This guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-authentication-user.html) explains in detail how to do it.
 5. Execute the setup.sh script. To do this, open a terminal from the repository directory and execute ***sh ./templates/setup.sh***. This script will configure the Backend properties for Terraform to handle a remote state hosted in AWS. Now we should be all set to run terraform commands.
 6. In the terminal in the root directory of the repository, we will run all Terraform commands. Lets start with ***terraform init***, which will initialize the state in the AWS S3 Backend, pull versions of Terraform itself and other providers.
 7. Run ***terraform plan*** to review what will be actually deployed. It should create 70 resources in total.
 8. If everything seems in order, run ***terraform apply***, confirm changes and wait for your infrastructure to deploy!
  

## Terraform details

  

The way this Terraform project was implemented was using different modules to keep our project organized and well structured as best practice to keep a clean workflow. Additionally, external modules for multiple AWS services and other integrations have been implemented in our IaC codebase as well. Remember that we use modules to simplify our codebase, as well as reducing multiple unitary resources into reduced but structured amounts of complete services. To get a better idea of this concepts, lets review our own modules:

  

- Network: Our network module takes care of creating/deploying our infrastructure's VPC, subnets and NAT gateways. These components will allow our Load Balancer and EKS components to have a secure network to be hosted on and enable secure traffic between those and the external world. However, we didn't implemented a codeblock for each component, but instead used AWS VPC Terraform module, we passed the configuration parameters and specifications (such as the amount of Availability Zones, NAT gateway replication and DNS support).

- EKS: This module was more complex to implement. There were multiple AWS Terraform modules implemented to fulfill the minimum requirements to not only deploy our EKS cluster but also enable traffic, load balancing and policies/roles for engineers and service accounts to connect, operate and maintain our K8s components. Nevertheless, this was still a prefferable option than creating each resource independently. For example, creating a node group, assign them in the subnets, create policies to link them to the EKS cluster, create policies and assign roles for each component, and even more tasks, seems very complicated but also easier to make human mistakes. Instead, we used a couple parametrized modules in a more organized way to deploy all these components as a whole.

- Deploy: The last module was dedicated to create our Elastic Container Registry, which duty is to keep all our built Docker images available for our EKS cluster to consume. Additionally, the module creates a CodeBuild project, which will act as our CI/CD pipeline platform. The steps our pipeline will do are defined in our Python App repository.
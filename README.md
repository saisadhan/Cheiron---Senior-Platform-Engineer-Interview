# AWS EC2 Microservices Deployment with Terraform

This project demonstrates deploying two microservices (`service1` and `service2`) on AWS EC2 instances using Terraform. The services are containerized with Docker and exposed via an Application Load Balancer (ALB).

---

## Key Features

- EC2 instances running Ubuntu with Docker and Docker Compose.  
- Docker images pulled from AWS ECR.  
- Services exposed through an ALB with path-based routing:  
  - `/service1` → Service 1  
  - `/service2` → Service 2  
- Security groups configured for secure SSH access and ALB traffic.  
- Python verification script to check service health.

---

---

## Prerequisites

- AWS CLI configured with access to your AWS account.  
- Terraform installed.  
- Python 3 installed (for verification script).  
- SSH key pair in AWS (`MyTerraformKey`).

---

## Deployment Overview

- Terraform provisions EC2 instances, security groups, IAM roles, and the Application Load Balancer.  
- EC2 instances are configured to automatically pull Docker images from ECR and run `service1` and `service2` containers.  
- Services are exposed via the ALB using path-based routing for secure and load-balanced access.

---

## Verification

- The Python verification script checks the health of each service endpoint.  
- Services are reachable through the ALB using `/service1` and `/service2` paths.  
- Service responses include a basic JSON message confirming proper deployment.

---

## Notes

- **ALB Security:** Only the ALB is allowed to access service ports (5000, 5001).  
- **SSH Access:** Restricted to your IP for security.  
- **Docker Permissions:** Proper user permissions are configured for Docker operations.  
- **Cleanup:** Terraform can destroy all resources when no longer needed.


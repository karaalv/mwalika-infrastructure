# Mwalika AWS Infrastructure

## Overview

This document provides a high-level overview of the AWS infrastructure used to operate the **Mwalika** system. It outlines the core AWS services used by the platform and describes how they interact to support the application.

The goal of this document is to provide a **concise reference for the deployed infrastructure** rather than a detailed architectural specification.

For a deeper discussion of system design, architectural decisions, and component interactions, refer to the main documentation repository:

**Mwalika Documentation**  
<https://github.com/karaalv/mwalika-documentation>

With the exception of certain global AWS services (such as Route 53), all infrastructure resources are deployed in the **`af-south-1` (Cape Town)** AWS region. This ensures:

- reduced latency for African users
- regional data locality
- alignment with the project's data sovereignty goals

> Certain infrastructure components are intentionally excluded from this document for security reasons. This includes specific Route 53 configurations and some AWS Secrets Manager entries. These are managed directly through the AWS console and are not part of the Terraform configuration in this repository.

## 1. Amazon S3

Two S3 buckets are used within the Mwalika infrastructure.

### `mwalika-terraform-state`

This bucket stores **Terraform state files** used for infrastructure provisioning.

Configuration:

- Versioning enabled
- Server-side encryption enabled
- Restricted IAM access policies

These controls ensure the integrity and security of Terraform state data.

### `mwalika-scripts`

This bucket stores **deployment and operational scripts** used during infrastructure management and service deployment.

Access to this bucket is restricted to authorised IAM principals.

## 2. Route 53

**AWS Route 53** is used for DNS management.

It manages the domain records for the Mwalika services and routes traffic to the appropriate CloudFront distributions.

The primary domains are:

- `mwalika.com` — main frontend application
- `agent.mwalika.com` — agent backend service

The specific DNS record configurations are not included in this document for security reasons.

## 3. AWS Secrets Manager

**AWS Secrets Manager** is used to securely store sensitive configuration values used by the system.

Examples include:

- deployment credentials
- service configuration secrets
- environment variables required by application services

Secrets are protected using IAM access policies to ensure that only authorised services and roles may retrieve them.

## 4. AWS CloudFront

**AWS CloudFront** is used as the primary edge layer for the Mwalika system.

It performs several functions:

- acts as a reverse proxy for backend services
- provides global edge caching
- performs TLS termination
- forwards requests to the EC2 origin

The following CloudFront distributions are configured:

### `mwalika.com`

Routes traffic to the EC2 instance hosting the **frontend application**.

### `agent.mwalika.com`

Routes traffic to the EC2 instance hosting the **agent backend service**.

All public traffic to the system flows through CloudFront before reaching the origin infrastructure.

## 5. Web Application Firewall (WAF)

**AWS WAF** is deployed in front of the CloudFront distributions to protect the system from common web-based attacks.

The following rules are enabled:

### AWS Managed Rule Set

Provides protection against common web exploits such as:

- SQL injection
- cross-site scripting (XSS)
- malicious request patterns
- abnormal request sizes

### AWS IP Reputation List

Blocks traffic originating from IP addresses known to be associated with malicious activity.

### Custom Rate Limiting Rules

Custom rules limit the number of requests from a single IP address in order to mitigate automated abuse and basic denial-of-service attempts.

## 6. AWS CodeBuild

**AWS CodeBuild** is used as part of the CI/CD pipeline for building container images.

CodeBuild builds Docker images for the following services:

- Mwalika Agent
- Mwalika Frontend

After successful builds, images are pushed to **Amazon Elastic Container Registry (ECR)** for deployment.

CodeBuild configuration:

- Architecture: `arm64`
- Instance type: `arm1.medium`
- vCPU: `4`
- Memory: `8 GB`

## 7. Amazon Elastic Container Registry (ECR)

Each service has its own **ECR repository** for storing container images.

Repositories:

- `mwalika-agent`
- `mwalika-frontend`

These repositories store versioned Docker images produced by the CI/CD pipeline.

Access is controlled through IAM policies to ensure only authorised build systems and deployment processes can push or pull images.

## 8. Amazon EC2

The Mwalika application is currently deployed on a **single EC2 instance**.

The instance hosts the system services as containerised workloads running in a Kubernetes cluster managed by **k3s**.

This simplified deployment architecture is intentionally chosen for the MVP in order to:

- minimise operational complexity
- reduce infrastructure overhead
- accelerate development and deployment

Ingress to the EC2 instance is restricted to traffic originating from the CloudFront distributions for:

- `mwalika.com`
- `agent.mwalika.com`

This ensures that all external traffic flows through the CloudFront edge layer before reaching the origin server.

Instance configuration:

- Architecture: `arm64`
- Instance type: `t4g.small`
- vCPU: `2`
- Memory: `2 GB`

## 9. Amazon CloudWatch

**Amazon CloudWatch** is used for infrastructure monitoring and alerting.

CloudWatch monitors:

- EC2 instance health
- system metrics
- service availability

Alerts are configured to notify operators in the event of:

- infrastructure failures
- abnormal resource usage
- service disruptions

This monitoring provides basic operational visibility into the running system.

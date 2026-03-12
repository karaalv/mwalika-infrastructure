# Mwalika Production Flow

## Overview

This document provides a high-level overview of the **production deployment flow** for the Mwalika system. It describes how application services are built, tested, and deployed through the CI/CD pipeline.

The production pipeline is centred around **GitHub Actions workflows**, which automate the build, validation, and deployment processes to ensure consistent and reliable releases.

Application services are built as container images, stored in Amazon ECR, and deployed to the production environment running on AWS infrastructure.

## Containerisation

The Mwalika system is deployed as a set of containerised services. Each service is packaged as a Docker image and stored in **Amazon Elastic Container Registry (ECR)**.

The following services are currently containerised:

- **Mwalika Agent**
- **Mwalika Frontend**

Container images are built specifically for the **`arm64` architecture** to ensure compatibility with the AWS EC2 instance hosting the production environment.

Images are built using **AWS CodeBuild** as part of the CI/CD pipeline and pushed to ECR where they are versioned and stored for deployment.

## Kubernetes Deployment

Production services are deployed as containerised workloads within a **k3s Kubernetes cluster**.

The cluster runs on a **single AWS EC2 instance**, which serves as the origin server for the CloudFront distributions.

Each service is defined using Kubernetes manifests which specify:

- deployment configuration
- container image references
- resource requirements
- environment variables
- networking configuration

This setup provides a lightweight orchestration layer while keeping operational complexity low for the MVP phase of the project.

## Code Environments

Each service supports multiple application environments:

- `development`
- `testing`
- `production`

Environment-specific configuration is managed using separate environment files:

- `.env.development`
- `.env.testing`
- `.env.production`

During deployment, the appropriate configuration is loaded as environment secrets for the Kubernetes deployments. This allows environment-specific behaviour without hardcoding sensitive values or configuration directly into the application code.

## Build and Deployment Automation

Build and deployment tasks are orchestrated through a **Makefile-based workflow**.

The Makefile defines targets for:

- building Docker images
- pushing images to ECR
- deploying services to the Kubernetes cluster

Each service contains a `service.mk` file that defines service-specific configuration and build targets. These files are included by the root Makefile and executed as part of the overall build and deployment process.

## Image Versioning

Docker images are versioned using the **Git commit hash** of the source code that produced the build.

This approach provides several advantages:

- each build is uniquely identifiable
- deployments are traceable to a specific code revision
- rollbacks can be performed reliably

Kubernetes deployment manifests reference the same image tags, ensuring that the exact build produced by the CI pipeline is deployed to the cluster.

## Deployment Flow

The CI/CD pipeline is implemented using **GitHub Actions workflows**.

Two primary workflow triggers are used.

## Push to `main`

Pushing changes to the `main` branch triggers the **test workflow**.

This workflow performs:

- unit tests for affected services
- validation that code changes do not introduce regressions

Only validated code is eligible for release deployment.

## Release `published`

Publishing a GitHub release triggers the **production deployment workflow**.

The deployment pipeline performs the following steps:

1. The `test` workflow is executed to ensure the codebase passes all validation checks.

2. If tests succeed, **AWS CodeBuild** builds Docker images for the affected services.

3. Built images are tagged with the Git commit hash and pushed to **Amazon ECR**.

4. After images are successfully pushed, the pipeline updates the Kubernetes deployment manifests with the new image tags.

5. The updated manifests are applied to the **k3s cluster**, initiating a rolling deployment of the updated services.

6. The pipeline monitors the rollout status to verify that the deployment completes successfully.

If any step fails, the workflow reports the failure and halts the deployment process to prevent partial or inconsistent production updates.

## Notes

The current deployment architecture prioritises **simplicity and reliability for the MVP**. Running the k3s cluster on a single EC2 instance reduces operational overhead while still providing container orchestration and controlled deployment workflows.

Future iterations of the infrastructure may migrate to a more distributed architecture with multiple nodes and additional redundancy as system scale and operational requirements increase.

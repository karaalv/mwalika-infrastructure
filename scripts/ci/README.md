# CI/CD Scripts

This directory contains the scripts used by the CI/CD pipeline
for the Mwalika project. They automate the build and deployment
workflow for backend services.

All scripts in this directory are stored in the project S3
scripts bucket:

**Bucket:** `mwalika-scripts`

The CI pipeline retrieves these scripts from the bucket during
execution.

## Uploading Scripts

Scripts are uploaded to S3 using the upload utility:

```bash
./scripts/upload/upload_ci_scripts.sh
```

Running this script uploads all CI scripts from this directory
to the `mwalika-scripts` bucket.

Run this whenever scripts are added or modified so the CI
pipeline uses the latest versions.

## Available Scripts

### `build_service.sh`

Builds a service Docker image and pushes it to the project's
ECR repository.

Typical responsibilities:

- Build the Docker image for the service
- Tag the image appropriately
- Push the image to Amazon ECR

### `deploy_service.sh`

Deploys a service to the Kubernetes cluster running on the
project infrastructure.

Typical responsibilities:

- Pull the latest image from ECR
- Update the Kubernetes deployment
- Roll out the new version of the service

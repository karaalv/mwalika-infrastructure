# Mwalika MongoDB Infrastructure

## Overview

This document provides a high-level overview of the MongoDB infrastructure used within the **Mwalika** system. MongoDB serves as the **primary operational database** for the application, storing application data, session information, and other persistent state required by the system.

For the MVP phase of the project, the database infrastructure is hosted on **MongoDB Atlas (MongoDB Cloud)** rather than being self-hosted on AWS. Using a managed database service simplifies deployment and operational management while the system is under active development.

Database environments are isolated using separate **MongoDB Atlas projects**, ensuring clear separation between application environments and reducing the risk of accidental interference between systems.

The following environments are maintained:

- `development`
- `testing`
- `production`

Each environment is provisioned as a **separate Atlas project**, containing a single MongoDB cluster dedicated to that environment.

This approach provides:

- isolation of application data between environments
- independent configuration and access controls
- reduced risk of operational mistakes during development and testing

All clusters are deployed in the **Africa (Cape Town) region** to align with the broader infrastructure deployment in AWS `af-south-1`.

## Cluster Environments

### Production Cluster

The production cluster stores live operational data for the Mwalika system.

Configuration:

- **Application:** `mwalika`
- **Project:** `mwalika-production`
- **Cluster Name:** `main`
- **Region:** `AF_SOUTH_1 (Cape Town)`
- **Cluster Tier:** `M0`
- **Network Access:** Restricted to the public IP address of the AWS EC2 instance hosting the production application.

Restricting network access to the EC2 instance ensures that only the application infrastructure can communicate with the production database.

### Development Cluster

The development cluster is used for active development and local testing by developers.

Configuration:

- **Application:** `mwalika`
- **Project:** `mwalika-development`
- **Cluster Name:** `main`
- **Region:** `AF_SOUTH_1 (Cape Town)`
- **Cluster Tier:** `M0`
- **Network Access:** `0.0.0.0/0` (open access)

Open access is permitted in the development environment to simplify development workflows. Authentication credentials are still required for database access.

### Testing Cluster

The testing cluster is used for validating application behaviour prior to production deployment.

Configuration:

- **Application:** `mwalika`
- **Project:** `mwalika-testing`
- **Cluster Name:** `main`
- **Region:** `AF_SOUTH_1 (Cape Town)`
- **Cluster Tier:** `M0`
- **Network Access:** `0.0.0.0/0` (open access)

This environment allows application behaviour to be validated without interacting with production data.

## Notes

MongoDB Atlas is used for the MVP to minimise operational complexity. In a future production deployment, the system may transition to a **self-hosted MongoDB deployment within the AWS infrastructure** to further strengthen data sovereignty and reduce reliance on third-party managed services.

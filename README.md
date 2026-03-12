# Mwalika Infrastructure

**Infrastructure Version:** `1.0.0`

This repository contains the infrastructure code for **Mwalika**, an agentic AI system designed to enhance the Kenyan **eCitizen platform**.

The Mwalika project is organised across multiple repositories. This repository acts as the **central location for all infrastructure-related components**, including:

- Terraform configurations
- Deployment scripts
- Service infrastructure configuration
- Infrastructure documentation

The infrastructure defined here is responsible for provisioning and managing the cloud resources required to run the Mwalika system.

This repository **does not contain the application logic** for the agent or frontend.

For a detailed discussion of the system architecture, design decisions, and the broader Mwalika project, refer to the main documentation repository:

**Mwalika Documentation**  
<https://github.com/karaalv/mwalika-documentation>

That repository provides comprehensive information on:

- system design and technical decisions
- links to all related repositories
- high-level project documentation

## Repository Structure

### `terraform/`

This directory contains the **primary Terraform configuration** used to provision the infrastructure required to run Mwalika.

Resources managed here include:

- compute infrastructure (EC2)
- networking components
- container registries
- DNS configuration
- other supporting cloud resources

The Terraform code defines the deployable infrastructure environment for the system.

### `terraform-state/`

This directory contains the Terraform configuration responsible for **provisioning the remote state backend** used by the main Terraform configuration in `terraform/`.

Separating the state backend configuration ensures that:

- Terraform state is centrally managed
- infrastructure changes are safely tracked
- concurrent updates can be coordinated correctly

### `services/`

This directory contains configuration and operational resources for the services that make up the Mwalika system.

Examples include:

- service deployment configuration
- shared infrastructure definitions
- monitoring and logging configuration
- operational resources related to running the system

### `scripts/`

This directory contains **deployment and operational scripts** used to manage the infrastructure and service lifecycle.

These scripts automate common operational tasks such as:

- deploying services
- updating running infrastructure
- performing maintenance operations

### `docs/`

This directory contains documentation specific to the infrastructure components of the Mwalika system.

It includes:

- operational guides
- infrastructure architecture notes
- best practices for working with the infrastructure stack

## Compatible Services

The infrastructure defined in this repository is designed to support the following Mwalika services:

- **Mwalika Agent**  
  <https://github.com/karaalv/mwalika-agent>  
  `^1.0.0`

- **Mwalika Frontend**  
  <https://github.com/karaalv/mwalika-frontend>  
  `^1.0.0`

These repositories contain the application logic and user-facing components that run on the infrastructure provisioned by this repository.

## Notes

This repository focuses exclusively on **infrastructure and deployment concerns**.

Application logic, AI systems, and frontend implementation are maintained in their respective repositories and documented within the **Mwalika Documentation** repository.

## Licence

This project is licensed under the **Apache License 2.0**.

Copyright © Alvin Karanja

You may use, modify, and distribute this work in accordance with the terms of the Apache 2.0 licence. See the `LICENSE` file for full details.

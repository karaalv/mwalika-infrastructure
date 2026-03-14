# Canonical Service Makefile Template

This directory contains the canonical Makefile implementation used to manage
Mwalika services in CI and deployment workflows.

The Makefile defined here provides standardised targets for building images,
managing Kubernetes secrets, deploying services, and handling rollouts across
environments.

## Usage Model

Each service repository is expected to contain two files at its root:

- `makefile`  
  The canonical Makefile copied from this directory. This file contains all
  shared CI and deployment logic and must remain unchanged.

- `service.mk`  
  A service-owned configuration file that defines service-specific variables.
  All per-service customisation must live in this file.

The canonical Makefile will fail early if `service.mk` is missing or if required
variables are not defined.

## Service Configuration

Service-specific configuration is provided via `service.mk`. The required variables are:

- `SERVICE_NAME`  
  A unique, stable identifier for the service. This value is used for image
  naming, secret naming, and Kubernetes resource identifiers.

No targets or execution logic should be defined in `service.mk`. It is purely for variable definitions.

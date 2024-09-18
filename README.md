# Jenkins CI/CD Pipeline for Docker and Kubernetes Deployment

This repository contains a Jenkins pipeline script that builds a Docker image, pushes it to an Azure Container Registry (ACR), and deploys it to a Kubernetes cluster using Helm.

## Pipeline Overview

The pipeline consists of the following stages:
1. **Docker Build**: Builds a Docker image from the source code.
2. **Upload Image to ACR**: Pushes the Docker image to an Azure Container Registry (ACR).
3. **K8S Deploy**: Deploys the Docker image to a Kubernetes cluster using Helm.

## Environment Variables

- `REGISTRY`: The ACR repository name where the Docker image is pushed.
- `ACR_LOGIN_SERVER`: The login server for the Azure Container Registry.
- `TAG`: The tag for the Docker image, which is set to the Jenkins build ID (`BUILD_ID`).
- `dockerImage`: Placeholder for the Docker image (not used directly in this script).



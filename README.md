# Flox containerd Shim Demo Environment w/ Kind

This repository contains the configuration files needed to create a [Kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker) cluster with Flox runtime support. This cluster can be used to quickly try out the shim locally.

## Prerequisites

### Requirements

Ensure you have either Podman or Docker installed on your system.

Before creating the Kind cluster, you need to authenticate with GitHub Container Registry (GHCR) to pull the node image.

1. **Login to GitHub CLI with required scopes**:
   ```bash
   gh auth login --scopes "gist read:org repo read:packages write:packages"
   ```

2. **Login to Docker/Podman with GHCR**:
   ```bash
   gh auth token | docker login ghcr.io -u <USERNAME> --password-stdin
   ```

   Replace `<USERNAME>` with your GitHub username.

## Setup Instructions

### 1. Create Kind Cluster

Create the Kind cluster using the provided cluster configuration:

```bash
kind create cluster --config=Cluster.yaml
```

This will create a cluster with:
- 1 control-plane node using `ghcr.io/flox/flox-kind:latest`
- 1 worker node using `ghcr.io/flox/flox-kind:latest`

### 2. Apply RuntimeClass

Apply the Flox runtime class configuration:

```bash
kubectl apply -f RuntimeClass.yaml
```

This creates a RuntimeClass named `flox` that enables creating pods that use the Flox shim.

### 3. Deploy Application

Apply the sample deployment:

```bash
kubectl apply -f Deployment.yaml
```

This creates a deployment called `flox-containerd-demo` that:
- Uses the `flox` runtime class
- Runs the `limeytexan/echoip` Flox environment
- Executes the `echoip` command

## Cluster Management

### Using kubectl

Check that your deployment is running:

```bash
kubectl get pods
kubectl logs deployment/flox-containerd-demo
```

### Using k9s (Recommended)

Launch k9s for an interactive cluster dashboard:

```bash
k9s
```

With k9s you can:
- Navigate pods, deployments, and services with arrow keys
- View logs by pressing `l` on a selected pod
- Describe resources by pressing `d`
- Delete resources by pressing `ctrl+d`

## Cleanup

To remove the Kind cluster:

```bash
kind delete cluster
```

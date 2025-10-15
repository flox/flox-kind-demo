# Flox containerd Shim Demo Environment w/ Kind

This repository contains the configuration files needed to create a [Kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker) cluster with Flox runtime support. This cluster can be used to quickly try out the shim locally.

## Prerequisites

### Requirements

Before creating the Kind cluster, you need to authenticate with GitHub Container Registry (GHCR) to pull the node image.

**Authenticate with GitHub and Docker/Podman**:
```bash
just auth <USERNAME>
```

Replace `<USERNAME>` with your GitHub username. This will handle both GitHub CLI authentication and Docker/Podman login to GHCR.

## Setup Instructions

### Start the Demo Environment

Create the complete demo environment with a single command:

```bash
just up
```

This will:
- Create a Kind cluster named `flox-shim` with the provided configuration
- Apply the Flox RuntimeClass configuration
- Deploy the sample application
- Display helpful next steps

The cluster will have:
- 1 control-plane node using `ghcr.io/flox/flox-kind:latest`
- 1 worker node using `ghcr.io/flox/flox-kind:latest`

The deployment creates a pod called `flox-containerd-demo` that:
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
just down
```

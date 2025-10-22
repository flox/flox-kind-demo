# Flox containerd Shim Demo Environment w/ Kind

This repository contains the configuration files needed to create a [Kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker) cluster with Flox runtime support. This cluster can be used to quickly try out the Flox shim locally.

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

The deployment creates:
- A `redis` pod running from `flox/redis` with a corresponding `Service`
- A pod running `quotes-app` that writes some initial quotes to the `redis` at startup, then uses it to serve quotes

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

# Flox Kind Demo Justfile

# Show available recipes
__default:
    @just --list

# Login to GitHub CLI with required scopes
gh-login:
    gh auth login --scopes "gist read:org repo read:packages write:packages"

# Login to Docker/Podman with GHCR (requires GitHub username argument)
docker-login username:
    gh auth token | docker login ghcr.io -u {{ username }} --password-stdin

# Stand up the complete demo environment
up:
    @if command -v podman &> /dev/null; then \
        echo "Podman detected, not using Colima"; \
    else \
        colima start -a x86_64; \
    fi
    kind create cluster --config=Cluster.yaml --name flox-shim
    kubectl apply -f RuntimeClass.yaml
    kubectl apply -f Deployment.yaml
    @echo ""
    @echo "Demo environment is ready!"
    @echo "Try: kubectl get pods"
    @echo "Or:  kubectl logs deployment/flox-containerd-demo"
    @echo "Or:  k9s"

# Shut down and clean up everything
down:
    kind delete cluster --name flox-shim
    @if command -v podman &> /dev/null; then \
        echo "Podman detected, not using Colima"; \
    else \
        colima stop; \
    fi

# Full authentication setup (requires GitHub username argument)
auth username: gh-login (docker-login username)

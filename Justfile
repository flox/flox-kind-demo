# Flox Kind Demo Justfile

# Show available recipes
__default:
    @just --list

# Stand up the complete demo environment
up:
    colima start
    docker pull ghcr.io/flox/flox-kind:latest
    kind create cluster --config=Cluster.yaml --name flox-shim
    kubectl apply -f RuntimeClass.yaml
    # The Flox shim needs a FloxHub token to pull the environments. Copy the
    # host login into a secret that the pods mount at /var/run/secrets/flox.dev.
    @flox auth token > /dev/null 2>&1 || (echo "ERROR: Not authenticated to FloxHub. Run 'flox auth login' first." && exit 1)
    flox auth token | kubectl create secret generic floxhub-token --from-file=floxhub-token=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -f redis.yaml
    kubectl apply -f quotes.yaml
    @echo "Waiting for deployment to be ready. This could take a while..."
    kubectl rollout status deployment/quotes --timeout=8m
    flox services start
    @echo ""
    @echo "Demo environment is ready!"
    @echo "Try: kubectl get pods"
    @echo "Or:  k9s"
    @echo "Or: curl localhost:3000/quotes/0"

# Shut down and clean up everything
down:
    -flox services stop
    kind delete cluster --name flox-shim
    colima stop

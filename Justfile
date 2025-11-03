# Flox Kind Demo Justfile

# Show available recipes
__default:
    @just --list

# Stand up the complete demo environment
up:
    colima start
    kind create cluster --config=Cluster.yaml --name flox-shim
    kubectl apply -f RuntimeClass.yaml
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

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
    @echo ""
    @echo "Demo environment is ready!"
    @echo "Try: kubectl get pods"
    @echo "Or:  k9s"

# Shut down and clean up everything
down:
    kind delete cluster --name flox-shim
    colima stop

# Flox Kind Demo Justfile

# The head of containerd-shim-flox#85 (non-root pods), built into the node image
shim_pr85_rev := "5f8e3c6a92d10c46a5eb951e57d243c8539d2a99"

# Show available recipes
__default:
    @just --list

# Stand up the complete demo environment
up:
    # Fail fast before standing anything up: the shim needs a FloxHub token
    # (see below) and a logged-out user should not get a half-built cluster.
    @flox auth token > /dev/null 2>&1 || (echo "ERROR: Not authenticated to FloxHub. Run 'flox auth login' first." && exit 1)
    colima start
    just image
    kind create cluster --config=Cluster.yaml --name flox-shim
    kubectl apply -f RuntimeClass.yaml
    # Pods cannot reach Docker's DNS through the kind node (it answers the
    # node, not pod traffic), so names outside the cluster, such as
    # api.anthropic.com for the agent sandboxes, would not resolve.
    # CoreDNS asks public resolvers instead.
    kubectl -n kube-system get configmap coredns -o yaml | sed 's|forward \. /etc/resolv.conf|forward . 1.1.1.1 8.8.8.8|' | kubectl apply -f -
    kubectl -n kube-system rollout restart deployment/coredns
    kubectl -n kube-system rollout status deployment/coredns --timeout=2m
    # Copy the host login into a secret that the pods mount at
    # /var/run/secrets/flox.dev so the shim can pull the environments.
    flox auth token | kubectl create secret generic floxhub-token --from-file=floxhub-token=/dev/stdin --dry-run=client -o yaml | kubectl apply -f -
    # agent-sandbox, and the namespace agent-sandbox-k8s launches agents in.
    kubectl apply -f https://github.com/kubernetes-sigs/agent-sandbox/releases/download/v1.0.8/sandbox.yaml
    kubectl -n agent-sandbox-system rollout status deployment/agent-sandbox-controller --timeout=5m
    kubectl create namespace agent-sandbox --dry-run=client -o yaml | kubectl apply -f -
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

# Build the node image locally, with the non-root shim (containerd-shim-flox#85)
image:
    # The shim repository is private: clone it with your GitHub login.
    [ -d .build/containerd-shim-flox ] || gh repo clone flox/containerd-shim-flox .build/containerd-shim-flox
    git -C .build/containerd-shim-flox fetch origin {{shim_pr85_rev}}
    git -C .build/containerd-shim-flox checkout --detach {{shim_pr85_rev}}
    docker build -t flox-kind:pr85 .

# Push the environment the agent sandboxes run (garbas/claude-sandbox)
push-sandbox-env:
    flox push -d envs/claude-sandbox --owner garbas

# Shut down and clean up everything
down:
    -flox services stop
    kind delete cluster --name flox-shim
    colima stop

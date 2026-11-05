# Flox Kind Demo Justfile

# Show available recipes
__default:
    @just --list

# Stand up the complete demo environment
up:
    # Fail fast before standing anything up: the shim needs a FloxHub token
    # (see below) and a logged-out user should not get a half-built cluster.
    @flox auth token > /dev/null 2>&1 || (echo "ERROR: Not authenticated to FloxHub. Run 'flox auth login' first." && exit 1)
    # colima's default 2 GiB VM runs out of memory with two kind nodes and
    # an agent sandbox; the OOM killer takes the VM's sshd, and with it the
    # Docker socket the host reaches the VM through.
    colima start --cpu 4 --memory 8
    docker pull ghcr.io/flox/flox-kind:latest
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
    @echo "Waiting for the deployments to be ready. This could take a while..."
    # redis first: quotes exits when it cannot reach redis, and the shim
    # takes a while to start redis's environment on a fresh node. Started
    # together, quotes restarts until then, rollout status can return in
    # between, and the port-forward below dies with the pod it points at.
    kubectl apply -f redis.yaml
    kubectl rollout status deployment/redis --timeout=8m
    kubectl apply -f quotes.yaml
    kubectl rollout status deployment/quotes --timeout=8m
    flox services start
    @echo ""
    @echo "Demo environment is ready!"
    @echo "Try: kubectl get pods"
    @echo "Or:  k9s"
    @echo "Or: curl localhost:3000/quotes/0"

# Push the environment the agent sandboxes run (garbas/claude-sandbox)
push-sandbox-env:
    flox push -d envs/claude-sandbox --owner garbas

# Shut down and clean up everything
down:
    -flox services stop
    kind delete cluster --name flox-shim
    colima stop

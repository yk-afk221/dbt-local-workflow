#!/bin/bash
# ローカルKubernetes + Argo Workflows セットアップスクリプト

set -e

CLUSTER_NAME="argo-local"
ARGO_VERSION="v3.5.11"

echo "=========================================="
echo "Argo Workflows Local Setup"
echo "=========================================="

# 1. kindのチェック/インストール
echo ""
echo "1. Checking kind..."
if ! command -v kind &> /dev/null; then
    echo "Installing kind..."
    brew install kind
else
    echo "kind is already installed: $(kind --version)"
fi

# 2. クラスタの作成
echo ""
echo "2. Creating Kubernetes cluster..."
if kind get clusters | grep -q "$CLUSTER_NAME"; then
    echo "Cluster '$CLUSTER_NAME' already exists"
    read -p "Delete and recreate? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kind delete cluster --name $CLUSTER_NAME
        kind create cluster --name $CLUSTER_NAME
    fi
else
    kind create cluster --name $CLUSTER_NAME
fi

# 3. コンテキスト設定
echo ""
echo "3. Setting kubectl context..."
kubectl cluster-info --context kind-$CLUSTER_NAME

# 4. Argo Workflowsのインストール
echo ""
echo "4. Installing Argo Workflows..."
kubectl create namespace argo 2>/dev/null || echo "Namespace 'argo' already exists"

kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/${ARGO_VERSION}/quick-start-minimal.yaml

echo "Waiting for Argo pods to be ready..."
kubectl wait --for=condition=Ready pods --all -n argo --timeout=300s

# 5. Argo CLIのチェック/インストール
echo ""
echo "5. Checking Argo CLI..."
if ! command -v argo &> /dev/null; then
    echo "Installing Argo CLI..."
    brew install argo
else
    echo "Argo CLI is already installed: $(argo version --short)"
fi

# 6. Dockerイメージのビルド
echo ""
echo "6. Building dbt Docker image..."
cd "$(dirname "$0")/.."
docker build -t dbt-duckdb:local -f Dockerfile ..

# 7. イメージをkindにロード
echo ""
echo "7. Loading image to kind cluster..."
kind load docker-image dbt-duckdb:local --name $CLUSTER_NAME

# 8. 完了メッセージ
echo ""
echo "=========================================="
echo "Setup completed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Start Argo UI:"
echo "   kubectl -n argo port-forward deployment/argo-server 2746:2746 &"
echo "   open https://localhost:2746"
echo ""
echo "2. Run a workflow:"
echo "   argo submit -n argo templates/dbt-workflow.yaml --watch"
echo ""
echo "3. Run DAG workflow:"
echo "   argo submit -n argo templates/dbt-dag-workflow.yaml --watch"
echo ""

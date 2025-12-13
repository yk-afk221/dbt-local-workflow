#!/bin/bash
# ローカルKubernetes + Argo Workflows セットアップスクリプト
# 共有クラスタ（kubernetes_test）を使用

set -e

CLUSTER_NAME="kind"  # kubernetes_testと共有
CONTEXT_NAME="kind-kind"

echo "=========================================="
echo "Argo Workflows Setup (Shared Cluster)"
echo "=========================================="

# 1. 共有クラスタの確認
echo ""
echo "1. Checking shared Kubernetes cluster..."
if ! kind get clusters | grep -q "^${CLUSTER_NAME}$"; then
    echo "❌ Error: Shared cluster '${CLUSTER_NAME}' not found!"
    echo ""
    echo "Please set up the cluster first using kubernetes_test repository:"
    echo "  cd ~/kubernetes_test"
    echo "  kind create cluster --config kind-config.yaml"
    exit 1
fi
echo "✅ Shared cluster '${CLUSTER_NAME}' found"

# 2. コンテキスト設定
echo ""
echo "2. Setting kubectl context..."
kubectl config use-context $CONTEXT_NAME
kubectl cluster-info --context $CONTEXT_NAME

# 3. Argo Workflowsの確認
echo ""
echo "3. Checking Argo Workflows..."
if ! kubectl get namespace argo &>/dev/null; then
    echo "❌ Argo namespace not found. Installing Argo Workflows..."
    kubectl create namespace argo
    kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.5.11/quick-start-minimal.yaml
    echo "Waiting for Argo pods to be ready..."
    kubectl wait --for=condition=Ready pods --all -n argo --timeout=300s
else
    echo "✅ Argo Workflows is already installed"
    kubectl get pods -n argo
fi

# 4. Argo CLIのチェック/インストール
echo ""
echo "4. Checking Argo CLI..."
if ! command -v argo &> /dev/null; then
    echo "Installing Argo CLI..."
    brew install argo
else
    echo "✅ Argo CLI: $(argo version --short)"
fi

# 5. Dockerイメージのビルド
echo ""
echo "5. Building dbt Docker image..."
cd "$(dirname "$0")/.."
docker build -t dbt-duckdb:local -f Dockerfile ..

# 6. イメージをkindにロード
echo ""
echo "6. Loading image to shared cluster..."
kind load docker-image dbt-duckdb:local --name $CLUSTER_NAME

# 7. 完了メッセージ
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
echo "⚠️  Note: This cluster is shared with kubernetes_test repository"
echo ""

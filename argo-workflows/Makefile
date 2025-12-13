# Argo Workflows ローカルセットアップ用 Makefile
# 共有クラスタ（kubernetes_test）を使用

CLUSTER_NAME := kind
CONTEXT_NAME := kind-kind
IMAGE_NAME := dbt-duckdb:local
ARGO_NAMESPACE := argo
ARGO_VERSION := v3.5.11

.PHONY: help setup check-cluster set-context install-argo check-argo-cli build load ui submit-simple submit-dag clean

# デフォルトターゲット
help:
	@echo "Usage: make <target>"
	@echo ""
	@echo "Setup targets:"
	@echo "  setup          - 全セットアップを実行（check-cluster → install-argo → build → load）"
	@echo "  check-cluster  - 共有Kubernetesクラスタの確認"
	@echo "  set-context    - kubectlコンテキストを設定"
	@echo "  install-argo   - Argo Workflowsをインストール"
	@echo "  check-argo-cli - Argo CLIの確認・インストール"
	@echo ""
	@echo "Build targets:"
	@echo "  build          - dbt Dockerイメージをビルド"
	@echo "  load           - イメージをkindクラスタにロード"
	@echo ""
	@echo "Run targets:"
	@echo "  ui             - Argo UI をポートフォワードで起動"
	@echo "  submit-simple  - シンプルなdbtワークフローを実行"
	@echo "  submit-dag     - DAGワークフローを実行"
	@echo ""
	@echo "Utility targets:"
	@echo "  clean          - 全ワークフローを削除"

# 全セットアップ
setup: check-cluster set-context install-argo check-argo-cli build load
	@echo ""
	@echo "=========================================="
	@echo "Setup completed!"
	@echo "=========================================="
	@echo ""
	@echo "Next steps:"
	@echo "  make ui            - Argo UIを起動"
	@echo "  make submit-simple - シンプルなワークフローを実行"
	@echo "  make submit-dag    - DAGワークフローを実行"
	@echo ""
	@echo "⚠️  Note: This cluster is shared with kubernetes_test repository"

# 共有クラスタの確認
check-cluster:
	@echo "Checking shared Kubernetes cluster..."
	@if ! kind get clusters | grep -q "^$(CLUSTER_NAME)$$"; then \
		echo "❌ Error: Shared cluster '$(CLUSTER_NAME)' not found!"; \
		echo ""; \
		echo "Please set up the cluster first using kubernetes_test repository:"; \
		echo "  cd ~/kubernetes_test"; \
		echo "  kind create cluster --config kind-config.yaml"; \
		exit 1; \
	fi
	@echo "✅ Shared cluster '$(CLUSTER_NAME)' found"

# コンテキスト設定
set-context: check-cluster
	@echo "Setting kubectl context..."
	@kubectl config use-context $(CONTEXT_NAME)
	@kubectl cluster-info --context $(CONTEXT_NAME)

# Argo Workflowsのインストール
install-argo: set-context
	@echo "Checking Argo Workflows..."
	@if ! kubectl get namespace $(ARGO_NAMESPACE) &>/dev/null; then \
		echo "Installing Argo Workflows..."; \
		kubectl create namespace $(ARGO_NAMESPACE); \
		kubectl apply -n $(ARGO_NAMESPACE) -f https://github.com/argoproj/argo-workflows/releases/download/$(ARGO_VERSION)/quick-start-minimal.yaml; \
		echo "Waiting for Argo pods to be ready..."; \
		kubectl wait --for=condition=Ready pods --all -n $(ARGO_NAMESPACE) --timeout=300s; \
	else \
		echo "✅ Argo Workflows is already installed"; \
		kubectl get pods -n $(ARGO_NAMESPACE); \
	fi

# Argo CLIのチェック/インストール
check-argo-cli:
	@echo "Checking Argo CLI..."
	@if ! command -v argo &> /dev/null; then \
		echo "Installing Argo CLI..."; \
		brew install argo; \
	else \
		echo "✅ Argo CLI: $$(argo version --short)"; \
	fi

# Dockerイメージのビルド
build:
	@echo "Building dbt Docker image..."
	docker build -t $(IMAGE_NAME) -f Dockerfile ..

# イメージをkindにロード
load: check-cluster
	@echo "Loading image to shared cluster..."
	kind load docker-image $(IMAGE_NAME) --name $(CLUSTER_NAME)
	@echo "✅ Image loaded successfully"

# Argo UI をポートフォワードで起動
ui:
	@echo "Starting Argo UI..."
	@pkill -f "port-forward.*2746" 2>/dev/null || true
	@kubectl -n $(ARGO_NAMESPACE) port-forward deployment/argo-server 2746:2746 &
	@sleep 2
	@echo "✅ Argo UI available at https://localhost:2746"
	@open https://localhost:2746

# シンプルなdbtワークフローを実行
submit-simple:
	@echo "Submitting simple dbt workflow..."
	argo submit -n $(ARGO_NAMESPACE) templates/dbt-workflow.yaml --watch

# DAGワークフローを実行
submit-dag:
	@echo "Submitting DAG workflow..."
	argo submit -n $(ARGO_NAMESPACE) templates/dbt-dag-workflow.yaml --watch

# 全ワークフローを削除
clean:
	@echo "Deleting all workflows..."
	argo delete -n $(ARGO_NAMESPACE) --all
	@echo "✅ All workflows deleted"

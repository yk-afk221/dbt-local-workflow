# Argo Workflows ローカルサンプル

DuckDB + dbt ワークフローをArgo Workflowsでローカル実行するサンプルです。

## 前提条件

- Docker Desktop
- kubectl
- Homebrew (macOS)
- **kubernetes_test リポジトリのkindクラスタ（共有）**

## クイックスタート

### 1. 共有Kubernetesクラスタの使用

このプロジェクトは `kubernetes_test` リポジトリと同じkindクラスタ（`kind`）を共有します。

```bash
# クラスタが起動しているか確認
kind get clusters
# 出力に "kind" が含まれていればOK

# コンテキストを切り替え
kubectl config use-context kind-kind

# Argo Workflowsが動作しているか確認
kubectl get pods -n argo
```

> **Note**: クラスタが存在しない場合は、`kubernetes_test` リポジトリのREADMEを参照してセットアップしてください。

### 2. Argo CLIのインストール（未インストールの場合）

```bash
brew install argo
```

### 3. Argo UI へのアクセス

```bash
# ポートフォワード
kubectl -n argo port-forward deployment/argo-server 2746:2746 &

# ブラウザでアクセス
open https://localhost:2746
```

### 3. dbt Dockerイメージのビルド

```bash
cd argo-workflows

# ローカルでイメージをビルド
docker build -t dbt-duckdb:local -f Dockerfile ..

# kindクラスタにイメージをロード（共有クラスタ）
kind load docker-image dbt-duckdb:local --name kind
```

### 4. ワークフローの実行

```bash
# シンプルなdbt runワークフロー
argo submit -n argo templates/dbt-workflow.yaml --watch

# DAGワークフロー（staging → marts）
argo submit -n argo templates/dbt-dag-workflow.yaml --watch

# パラメータ付き実行
argo submit -n argo templates/dbt-workflow.yaml \
  -p dbt-command="dbt test --target dev" \
  --watch
```

## ディレクトリ構成

```
argo-workflows/
├── README.md                    # このファイル
├── Dockerfile                   # dbt + DuckDB イメージ
├── templates/
│   ├── dbt-workflow.yaml        # シンプルなdbt実行
│   ├── dbt-dag-workflow.yaml    # DAG形式（staging→marts）
│   └── dbt-cron-workflow.yaml   # 定期実行（CronWorkflow）
└── scripts/
    └── setup-local-k8s.sh       # セットアップスクリプト
```

## ワークフローテンプレート

### シンプル実行 (dbt-workflow.yaml)

```yaml
# dbt build を実行
argo submit -n argo templates/dbt-workflow.yaml --watch
```

### DAG実行 (dbt-dag-workflow.yaml)

```
seed → staging → marts → test
```

### 定期実行 (dbt-cron-workflow.yaml)

```bash
# CronWorkflowを登録
kubectl apply -f templates/dbt-cron-workflow.yaml -n argo

# 確認
argo cron list -n argo
```

## コマンドリファレンス

### Argo CLI

```bash
# ワークフロー一覧
argo list -n argo

# ワークフローのログ確認
argo logs -n argo <workflow-name>

# ワークフローの詳細
argo get -n argo <workflow-name>

# ワークフローの削除
argo delete -n argo <workflow-name>

# 全ワークフロー削除
argo delete -n argo --all
```

### クラスタ管理

```bash
# ⚠️ 共有クラスタのため、削除時は注意してください
# kubernetes_test のワークフローにも影響します

# クラスタ停止（kubernetes_testと共有）
kind delete cluster --name kind

# クラスタ再作成はkubernetes_testのREADMEを参照
```

## トラブルシューティング

### イメージが見つからない

```bash
# kindにイメージをロードし直す（共有クラスタ）
kind load docker-image dbt-duckdb:local --name kind
```

### Podがpendingのまま

```bash
# リソース状況確認
kubectl describe pod -n argo <pod-name>

# ノード状況確認
kubectl get nodes
kubectl describe node
```

### Argo UIにアクセスできない

```bash
# ポートフォワードを再実行
pkill -f "port-forward.*2746"
kubectl -n argo port-forward deployment/argo-server 2746:2746 &
```

## 本番環境への移行

このサンプルを本番Argo Workflowsに移行する場合:

1. **イメージレジストリ**: `dbt-duckdb:local` → ECR/GCRのイメージに変更
2. **dbt adapter**: `dbt-duckdb` → `dbt-bigquery` に変更
3. **認証**: Workload Identity / Service Account設定を追加
4. **Secrets**: BigQuery認証情報をK8s Secretsで管理

```yaml
# 本番用イメージ例
image: gcr.io/your-project/dbt-bigquery:v1.0.0

# 認証情報のマウント
volumeMounts:
  - name: gcp-credentials
    mountPath: /secrets
volumes:
  - name: gcp-credentials
    secret:
      secretName: bigquery-sa-key
```

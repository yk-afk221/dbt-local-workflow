#!/usr/bin/env python3
"""
ローカル環境のDuckDBにdev_raw/prd_rawスキーマをセットアップするスクリプト

このスクリプトは、seedsディレクトリのCSVファイルを読み込み、
DuckDBの dev_raw と prd_raw スキーマにデータを投入します。

Usage:
    python scripts/setup_local_env.py

BigQuery環境との対応:
    - dev_raw: テスト用データ（本番データのサブセット）
    - prd_raw: 本番データ（このサンプルでは同じデータを使用）
"""

import duckdb
import os
from pathlib import Path


def setup_schemas(db_path: str = "sample.duckdb"):
    """
    DuckDBにdev_raw/prd_rawスキーマを作成し、seedsデータを投入

    Args:
        db_path: DuckDBファイルのパス
    """
    # スクリプトのディレクトリからの相対パスを解決
    script_dir = Path(__file__).parent.parent
    seeds_dir = script_dir / "seeds"
    db_full_path = script_dir / db_path

    print(f"Setting up DuckDB at: {db_full_path}")

    # DuckDBに接続
    con = duckdb.connect(str(db_full_path))

    # スキーマを作成
    schemas = ["dev_raw", "prd_raw"]
    for schema in schemas:
        con.execute(f"CREATE SCHEMA IF NOT EXISTS {schema}")
        print(f"Created schema: {schema}")

    # CSVファイルを読み込んでテーブルを作成
    csv_files = list(seeds_dir.glob("raw_*.csv"))

    for csv_file in csv_files:
        # raw_customers.csv -> customers
        table_name = csv_file.stem.replace("raw_", "")

        for schema in schemas:
            full_table_name = f"{schema}.{table_name}"

            # テーブルを作成（存在すれば上書き）
            con.execute(f"""
                CREATE OR REPLACE TABLE {full_table_name} AS
                SELECT * FROM read_csv_auto('{csv_file}')
            """)

            # 行数を確認
            result = con.execute(f"SELECT COUNT(*) FROM {full_table_name}").fetchone()
            print(f"Created table: {full_table_name} ({result[0]} rows)")

    # 開発環境用にデータを減らす例（オプション）
    # 本番ではprd_rawに全データ、dev_rawにサブセットを入れる
    # ここでは同じデータを使用

    con.close()
    print("\nSetup completed successfully!")
    print(f"\nYou can now run:")
    print(f"  dbt seed --target dev   # seedsをロード")
    print(f"  dbt run --target dev    # devモードで実行（dev_rawを参照）")
    print(f"  dbt run --target prd    # prdモードで実行（prd_rawを参照）")


def show_schema_info(db_path: str = "sample.duckdb"):
    """
    DuckDBのスキーマ情報を表示

    Args:
        db_path: DuckDBファイルのパス
    """
    script_dir = Path(__file__).parent.parent
    db_full_path = script_dir / db_path

    if not db_full_path.exists():
        print(f"Database not found: {db_full_path}")
        print("Run setup first: python scripts/setup_local_env.py")
        return

    con = duckdb.connect(str(db_full_path))

    print("\n=== Schema Information ===\n")

    # スキーマ一覧
    schemas = con.execute("""
        SELECT schema_name
        FROM information_schema.schemata
        WHERE schema_name NOT IN ('information_schema', 'pg_catalog')
        ORDER BY schema_name
    """).fetchall()

    for (schema_name,) in schemas:
        print(f"Schema: {schema_name}")

        # テーブル一覧
        tables = con.execute(f"""
            SELECT table_name
            FROM information_schema.tables
            WHERE table_schema = '{schema_name}'
            ORDER BY table_name
        """).fetchall()

        for (table_name,) in tables:
            count = con.execute(f"SELECT COUNT(*) FROM {schema_name}.{table_name}").fetchone()[0]
            print(f"  - {table_name} ({count} rows)")

        print()

    con.close()


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "info":
        show_schema_info()
    else:
        setup_schemas()

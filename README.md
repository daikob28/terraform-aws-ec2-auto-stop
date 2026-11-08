# Terraform AWS EC2 Auto Stopper

Terraform (IaC) を用いて、AWS Lambda と Amazon EventBridge による開発・検証用EC2インスタンスの夜間自動停止システムを一括構築・管理するインフラ自動化プロジェクトです。

## 🛠 概要 (Overview)
第2弾で作成した「LambdaによるEC2自動停止スクリプト」の仕組みをベースに、インフラストラクチャをコードとして管理（IaC）することで、再現性と保守性を高めた構成です。
手動でのコンソール操作を排除し、コマンド一つでインフラ環境のデプロイや削除が可能になっています。

## ✨ 主な構成リソース (Infrastructure Resources)
- **AWS Lambda:** EC2のタグを検出し、稼働中の対象インスタンスを停止するPythonスクリプトの実行基盤。
- **IAM Role & Policy:** 最小権限の原則に基づき、EC2の参照・停止およびCloudWatch Logsへの書き込み権限を付与。
- **Amazon EventBridge:** 毎日日本時間の22:00（UTC 13:00）にLambdaを起動する定期実行スケジュール。

## 📂 リポジトリ構成 (Repository Structure)
```text
terraform-aws-ec2-auto-stop/
├── main.tf             # インフラのメイン定義（Lambda, IAM, EventBridge等）
├── variables.tf        # 変数定義（リージョン設定など）
├── lambda_function.py  # 自動停止を行うPythonスクリプト
└── README.md           # 説明書（本書）
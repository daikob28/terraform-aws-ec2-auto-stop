# 1. AWSプロバイダーの設定
provider "aws" {
  region = var.aws_region
}

# 2. Lambda実行用IAMロールの信頼ポリシー（Assume Role）
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# 3. Lambda実行用IAMロールの作成
resource "aws_iam_role" "lambda_exec_role" {
  name               = "ec2_stopper_lambda_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# 4. 最小権限ポリシーの定義（EC2の参照・停止 ＋ CloudWatch Logs出力）
data "aws_iam_policy_document" "lambda_permissions" {
  statement {
    sid       = "AllowEC2ReadAndStop"
    effect    = "Allow"
    actions   = [
      "ec2:DescribeInstances",
      "ec2:StopInstances"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "AllowCloudWatchLogs"
    effect    = "Allow"
    actions   = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

# 5. IAMロールへポリシーをアタッチ
resource "aws_iam_role_policy" "lambda_policy_attachment" {
  role   = aws_iam_role.lambda_exec_role.name
  policy = data.aws_iam_policy_document.lambda_permissions.json
}

# 6. Lambda関数の定義（Pythonスクリプトのデプロイ）
# ※あらかじめスクリプトを圧縮した ZIP ファイル（lambda_function.zip）を用意しておきます
resource "aws_lambda_function" "ec2_stopper" {
  filename         = "lambda_function.zip"
  function_name    = "ec2_auto_stopper"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = filebase64sha256("lambda_function.zip")
}

# 7. Amazon EventBridge（毎日22:00 JST / 13:00 UTC に実行）
resource "aws_cloudwatch_event_rule" "every_night" {
  name                = "stop-ec2-every-night"
  description         = "Trigger EC2 auto-stopper lambda every night at 22:00 JST"
  schedule_expression = "cron(0 13 * * ? *)"
}

# 8. EventBridgeのターゲットにLambdaを指定
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.every_night.name
  target_id = "StopEC2Lambda"
  arn       = aws_lambda_function.ec2_stopper.arn
}

# 9. EventBridgeからLambdaを起動するパーミッションの付与
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_stopper.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_night.arn
}
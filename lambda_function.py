import boto3
import os

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    
    # 停止対象とするタグ条件（例: Environment = Development）
    # 必要に応じて環境変数等から受け取ることも可能です
    filters = [
        {
            'Name': 'tag:Environment',
            'Values': ['Development']
        },
        {
            'Name': 'instance-state-name',
            'Values': ['running']
        }
    ]
    
    # 条件に一致するインスタンスを取得
    response = ec2.describe_instances(Filters=filters)
    instance_ids = []
    
    for reservation in response['Reservations']:
        for instance in reservation['Instances']:
            instance_ids.append(instance['InstanceId'])
            
    if instance_ids:
        print(f"Stopping instances: {instance_ids}")
        ec2.stop_instances(InstanceIds=instance_ids)
        return {
            'statusCode': 200,
            'body': f"Successfully stopped instances: {instance_ids}"
        }
    else:
        print("No matching running instances found to stop.")
        return {
            'statusCode': 200,
            'body': "No matching running instances found."
        }
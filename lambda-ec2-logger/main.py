import boto3
import json
import os

def lambda_handler(event, context):
    ec2 = boto3.client('ec2')
    sns = boto3.client('sns')
    topic_arn = os.environ['SNS_TOPIC_ARN']

    for record in event['Records']:
        try:
            alarm_msg = json.loads(record['Sns']['Message'])
            trigger = alarm_msg.get("Trigger", {})
            instance_id = next(
                (dim["value"] for dim in trigger.get("Dimensions", []) if dim["name"] == "InstanceId"), None
            )

            if not instance_id:
                print("No instance ID found in alarm message.")
                continue

            # Fetch EC2 details
            instance = ec2.describe_instances(InstanceIds=[instance_id])['Reservations'][0]['Instances'][0]
            name_tag = next((tag['Value'] for tag in instance.get('Tags', []) if tag['Key'] == 'Name'), 'NoName')
            public_ip = instance.get('PublicIpAddress', 'No Public IP')

            # Get console output
            console_out = ec2.get_console_output(InstanceId=instance_id, Latest=True)
            logs = console_out.get('Output', '(No logs found)').strip()

            # Format email message
            email_subject = f"EC2 Status Check Failed: {name_tag} ({instance_id} !!!!!!)"
            email_body = f"""
EC2 Status Check Failed

Instance ID: {instance_id}
Instance Name: {name_tag}
Public IP: {public_ip}

System Logs:
{logs[:1000]}  # SNS has a max message size of 262144 bytes
"""

            print("Sending formatted alert to SNS...")
            sns.publish(
                TopicArn=topic_arn,
                Subject=email_subject,
                Message=email_body
            )

        except Exception as e:
            print(f"Error processing record: {e}")

    return {"status": "done"}

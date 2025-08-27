# EC2 Health Monitor

A Terraform-based infrastructure solution that automatically monitors EC2 instances for status check failures and sends detailed alerts via email notifications.

##  Features

- **Automatic Discovery**: Finds all running EC2 instances in the specified AWS region
- **CloudWatch Monitoring**: Sets up status check alarms for each instance
- **Email Notifications**: Sends alerts to multiple email addresses when status checks fail
- **Detailed Logging**: Includes EC2 console output in alert messages for troubleshooting
- **Serverless Architecture**: Uses AWS Lambda for processing and SNS for notifications

##  Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed (version 0.12+)
- AWS account with permissions for EC2, CloudWatch, SNS, Lambda, and IAM

##  Architecture

```
EC2 Instances → CloudWatch Alarms → SNS Topic → Lambda Function → Email Alerts
```

The solution consists of:
- **CloudWatch Alarms**: Monitor EC2 status checks every 30 minutes
- **SNS Topic**: Central notification hub
- **Lambda Function**: Processes alarms and enriches alerts with instance details
- **Email Subscriptions**: Deliver formatted alerts to specified recipients

##  Project Structure

```
ec2-health-monitor/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Input variables
├── outputs.tf              # Output values
└── lambda-ec2-logger/
    ├── main.py            # Lambda function code
    └── function.zip       # Lambda deployment package
```

##  Configuration

### 1. AWS Region Configuration

The code will find all "running" instances in a region specified in line 1 of `main.tf`:

```hcl
variable "region" {
    default = "ap-south-1"  # Modify this to your desired region
}
```

### 2. Email Alert Configuration

For each region, you have to setup cloudwatch alarms per ec2 instance, setup a common topic which will email to "multiple" emails. Modify email list in `variables.tf`:

```hcl
variable "alert_email" {
    description = "Email addresses to receive EC2 status check alerts"
    type        = list(string)
    default     = [
        "shiva@pesuventurelabs.com",
        "analyst@pesuventurelabs.com"
    ]
}
```

**Note**: Recipients will receive email subscription confirmation requests from AWS SNS.

## Monitoring Details

- **Check Frequency**: The cloudwatch alarm will check once every 30 minutes as seen in `main.tf` (1800 seconds in line 30)
- **Trigger Condition**: StatusCheckFailed > 0
- **Instance Discovery**: Automatically finds all instances with state "running"
- **Alarm Naming**: `EC2_StatusCheckFailed-{InstanceName} ({InstanceID})`

## Alert Format

When a status check fails, recipients receive an email with:

```
Subject: EC2 Status Check Failed: {InstanceName} ({InstanceID}) !!!!!!

Body:
EC2 Status Check Failed

Instance ID: i-1234567890abcdef0
Instance Name: WebServer-Prod
Public IP: 54.123.456.789

System Logs:
[First 1000 characters of console output]
```

##  Deployment Instructions

### Step 1: Clone and Configure

```bash
git clone <repository-url>
cd ec2-health-monitor
```

### Step 2: Modify Configuration

Edit `variables.tf` to set your desired:
- AWS region
- Email addresses for alerts

### Step 3: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply
```

### Step 4: Confirm Email Subscriptions

Check your email for SNS subscription confirmation messages and click "Confirm subscription" for each email address.

## Lambda Function Modifications

If you modify `main.py` of the `lambda-ec2-logger` function:

1. Edit `lambda-ec2-logger/main.py`
2. Run `zip function.zip main.py` inside `lambda-ec2-logger` folder to zip it
3. Run `terraform apply` to apply everything

## Outputs

After deployment, Terraform provides information about monitored instances:

```
instance_info = {
  "i-1234567890abcdef0" = {
    name = "WebServer-Prod"
    public_ip = "54.123.456.789"
  }
  "i-0987654321fedcba0" = {
    name = "DatabaseServer"
    public_ip = "54.987.654.321"
  }
}
```

## IAM Permissions

The Lambda function requires the following permissions:
- `ec2:DescribeInstances` - Get instance details
- `ec2:GetConsoleOutput` - Fetch system logs
- `sns:Publish` - Send notifications
- `logs:CreateLogGroup`, `logs:CreateLogStream`, `logs:PutLogEvents` - CloudWatch logging

## Important Notes

1. **Regional Scope**: The solution only monitors instances in the specified region
2. **Instance State**: Only monitors instances in "running" state
3. **Email Confirmation**: Recipients must confirm SNS subscriptions to receive alerts
4. **Cost Consideration**: Each instance creates a CloudWatch alarm (charges apply)
5. **Message Size**: Alert messages are limited to 1000 characters of console output due to SNS limits

## Cleanup

To remove all resources:

```bash
terraform destroy
```

## Tags

All resources are tagged with:
- `Project`: EC2HealthMonitor
- `Environment`: prod
- `Owner`: shivaedu33@gmail.com

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.

---

**⚠️ Remember**: Always review and test infrastructure changes in a development environment before applying to production!

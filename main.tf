provider "aws" {
    region = var.region
}

# get instance ID's

data "aws_instances" "all" {
    filter {
        name = "instance-state-name"
        values = ["running"]
    }
}

# get instance name & IP wrt ID's

data "aws_instance" "details" {
    for_each = toset(data.aws_instances.all.ids)
    instance_id = each.key
}

# create cloudwatch metric alarms for ec2_status_check 

 resource "aws_cloudwatch_metric_alarm" "ec2_status_check" {
     for_each = data.aws_instance.details
 
     alarm_name          = "EC2_StatusCheckFailed-${lookup(each.value.tags, "Name", "NoName")} (${each.key})"
     comparison_operator = "GreaterThanThreshold"
     evaluation_periods  = 1
     metric_name         = "StatusCheckFailed"
     namespace           = "AWS/EC2"
     period              = 1800
     statistic           = "Maximum"
     threshold           = 0
     alarm_description   = "Status check failed for instance ${each.key} (${lookup(each.value.tags, "Name", "NoName")})"
     dimensions = {
         InstanceId = each.key
     }
 
   alarm_actions = [aws_lambda_function.ec2_alert_handler.arn] # this line will email to the already subscribed emails via topics thats done below
 }
 
# Create the AWS aws_sns_topic

resource "aws_sns_topic" "ec2_alerts" {
    name = "ec2-status-check-alerts"
}

# connect topic to subsscription emails.. VVIP

resource "aws_sns_topic_subscription" "emails" {
  for_each  = toset(var.alert_email)
  topic_arn = aws_sns_topic.ec2_alerts.arn
  protocol  = "email"
  endpoint  = each.key
}

##  Below everything is for Lambda 

# create IAM Roles & Policy for Lambda function 

resource "aws_iam_role" "lambda_role" {
  name = "lambda_ec2_log_fetcher"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "lambda_log_fetch_policy"
  role = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:DescribeInstances",
          "ec2:GetConsoleOutput"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = "*" # or restrict to your topic ARN
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

# Now lets deploy the Lambda function written in lambda-ec2-logger 

resource "aws_lambda_function" "ec2_alert_handler" {
  depends_on       = [aws_sns_topic.ec2_alerts]
  filename         = "lambda-ec2-logger/function.zip"
  function_name    = "ec2_status_check_handler"
  role             = aws_iam_role.lambda_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.12"
  source_code_hash = filebase64sha256("lambda-ec2-logger/function.zip")
  timeout          = 30

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.ec2_alerts.arn
    }
  }

  tags = {
    Project     = "EC2HealthMonitor"
    Environment = "prod"
    Owner       = "shivaedu33@gmail.com"
  }
}


# Now we connect the SNS topics to Lambda

resource "aws_sns_topic_subscription" "lambda_sub" {
  topic_arn = aws_sns_topic.ec2_alerts.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.ec2_alert_handler.arn
}

resource "aws_lambda_permission" "allow_sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ec2_alert_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.ec2_alerts.arn
}




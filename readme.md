1. The code will find all "running " instances in a region specified in line 1 of main.tf 
2. For each region, u have to setup cloudwatch alarms per ec2 instance, setup a common topic which will email to " multiple " emails. Modify email list in " variables.tf "
3. the cloudwatch alarm will check once every 30 minutes as seen in main.tf (1800 seconds in line 30)
4. If you modify main.py of the lambda-ec2-logger function, run zip function.zip main.py inside lambda-ec2-logger folder to zip it.
5. run terraform apply to apply everything 

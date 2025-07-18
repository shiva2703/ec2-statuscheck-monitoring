# variables for AWS region
# This variable sets the AWS region where the resources will be created & modified.
variable "region" {
    default = "ap-south-1"
}

# variables for alert email
# Modify the email list to add or remove emails as needed
# This will be used to send alerts for EC2 status checks

variable "alert_email" {
    description = "Email addresses to receive EC2 status check alerts"
    type        = list(string)
    default    = ["shiva@pesuventurelabs.com", "analyst@pesuventurelabs.com"]   

}

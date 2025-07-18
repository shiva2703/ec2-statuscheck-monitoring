#output "ec2_ids" {
#    value = data.aws_instances.all.ids
#}


# Output & display list of all instances ID, name and public_IP for instances in region specified in variables.tf
output "instance_info" {
    value = {
        for id, instance in data.aws_instance.details :
        id => {
        name = lookup(instance.tags, "Name","NoName")
        public_ip = instance.public_ip
        }
    }
}

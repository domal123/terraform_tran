variable "subnet_public" {
    default= "subnet-045497283f6e774b6"
}

variable "server_port" {
    default=8080
}

output "instance_private_ip" {
    value="${aws_instance.gdomal1.private_ip}"
}

output "instance_public_ip" {
    value="${aws_instance.gdomal1.public_ip}"
}

output "elbdnsname" {
    value="${aws_elb.aelbgd.dns_name}"
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "gdomal1" {
    ami = "ami-0a313d6098716f372"
    instance_type= "t2.micro"
    subnet_id= "${var.subnet_public}"
}

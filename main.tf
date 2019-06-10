provider "aws" {
    region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
    bucket = "terraform-state-gdomal"

    versioning {
        enabled = true
    }

    lifecycle {
        prevent_destroy = true
    }
}

terraform {
    backend "s3" {
        bucket = "terraform-state-gdomal"
        key = "domal/tf-gdomal.tfstate"
        region = "us-east-1"
    }
}

resource "aws_instance" "gdomal1" {
    ami = "ami-0a313d6098716f372"
    instance_type= "t2.micro"
    subnet_id= "${var.subnet_public}"
    user_data = <<-EOF
            #!/bin/bash
            echo "Hello, World" > index.html
            nohup busybox httpd -f -p "${var.server_port}" &
            EOF
    tags {
        Name = "gdomal1"
    }
    vpc_security_group_ids = ["${aws_security_group.allow_tls.id}"]
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  vpc_id      = "vpc-0bd376fe9558476e9"
  description = "Allow TLS inbound traffic"


  ingress {
    # TLS (change to whatever ports you need)
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "gdomal1" {
    image_id= "ami-0a313d6098716f372"
    instance_type="t2.micro"
    security_groups=["${aws_security_group.allow_tls.id}"]
        user_data = <<-EOF
            #!/bin/bash
            echo "Hello, World" > index.html
            nohup busybox httpd -f -p "${var.server_port}" &
            EOF
    lifecycle {
        create_before_destroy=true
    }
}

data "aws_availability_zones" "available" {

}

resource "aws_autoscaling_group" "asg" {
    launch_configuration="${aws_launch_configuration.gdomal1.id}"
    availability_zones=["${data.aws_availability_zones.available.names}"]
    vpc_zone_identifier=["subnet-045497283f6e774b6", "subnet-0bb2b69f0367ee463" ]
    load_balancers=["${aws_elb.aelbgd.name}"]
    health_check_type   ="ELB"
    min_size=1
    max_size=2
}

resource "aws_elb" "aelbgd" {
    name="aelbgd-first"
#    availability_zones=["us-east-1a","us-east-1b"]
    subnets=["subnet-045497283f6e774b6", "subnet-0bb2b69f0367ee463" ]
    security_groups=["${aws_security_group.allow_elb.id}"]
    listener {
        lb_port=80
        lb_protocol="http"
        instance_port="${var.server_port}"
        instance_protocol="http"
    }
    health_check{
        healthy_threshold=2
        unhealthy_threshold=2
        timeout=3
        interval=30
        target="HTTP:${var.server_port}/"
    }
}

resource "aws_security_group" "allow_elb" {
  name        = "allow_elb"
  vpc_id      = "vpc-0bd376fe9558476e9"
  description = "Allow TLS inbound traffic"


  ingress {
    # TLS (change to whatever ports you need)
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # Please restrict your ingress to only necessary IPs and ports.
    # Opening to 0.0.0.0/0 can lead to security vulnerabilities.
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port=0
      to_port=0
      protocol="-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

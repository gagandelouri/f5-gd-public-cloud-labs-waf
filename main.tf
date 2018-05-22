/*
terraform {
  required_version = ">=0.9.6",
  backend "s3" {
    key    = "terraform.tfstate"
  }
}
*/
provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_vpc" "terraform-vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"

  tags {
    Name = "terraform_${var.emailid}"
  }

  #With timestamp
  /*
    tags {
    Name = "terraform_${var.emailid}_${timestamp()}"
  }
  */
}

resource "aws_subnet" "f5-management-a" {
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  cidr_block              = "10.0.101.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "${var.aws_region}a"

  tags {
    Name = "management"
  }
}

resource "aws_subnet" "f5-management-b" {
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  cidr_block              = "10.0.102.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "${var.aws_region}b"

  tags {
    Name = "management"
  }
}

resource "aws_subnet" "public-a" {
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.aws_region}a"

  tags {
    Name = "public"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  cidr_block              = "10.0.100.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.aws_region}a"

  tags {
    Name = "private"
  }
}

resource "aws_subnet" "public-b" {
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.aws_region}b"

  tags {
    Name = "public"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  cidr_block              = "10.0.200.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.aws_region}b"

  tags {
    Name = "private"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"

  tags {
    Name = "internet-gateway"
  }
}

resource "aws_route_table" "rt1" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags {
    Name = "Default"
  }
}

resource "aws_main_route_table_association" "association-subnet" {
  vpc_id         = "${aws_vpc.terraform-vpc.id}"
  route_table_id = "${aws_route_table.rt1.id}"
}

/*
resource "aws_launch_configuration" "example" {
  image_id        = "ami-40d28157"
  instance_type   = "t2.micro"
  key_name        = "${var.aws_keypair}"
  security_groups = ["${aws_security_group.instance.id}"]

  }

  user_data = <<-EOF
              #!/bin/bash
              az = `curl 169.254.169.254/latest/meta-data/placement/availability-zone`
              echo "Hello, World from $az" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example.id}"
  vpc_zone_identifier  = ["${aws_subnet.public-a.id}", "${aws_subnet.public-b.id}"]

  load_balancers    = ["${aws_elb.example.name}"]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key                 = "Name"
    value               = "tf-asg-elb-${var.emailid}"
    propagate_at_launch = true
  }
}
*/

resource "aws_security_group" "instance" {
  name   = "terraform-example-instance"
  vpc_id = "${aws_vpc.terraform-vpc.id}"

  ingress {
    from_port   = "${var.server_port}"
    to_port     = "${var.server_port}"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

#added port 443 in security group Gagan Delouri
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "example-a" {
  count = 1

  #ami                    = "${var.web_server_ami}"
  ami                         = "${lookup(var.web_server_ami, var.aws_region)}"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.public-a.id}"
  vpc_security_group_ids      = ["${aws_security_group.instance.id}"]
  key_name                    = "${var.aws_keypair}"
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              yum install -y telnet
              /sbin/chkconfig --add docker
              service docker start
              ## added by Gagan Delouri for Dockeer instances for WAF Test
              #docker run -d -p 80:80 --net host -e F5DEMO_APP=website -e F5DEMO_NODENAME="Public Cloud Lab: AZ #1" --restart always --name f5demoapp chen23/f5-demo-app:latest
              #sudo docker run --restart=always -d -p 443:80 citizenstig/dvwa
              docker run  --restart=always -d -p 443:80 mutzel/all-in-one-hackazon:postinstall supervisord -n
              #Start DVWA with random mysql password:
              #docker run  --restart=always -d -p 80:8000 -it appsecco/dsvw
              docker run  --restart=always -d -p 80:8000 -it gaganld/dsvw-gagan
              #Port 8080 for DVWA
              docker pull citizenstig/dvwa
              docker run --restart=always -d -p 8080:9091 citizenstig/dvwa
              EOF

  tags {
    Name   = "web-az1.${count.index}: ${var.emailidsan}"
    findme = "web"
  }
}

resource "aws_instance" "example-b" {
  count = 1

  #ami                    = "{var.web_server_ami}"
  ami                         = "${lookup(var.web_server_ami, var.aws_region)}"
  instance_type               = "t2.micro"
  subnet_id                   = "${aws_subnet.public-b.id}"
  vpc_security_group_ids      = ["${aws_security_group.instance.id}"]
  key_name                    = "${var.aws_keypair}"
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              yum install -y telnet
              /sbin/chkconfig --add docker
              service docker start
              ## added by Gagan Delouri for Dockeer instances for WAF Test
              #docker run -d -p 80:80 --net host -e F5DEMO_APP=website -e F5DEMO_NODENAME="Public Cloud Lab: AZ #1" --restart always --name f5demoapp chen23/f5-demo-app:latest
              #sudo docker run --restart=always -d -p 443:80 citizenstig/dvwa
              docker run  --restart=always -d -p 443:80 mutzel/all-in-one-hackazon:postinstall supervisord -n
              #Start DVWA with random mysql password:
              #docker run  --restart=always -d -p 80:8000 -it appsecco/dsvw
              docker run  --restart=always -d -p 80:8000 -it gaganld/dsvw-gagan
              #Port 8080 for DVWA
              #docker run --restart=always -d -p 8080:8080 -p 3306:3306 -e MYSQL_PASS="Chang3ME" gaganld/dvwa-gagan
              docker pull citizenstig/dvwa
              docker run --restart=always -d -p 8080:9091 citizenstig/dvwa
              EOF

  tags {
    Name   = "web-az2.${count.index}: ${var.emailidsan}"
    findme = "web"
  }
}

## added by Gagan Delouri for Dockeer instances for WAF Test
# disabled for now
#resource "aws_instance" "example-c" {
#  count = 1

  #ami                    = "{var.web_server_ami}"
#  ami                         = "${lookup(var.web_server_ami, var.aws_region)}"
#  instance_type               = "t2.micro"
#  subnet_id                   = "${aws_subnet.public-b.id}"
#  vpc_security_group_ids      = ["${aws_security_group.instance.id}"]
# key_name                    = "${var.aws_keypair}"
#  associate_public_ip_address = true

#  user_data = <<-EOF
#              #!/bin/bash
#              yum update -y
#              yum install -y docker
#              /sbin/chkconfig --add docker
#              service docker start
#              ## added by Gagan Delouri for Dockeer instances for WAF Test
#              sudo docker run --restart=always -d -p 8181:80 -p 3306:3306 -e MYSQL_PASS="Chang3ME" citizenstig/dvwa
#              #docker run --restart=always -d -p 6969:8080 tomcat:8.0
#              docker run  --restart=always -d -p 8282:80 mutzel/all-in-one-hackazon:postinstall supervisord -n
#              #docker run  --restart=always -d -p 8080:8080 -t webgoat/webgoat-8.0
#              docker run  --restart=always -d -p 8383:8000 -it appsecco/dsvw
#              EOF

#  tags {
#    Name   = "web-az2.WAFUseCaseNode.${count.index}: ${var.emailidsan}"
#    findme = "web"
#  }
#}




#data "aws_availability_zones" "all" {}

resource "aws_iam_server_certificate" "elb_cert" {
  name             = "elb_cert_${var.emailid}"
  certificate_body = "${file("${var.emailidsan}.crt")}"
  private_key      = "${file("${var.emailidsan}.key")}"
}

resource "aws_elb" "example" {
  name = "tf-elb-${var.emailidsan}"

  cross_zone_load_balancing = true
  security_groups           = ["${aws_security_group.elb.id}"]
  subnets                   = ["${aws_subnet.public-a.id}", "${aws_subnet.public-b.id}"]

  listener {
    lb_port           = 80
    lb_protocol       = "http"
    instance_port     = "${var.server_port}"
    instance_protocol = "http"
  }
## added 443 listener port - Gagan Delouri
  listener {
    lb_port           = 443
    lb_protocol       = "http"
    instance_port     = 443
    instance_protocol = "http"
  }

  ## added 8080 listener port - Gagan Delouri
    listener {
      lb_port           = 8080
      lb_protocol       = "http"
      instance_port     = 8080
      instance_protocol = "http"
    }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:${var.server_port}/"
  }


  instances                   = ["${aws_instance.example-a.id}", "${aws_instance.example-b.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "tf-elb-${var.emailidsan}"
  }
}

resource "aws_security_group" "elb" {
  name   = "terraform-example-elb"
  vpc_id = "${aws_vpc.terraform-vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${var.restrictedSrcAddress}"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${var.restrictedSrcAddress}"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = "${var.restrictedSrcAddress}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "f5_management" {
  name   = "f5_management"
  vpc_id = "${aws_vpc.terraform-vpc.id}"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${var.restrictedSrcAddress}"
  }

## Added Port 80 to Security Group - Gagan Delouri
    ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = "${var.restrictedSrcAddress}"
    }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = "${var.restrictedSrcAddress}"
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = "${var.restrictedSrcAddress}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "f5_data" {
  name   = "f5_data"
  vpc_id = "${aws_vpc.terraform-vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${var.restrictedSrcAddress}"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${var.restrictedSrcAddress}"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = "${var.restrictedSrcAddress}"
  }

  ingress {
    from_port   = 1026
    to_port     = 1026
    protocol    = "udp"
    cidr_blocks = "${var.restrictedSrcAddress}"
  }

  ingress {
    from_port   = 4353
    to_port     = 4353
    protocol    = "tcp"
    cidr_blocks = "${var.restrictedSrcAddress}"
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = "${var.restrictedSrcAddress}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

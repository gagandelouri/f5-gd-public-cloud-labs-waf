resource "aws_elb" "f5-autoscale-waf-elb" {
  name = "waf-${var.emailidsan}"

  cross_zone_load_balancing = true
  security_groups           = ["${aws_security_group.elb.id}"]
  subnets                   = ["${aws_subnet.public-a.id}", "${aws_subnet.public-b.id}"]

  listener {
    lb_port            = 443
    lb_protocol        = "https"
    instance_port      = "443"
    instance_protocol  = "http"
    ssl_certificate_id = "${aws_iam_server_certificate.elb_cert.arn}"
  }

  ## added 443 listener port - Gagan Delouri
  listener {
    lb_port            = 80
    lb_protocol        = "http"
    instance_port      = "${var.server_port}"
    instance_protocol  = "http"
  }

  ## added 8080 listener port - Gagan Delouri
  listener {
    lb_port            = 8080
    lb_protocol        = "http"
    instance_port      = "8080"
    instance_protocol  = "http"
  }

  #added health check as ELB was not working
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTPS:8443/"
  }


}

resource "aws_cloudformation_stack" "f5-autoscale-waf" {
  name         = "waf-${var.emailidsan}-${aws_vpc.terraform-vpc.id}"
  capabilities = ["CAPABILITY_IAM"]

  parameters {
    #DEPLOYMENT
    deploymentName           = "waf-${var.emailidsan}"
    vpc                      = "${aws_vpc.terraform-vpc.id}"
    availabilityZones        = "${var.aws_region}a,${var.aws_region}b"
    subnets                  = "${aws_subnet.public-a.id},${aws_subnet.public-b.id}"
    bigipElasticLoadBalancer = "${aws_elb.f5-autoscale-waf-elb.name}"

    #New Deployment on Port 443 - Gagan Delouri

    #INSTANCE CONFIGURATION
    sshKey            = "${var.aws_keypair}"
    throughput        = "25Mbps"
    adminUsername     = "cluster-admin"
    managementGuiPort = 8443
    timezone          = "UTC"
    ntpServer         = "0.pool.ntp.org"
    restrictedSrcAddress = "0.0.0.0/0"

    #AUTO SCALING CONFIGURATION
    scalingMinSize          = "1"
    scalingMaxSize          = "2"
    scaleDownBytesThreshold = 10000
    scaleUpBytesThreshold   = 35000
    notificationEmail       = "${var.waf_emailid != "" ? var.waf_emailid : var.emailid}"
    #WAF VIRTUAL SERVICE CONFIGURATION
    virtualServicePort      = "${var.server_port}"
    applicationPort         = "${var.server_port}"
    #New Deployment on Port 443 - Gagan Delouri
    #virtualServicePort-443      = "443"
    #applicationPort-443        = "443"

    applicationPoolTagKey   = "findme"
    applicationPoolTagValue = "web"
    policyLevel             = "low"
    #TAGS
    application = "f5app"
    environment = "f5env"
    group       = "f5group"
    owner       = "f5owner"
    costcenter  = "f5costcenter"
  }

  #CloudFormation templates triggered from Terraform must be hosted on AWS S3.
  #template_url = "https://s3.amazonaws.com/f5-public-cloud/f5-autoscale-bigip.template"

  # changed to my local S3 bucket, required to test the local AMI instances for WAF -
  #us-east-1 BEST 25 Mbps ami-0e170a74,
  #ap-southeast-2 BEST 25 Mbps ami-4a19e728
  #ap-southeast-1 BEST 25 Mbps ami-a3b9fbdf
   template_url = "https://s3.amazonaws.com/gd-f5-public-cloud/v1/gd-f5-autoscale-bigip.template"

}

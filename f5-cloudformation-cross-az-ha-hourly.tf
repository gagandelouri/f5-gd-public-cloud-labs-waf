resource "aws_cloudformation_stack" "f5-cluster-cross-az-ha-hourly" {
  name         = "ha-${var.emailidsan}-${aws_vpc.terraform-vpc.id}"
  capabilities = ["CAPABILITY_IAM"]

  parameters {
    #NETWORKING CONFIGURATION

    Vpc                          = "${aws_vpc.terraform-vpc.id}"
    managementSubnetAz1          = "${aws_subnet.f5-management-a.id}"
    managementSubnetAz2          = "${aws_subnet.f5-management-b.id}"
    bigipManagementSecurityGroup = "${aws_security_group.f5_management.id}"
    subnet1Az1                   = "${aws_subnet.public-a.id}"
    subnet1Az2                   = "${aws_subnet.public-b.id}"
    bigipExternalSecurityGroup   = "${aws_security_group.f5_data.id}"

    #INSTANCE CONFIGURATION

    imageName            = "Good25Mbps"
    instanceType         = "m4.xlarge"
    restrictedSrcAddress = "0.0.0.0/0"
    sshKey               = "${var.aws_keypair}"
    restrictedSrcAddress = "0.0.0.0/0"
    ntpServer            = "0.pool.ntp.org"

    #BIG-IQ LICENSING CONFIGURATION


    # bigiqAddress         = "${var.bigiqLicenseManager}"
    # bigiqUsername        = "admin"
    # bigiqPasswordS3Arn   = "arn:aws:s3:::f5-public-cloud/passwd"
    # bigiqLicensePoolName = "${var.bigiqLicensePoolName}"


    #TAGS

    application = "f5app"
    environment = "f5env"
    group       = "f5group"
    owner       = "f5owner"
    costcenter  = "f5costcenter"
  }

  #CloudFormation templates triggered from Terraform must be hosted on AWS S3. Experimental hosted in non-canonical S3 bucket.
  #template_url = "https://s3.amazonaws.com/f5-public-cloud/f5-existing-stack-across-az-cluster-hourly-2nic-bigip.template"
  # changed to my local S3 bucket, required to test the local AMI instances, us-east-1 Good 25  Mbps updated ami-161c016c
  # changed to my local S3 bucket, required to test the local AMI instances for LTM -
  #us-east-1 Good 25 Mbps ami-161c016c,
  #ap-southeast-2 Good 25 Mbps ami-fbb07599
  #ap-southeast-1 Good 25 Mbps ami-3cbbf940
template_url = "https://s3.amazonaws.com/gd-f5-public-cloud/v1/gd-f5-existing-stack-across-az-cluster-hourly-2nic-bigip.template"

}

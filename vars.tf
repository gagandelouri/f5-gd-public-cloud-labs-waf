/*
variable "web_server_ami" {
  description = "web server ami is region specific, defaults to us-east-1"
  default     = "ami-40d28157"
  }
*/

variable "web_server_ami" {
  type = "map"

  default = {
    "us-east-1"      = "ami-a4c7edb2"
    "ap-southeast-1" = "ami-77af2014"
    "us-west-2"      = "ami-6df1e514"
    "ap-southeast-2"  = "ami-60a26a02"
     "us-west-1" = "ami-46e1f226"
     "us-west-2" = "ami-6b8cef13"
     "us-east-2" = "ami-976152f2"
  }
}

variable "aws_region" {
  description = "aws region (default is us-east-1)"
  default     = "us-east-1"
}

variable "bigiqLicenseManager" {
  description = "Management IP address of the BigIQ License Manager"
  default     = "null"
}

variable "bigiqLicensePoolName" {
  description = "BigIQ License Pool name"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
}

variable "aws_keypair" {
  description = "The name of an existing key pair. In AWS Console: NETWORK & SECURITY -> Key Pairs"
}

variable "emailid" {
  description = "emailid"
}

variable "waf_emailid" {
  description = "waf email notification"
  default     = ""
}

variable "emailidsan" {
  description = "emailidsan"
}

variable "restrictedSrcAddress" {
  type        = "list"
  description = "Lock down management access by source IP address or network"
  default     = ["0.0.0.0/0", "10.0.0.0/16"]
}

variable "aws_alias" {
  description = "Link alias to AWS Console"
}
